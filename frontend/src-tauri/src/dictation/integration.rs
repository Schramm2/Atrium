use std::sync::atomic::{AtomicU64, AtomicU8, Ordering};
use std::sync::mpsc::{self, Receiver, SyncSender};
use std::sync::{Arc, Mutex};

use cpal::traits::{DeviceTrait, HostTrait, StreamTrait};
use serde::Serialize;
use tauri::{AppHandle, Emitter, Manager, Wry};

use crate::audio::transcription::TranscriptionEngine;
use crate::dictation::{
    AvailabilityCheck, AvailabilityConflict, CapturedAudio, DictationAdapterError,
    DictationSession, DictationStatus, MicrophoneCapture, NoPersistence, SessionId, StartResult,
    StopResult, Transcriber, Transcript,
};

pub const DICTATION_STATE_CHANGED_EVENT: &str = "dictation-state-changed";
pub const DICTATION_RESULT_EVENT: &str = "dictation-result";

const OWNER_IDLE: u8 = 0;
const OWNER_MEETING: u8 = 1;
const OWNER_DICTATION: u8 = 2;
const TARGET_SAMPLE_RATE_HZ: u32 = 16_000;

static AUDIO_OWNER: AtomicU8 = AtomicU8::new(OWNER_IDLE);
static DICTATION_PHASE: AtomicU8 = AtomicU8::new(OWNER_IDLE);
static DICTATION_SESSION_ID: AtomicU64 = AtomicU64::new(0);

type AppDictationSession =
    DictationSession<CpalMicrophoneCapture, LocalTranscriber, MeetingAvailability, NoPersistence>;

pub struct DictationIntegrationState {
    worker: DictationWorker,
    cancel_generation: Arc<AtomicU64>,
    #[cfg(target_os = "macos")]
    focus: Arc<Mutex<Option<crate::dictation_platform::macos::FocusToken>>>,
    #[cfg(target_os = "macos")]
    hotkey: Mutex<Option<crate::dictation_platform::macos::GlobalHotkey>>,
}

#[derive(Clone)]
struct DictationWorker {
    sender: mpsc::Sender<WorkerCommand>,
}

enum WorkerCommand {
    Start(SyncSender<Result<StartResult, String>>),
    Stop(SyncSender<Result<StopResult, String>>),
    Cancel(SyncSender<Result<(), String>>),
    Shutdown,
}

#[derive(Clone, Debug, Eq, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct DictationStatusPayload {
    pub state: &'static str,
    pub session_id: Option<u64>,
}

#[derive(Clone, Debug, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct DictationResultPayload {
    pub session_id: u64,
    pub text: String,
    pub confidence: Option<f32>,
}

impl From<DictationStatus> for DictationStatusPayload {
    fn from(status: DictationStatus) -> Self {
        match status {
            DictationStatus::Idle => Self {
                state: "idle",
                session_id: None,
            },
            DictationStatus::Recording { session_id } => Self {
                state: "recording",
                session_id: Some(session_id.get()),
            },
            DictationStatus::Processing { session_id } => Self {
                state: "processing",
                session_id: Some(session_id.get()),
            },
        }
    }
}

impl DictationIntegrationState {
    fn new(app: AppHandle<Wry>) -> Result<Self, String> {
        let (sender, receiver) = mpsc::channel();
        std::thread::Builder::new()
            .name("dictation-session".to_string())
            .spawn(move || {
                run_dictation_worker(
                    receiver,
                    DictationSession::new(
                        CpalMicrophoneCapture::default(),
                        LocalTranscriber { app },
                        MeetingAvailability,
                    ),
                );
            })
            .map_err(|error| format!("Failed to start the dictation worker: {error}"))?;

        Ok(Self {
            worker: DictationWorker { sender },
            cancel_generation: Arc::new(AtomicU64::new(0)),
            #[cfg(target_os = "macos")]
            focus: Arc::new(Mutex::new(None)),
            #[cfg(target_os = "macos")]
            hotkey: Mutex::new(None),
        })
    }
}

impl Drop for DictationIntegrationState {
    fn drop(&mut self) {
        let _ = self.worker.sender.send(WorkerCommand::Shutdown);
    }
}

fn run_dictation_worker(receiver: Receiver<WorkerCommand>, mut session: AppDictationSession) {
    while let Ok(command) = receiver.recv() {
        match command {
            WorkerCommand::Start(response) => {
                let _ = response.send(session.start().map_err(|error| error.to_string()));
            }
            WorkerCommand::Stop(response) => {
                let _ = response.send(session.stop().map_err(|error| error.to_string()));
            }
            WorkerCommand::Cancel(response) => {
                let result = session
                    .cancel()
                    .map(|_| ())
                    .map_err(|error| error.to_string());
                let _ = response.send(result);
            }
            WorkerCommand::Shutdown => {
                if session.status() != DictationStatus::Idle {
                    let _ = session.cancel();
                }
                break;
            }
        }
    }
}

pub fn initialize(app: &AppHandle<Wry>) -> Result<(), String> {
    if !app.manage(DictationIntegrationState::new(app.clone())?) {
        return Err("Dictation integration state is already initialized".to_string());
    }

    #[cfg(target_os = "macos")]
    if let Err(error) = initialize_macos_hotkey(app) {
        log::warn!("Dictation shortcut is unavailable: {error}");
    }

    Ok(())
}

#[cfg(target_os = "macos")]
fn initialize_macos_hotkey(app: &AppHandle<Wry>) -> Result<(), String> {
    if !crate::dictation_platform::macos::accessibility_is_trusted() {
        log::warn!("Dictation shortcut is disabled until Accessibility access is granted");
        return Ok(());
    }

    let (hotkey, receiver) =
        crate::dictation_platform::macos::GlobalHotkey::register("option+space")?;
    let state = app.state::<DictationIntegrationState>();
    *state
        .hotkey
        .lock()
        .map_err(|_| "Dictation hotkey state is unavailable".to_string())? = Some(hotkey);

    let app = app.clone();
    std::thread::Builder::new()
        .name("dictation-hotkey".to_string())
        .spawn(move || {
            while let Ok(event) = receiver.recv() {
                let result = match event.kind {
                    crate::dictation_platform::macos::HotkeyEventKind::Pressed => {
                        tauri::async_runtime::block_on(start_dictation_internal(app.clone()))
                            .map(|_| ())
                    }
                    crate::dictation_platform::macos::HotkeyEventKind::Released => {
                        tauri::async_runtime::block_on(stop_dictation_internal(app.clone()))
                            .map(|_| ())
                    }
                };
                if let Err(error) = result {
                    log::warn!("Dictation shortcut action failed: {error}");
                }
            }
        })
        .map_err(|error| format!("Failed to start dictation shortcut listener: {error}"))?;

    Ok(())
}

pub fn claim_meeting_audio() -> Result<(), String> {
    AUDIO_OWNER
        .compare_exchange(
            OWNER_IDLE,
            OWNER_MEETING,
            Ordering::AcqRel,
            Ordering::Acquire,
        )
        .map(|_| ())
        .map_err(|owner| match owner {
            OWNER_DICTATION => "Stop dictation before you start a meeting recording".to_string(),
            OWNER_MEETING => "A meeting recording is already active".to_string(),
            _ => "Audio capture is unavailable".to_string(),
        })
}

pub fn release_meeting_audio() {
    let _ = AUDIO_OWNER.compare_exchange(
        OWNER_MEETING,
        OWNER_IDLE,
        Ordering::AcqRel,
        Ordering::Acquire,
    );
}

pub async fn release_meeting_audio_if_stopped() {
    if !crate::audio::recording_commands::is_recording().await {
        release_meeting_audio();
    }
}

fn claim_dictation_audio() -> Result<(), AvailabilityConflict> {
    AUDIO_OWNER
        .compare_exchange(
            OWNER_IDLE,
            OWNER_DICTATION,
            Ordering::AcqRel,
            Ordering::Acquire,
        )
        .map(|_| ())
        .map_err(|owner| match owner {
            OWNER_MEETING => AvailabilityConflict::MeetingInProgress,
            OWNER_DICTATION => {
                AvailabilityConflict::Unavailable("dictation is already active".to_string())
            }
            _ => AvailabilityConflict::Unavailable("audio capture is unavailable".to_string()),
        })
}

fn release_dictation_audio() {
    let _ = AUDIO_OWNER.compare_exchange(
        OWNER_DICTATION,
        OWNER_IDLE,
        Ordering::AcqRel,
        Ordering::Acquire,
    );
}

struct MeetingAvailability;

impl AvailabilityCheck for MeetingAvailability {
    fn check(&self) -> Result<(), AvailabilityConflict> {
        claim_dictation_audio()?;
        let meeting_active =
            tauri::async_runtime::block_on(crate::audio::recording_commands::is_recording());
        if meeting_active {
            release_dictation_audio();
            return Err(AvailabilityConflict::MeetingInProgress);
        }

        Ok(())
    }
}

#[derive(Default)]
struct CpalMicrophoneCapture {
    stream: Option<cpal::Stream>,
    samples: Arc<Mutex<Vec<f32>>>,
    source_sample_rate_hz: u32,
}

impl MicrophoneCapture for CpalMicrophoneCapture {
    fn start(&mut self, _session_id: SessionId) -> Result<(), DictationAdapterError> {
        if self.stream.is_some() {
            return Err(DictationAdapterError::new(
                "the dictation microphone is already active",
            ));
        }

        let device = cpal::default_host()
            .default_input_device()
            .ok_or_else(|| DictationAdapterError::new("no microphone is available"))?;
        let supported = device
            .default_input_config()
            .map_err(|error| DictationAdapterError::new(error.to_string()))?;
        let sample_format = supported.sample_format();
        let config = supported.config();
        let channels = usize::from(config.channels);
        self.source_sample_rate_hz = config.sample_rate.0;
        self.samples = Arc::new(Mutex::new(Vec::new()));

        let samples = self.samples.clone();
        let error_callback = |error| log::error!("Dictation microphone stream failed: {error}");
        let stream = match sample_format {
            cpal::SampleFormat::F32 => device.build_input_stream(
                &config,
                move |data: &[f32], _| append_interleaved(data, channels, &samples, |value| value),
                error_callback,
                None,
            ),
            cpal::SampleFormat::I16 => device.build_input_stream(
                &config,
                move |data: &[i16], _| {
                    append_interleaved(data, channels, &samples, |value| {
                        value as f32 / i16::MAX as f32
                    })
                },
                error_callback,
                None,
            ),
            cpal::SampleFormat::U16 => device.build_input_stream(
                &config,
                move |data: &[u16], _| {
                    append_interleaved(data, channels, &samples, |value| {
                        (value as f32 / u16::MAX as f32) * 2.0 - 1.0
                    })
                },
                error_callback,
                None,
            ),
            format => {
                return Err(DictationAdapterError::new(format!(
                    "unsupported microphone sample format: {format:?}"
                )))
            }
        }
        .map_err(|error| DictationAdapterError::new(error.to_string()))?;

        stream
            .play()
            .map_err(|error| DictationAdapterError::new(error.to_string()))?;
        self.stream = Some(stream);
        Ok(())
    }

    fn stop(&mut self, _session_id: SessionId) -> Result<CapturedAudio, DictationAdapterError> {
        let stream = self
            .stream
            .take()
            .ok_or_else(|| DictationAdapterError::new("the dictation microphone is not active"))?;
        drop(stream);
        let samples = std::mem::take(
            &mut *self
                .samples
                .lock()
                .map_err(|_| DictationAdapterError::new("microphone samples are unavailable"))?,
        );

        Ok(CapturedAudio {
            samples: resample_linear(&samples, self.source_sample_rate_hz, TARGET_SAMPLE_RATE_HZ),
            sample_rate_hz: TARGET_SAMPLE_RATE_HZ,
        })
    }

    fn cancel(&mut self, _session_id: SessionId) -> Result<(), DictationAdapterError> {
        self.stream.take();
        self.samples
            .lock()
            .map_err(|_| DictationAdapterError::new("microphone samples are unavailable"))?
            .clear();
        Ok(())
    }
}

fn append_interleaved<T: Copy>(
    data: &[T],
    channels: usize,
    destination: &Arc<Mutex<Vec<f32>>>,
    convert: impl Fn(T) -> f32,
) {
    let Ok(mut destination) = destination.lock() else {
        return;
    };
    for frame in data.chunks_exact(channels.max(1)) {
        let mono = frame.iter().copied().map(&convert).sum::<f32>() / frame.len() as f32;
        destination.push(mono);
    }
}

fn resample_linear(samples: &[f32], source_rate_hz: u32, target_rate_hz: u32) -> Vec<f32> {
    if samples.is_empty() || source_rate_hz == 0 || target_rate_hz == 0 {
        return Vec::new();
    }
    if source_rate_hz == target_rate_hz {
        return samples.to_vec();
    }

    let output_len =
        (samples.len() as u64 * target_rate_hz as u64 / source_rate_hz as u64) as usize;
    let ratio = source_rate_hz as f64 / target_rate_hz as f64;
    (0..output_len)
        .map(|index| {
            let position = index as f64 * ratio;
            let lower = position.floor() as usize;
            let upper = (lower + 1).min(samples.len() - 1);
            let fraction = (position - lower as f64) as f32;
            samples[lower] + (samples[upper] - samples[lower]) * fraction
        })
        .collect()
}

struct LocalTranscriber {
    app: AppHandle<Wry>,
}

impl Transcriber for LocalTranscriber {
    fn transcribe(
        &mut self,
        _session_id: SessionId,
        audio: CapturedAudio,
    ) -> Result<Transcript, DictationAdapterError> {
        if audio.samples.len() < TARGET_SAMPLE_RATE_HZ as usize / 10 {
            return Err(DictationAdapterError::new(
                "dictation audio is shorter than 100 milliseconds",
            ));
        }

        let app = self.app.clone();
        tauri::async_runtime::block_on(async move {
            crate::audio::transcription::validate_transcription_model_ready(&app)
                .await
                .map_err(DictationAdapterError::new)?;
            let engine = crate::audio::transcription::get_or_init_transcription_engine(&app)
                .await
                .map_err(DictationAdapterError::new)?;

            match engine {
                TranscriptionEngine::Whisper(engine) => {
                    let (text, confidence, _) = engine
                        .transcribe_audio_with_confidence(
                            audio.samples,
                            crate::get_language_preference_internal(),
                        )
                        .await
                        .map_err(|error| DictationAdapterError::new(error.to_string()))?;
                    Ok(Transcript {
                        text: text.trim().to_string(),
                        confidence: Some(confidence),
                    })
                }
                TranscriptionEngine::Parakeet(engine) => {
                    let text = engine
                        .transcribe_audio(audio.samples)
                        .await
                        .map_err(|error| DictationAdapterError::new(error.to_string()))?;
                    Ok(Transcript {
                        text: text.trim().to_string(),
                        confidence: None,
                    })
                }
                TranscriptionEngine::Provider(provider) => {
                    let result = provider
                        .transcribe(audio.samples, crate::get_language_preference_internal())
                        .await
                        .map_err(|error| DictationAdapterError::new(error.to_string()))?;
                    Ok(Transcript {
                        text: result.text.trim().to_string(),
                        confidence: result.confidence,
                    })
                }
            }
        })
    }
}

#[tauri::command]
pub async fn start_dictation(app: AppHandle<Wry>) -> Result<DictationStatusPayload, String> {
    start_dictation_internal(app).await
}

pub async fn start_dictation_internal(
    app: AppHandle<Wry>,
) -> Result<DictationStatusPayload, String> {
    #[cfg(target_os = "macos")]
    if !crate::dictation_platform::macos::accessibility_is_trusted() {
        crate::dictation_platform::macos::request_accessibility();
        return Err(
            "Allow Ubundi Meet in Privacy & Security > Accessibility, then restart Ubundi Meet"
                .to_string(),
        );
    }

    let state = app.state::<DictationIntegrationState>();
    let worker = state.worker.clone();
    #[cfg(target_os = "macos")]
    let focus = state.focus.clone();

    #[cfg(target_os = "macos")]
    let captured_focus = crate::dictation_platform::macos::FocusToken::capture();

    let (response_sender, response_receiver) = mpsc::sync_channel(1);
    worker
        .sender
        .send(WorkerCommand::Start(response_sender))
        .map_err(|_| "Dictation session is unavailable".to_string())?;
    let result = wait_for_worker(response_receiver).await;

    match result {
        Ok(started) => {
            #[cfg(target_os = "macos")]
            {
                *focus
                    .lock()
                    .map_err(|_| "Dictation focus state is unavailable".to_string())? =
                    captured_focus;
            }
            let payload = DictationStatusPayload::from(DictationStatus::Recording {
                session_id: started.session_id,
            });
            DICTATION_SESSION_ID.store(started.session_id.get(), Ordering::Release);
            DICTATION_PHASE.store(1, Ordering::Release);
            emit_state(&app, &payload);
            Ok(payload)
        }
        Err(error) => {
            release_dictation_audio();
            Err(error)
        }
    }
}

#[tauri::command]
pub async fn stop_dictation(app: AppHandle<Wry>) -> Result<DictationResultPayload, String> {
    stop_dictation_internal(app).await
}

pub async fn stop_dictation_internal(
    app: AppHandle<Wry>,
) -> Result<DictationResultPayload, String> {
    let state = app.state::<DictationIntegrationState>();
    let worker = state.worker.clone();
    let generation = state.cancel_generation.load(Ordering::Acquire);
    let status = tray_status();
    let session_id = match (status.state, status.session_id) {
        ("recording", Some(session_id)) => session_id,
        ("idle", _) => return Err("No dictation session is active".to_string()),
        ("processing", _) => return Err("Dictation is already processing".to_string()),
        _ => return Err("Dictation status is unavailable".to_string()),
    };
    DICTATION_PHASE.store(2, Ordering::Release);
    emit_state(
        &app,
        &DictationStatusPayload {
            state: "processing",
            session_id: Some(session_id),
        },
    );

    let (response_sender, response_receiver) = mpsc::sync_channel(1);
    if worker
        .sender
        .send(WorkerCommand::Stop(response_sender))
        .is_err()
    {
        release_dictation_audio();
        DICTATION_PHASE.store(0, Ordering::Release);
        DICTATION_SESSION_ID.store(0, Ordering::Release);
        return Err("Dictation session is unavailable".to_string());
    }
    let outcome = wait_for_worker(response_receiver).await;

    release_dictation_audio();
    DICTATION_PHASE.store(0, Ordering::Release);
    DICTATION_SESSION_ID.store(0, Ordering::Release);
    let idle = DictationStatusPayload::from(DictationStatus::Idle);
    emit_state(&app, &idle);

    let stopped = outcome?;
    if state.cancel_generation.load(Ordering::Acquire) != generation {
        return Err("Dictation was cancelled".to_string());
    }

    let payload = DictationResultPayload {
        session_id: stopped.result.session_id.get(),
        text: stopped.result.transcript.text,
        confidence: stopped.result.transcript.confidence,
    };

    if let Err(error) = app.emit(DICTATION_RESULT_EVENT, &payload) {
        log::error!("Failed to emit dictation result: {error}");
    }

    #[cfg(target_os = "macos")]
    if !payload.text.is_empty() {
        let focus = state
            .focus
            .lock()
            .map_err(|_| "Dictation focus state is unavailable".to_string())?
            .take();
        crate::dictation_platform::macos::paste_text_preserving_clipboard(
            &payload.text,
            focus.as_ref(),
            crate::dictation_platform::macos::PasteOptions::default(),
        )?;
    }

    Ok(payload)
}

#[tauri::command]
pub async fn cancel_dictation(app: AppHandle<Wry>) -> Result<DictationStatusPayload, String> {
    let state = app.state::<DictationIntegrationState>();
    state.cancel_generation.fetch_add(1, Ordering::AcqRel);
    if DICTATION_PHASE.load(Ordering::Acquire) == 2 {
        return Ok(tray_status());
    }
    let worker = state.worker.clone();
    let (response_sender, response_receiver) = mpsc::sync_channel(1);
    if worker
        .sender
        .send(WorkerCommand::Cancel(response_sender))
        .is_err()
    {
        release_dictation_audio();
        DICTATION_PHASE.store(0, Ordering::Release);
        DICTATION_SESSION_ID.store(0, Ordering::Release);
        return Err("Dictation session is unavailable".to_string());
    }
    let outcome = wait_for_worker(response_receiver).await;

    release_dictation_audio();
    outcome?;
    DICTATION_PHASE.store(0, Ordering::Release);
    DICTATION_SESSION_ID.store(0, Ordering::Release);
    #[cfg(target_os = "macos")]
    {
        state
            .focus
            .lock()
            .map_err(|_| "Dictation focus state is unavailable".to_string())?
            .take();
    }
    let payload = DictationStatusPayload::from(DictationStatus::Idle);
    emit_state(&app, &payload);
    Ok(payload)
}

#[tauri::command]
pub async fn get_dictation_status(app: AppHandle<Wry>) -> Result<DictationStatusPayload, String> {
    let _ = app;
    Ok(tray_status())
}

pub fn tray_status() -> DictationStatusPayload {
    let session_id = DICTATION_SESSION_ID.load(Ordering::Acquire);
    match DICTATION_PHASE.load(Ordering::Acquire) {
        1 => DictationStatusPayload {
            state: "recording",
            session_id: Some(session_id),
        },
        2 => DictationStatusPayload {
            state: "processing",
            session_id: Some(session_id),
        },
        _ => DictationStatusPayload::from(DictationStatus::Idle),
    }
}

pub fn cancel_on_exit(app: &AppHandle<Wry>) {
    let Some(state) = app.try_state::<DictationIntegrationState>() else {
        return;
    };
    state.cancel_generation.fetch_add(1, Ordering::AcqRel);
    let _ = state.worker.sender.send(WorkerCommand::Shutdown);
    release_dictation_audio();
    DICTATION_PHASE.store(0, Ordering::Release);
    DICTATION_SESSION_ID.store(0, Ordering::Release);
}

async fn wait_for_worker<T: Send + 'static>(
    receiver: Receiver<Result<T, String>>,
) -> Result<T, String> {
    tauri::async_runtime::spawn_blocking(move || {
        receiver
            .recv()
            .map_err(|_| "Dictation worker stopped before it replied".to_string())?
    })
    .await
    .map_err(|error| error.to_string())?
}

fn emit_state(app: &AppHandle<Wry>, payload: &DictationStatusPayload) {
    if let Err(error) = app.emit(DICTATION_STATE_CHANGED_EVENT, payload) {
        log::error!("Failed to emit dictation state: {error}");
    }
    crate::tray::update_tray_menu(app);
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn resamples_to_sixteen_kilohertz() {
        let input = vec![0.0, 1.0, 0.0, -1.0];
        let output = resample_linear(&input, 8_000, 16_000);

        assert_eq!(output.len(), 8);
        assert_eq!(output[0], 0.0);
        assert_eq!(output[2], 1.0);
        assert_eq!(output[4], 0.0);
        assert_eq!(output[6], -1.0);
    }

    #[test]
    fn audio_owner_is_mutually_exclusive() {
        AUDIO_OWNER.store(OWNER_IDLE, Ordering::Release);

        claim_meeting_audio().expect("meeting claim");
        assert_eq!(
            claim_dictation_audio(),
            Err(AvailabilityConflict::MeetingInProgress)
        );
        release_meeting_audio();
        claim_dictation_audio().expect("dictation claim");
        assert!(claim_meeting_audio().is_err());
        release_dictation_audio();
    }
}
