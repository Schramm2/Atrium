//! Press-and-release global hotkey adapter.
//!
//! The single-owner worker follows Handy's MIT-licensed manager design:
//! https://github.com/cjpais/Handy/blob/e449f69c9f2abc4299333b952b9728323a76952d/src-tauri/src/shortcut/handy_keys.rs

use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::mpsc::{self, Receiver, SyncSender};
use std::sync::Arc;
use std::thread::{self, JoinHandle};
use std::time::Duration;

use handy_keys::{Hotkey, HotkeyManager, HotkeyState};

use super::accessibility::accessibility_is_trusted;

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum HotkeyEventKind {
    Pressed,
    Released,
}

#[derive(Clone, Debug, Eq, PartialEq)]
pub struct HotkeyEvent {
    pub binding: String,
    pub kind: HotkeyEventKind,
}

pub struct GlobalHotkey {
    stop: Arc<AtomicBool>,
    worker: Option<JoinHandle<()>>,
}

impl GlobalHotkey {
    pub fn register(binding: &str) -> Result<(Self, Receiver<HotkeyEvent>), String> {
        if !accessibility_is_trusted() {
            return Err("Accessibility permission is required for global dictation hotkeys".into());
        }
        let hotkey: Hotkey = binding
            .parse()
            .map_err(|error| format!("Invalid dictation hotkey '{binding}': {error}"))?;

        let binding = binding.to_string();
        let binding_for_worker = binding.clone();
        let stop = Arc::new(AtomicBool::new(false));
        let stop_for_worker = Arc::clone(&stop);
        let (event_sender, event_receiver) = mpsc::channel();
        let (startup_sender, startup_receiver) = mpsc::sync_channel(1);

        let worker = thread::spawn(move || {
            run_worker(
                hotkey,
                binding_for_worker,
                stop_for_worker,
                event_sender,
                startup_sender,
            );
        });

        match startup_receiver.recv() {
            Ok(Ok(())) => Ok((
                Self {
                    stop,
                    worker: Some(worker),
                },
                event_receiver,
            )),
            Ok(Err(error)) => {
                let _ = worker.join();
                Err(error)
            }
            Err(_) => {
                let _ = worker.join();
                Err(format!(
                    "The global hotkey worker stopped before registering '{binding}'"
                ))
            }
        }
    }
}

impl Drop for GlobalHotkey {
    fn drop(&mut self) {
        self.stop.store(true, Ordering::Release);
        if let Some(worker) = self.worker.take() {
            let _ = worker.join();
        }
    }
}

fn run_worker(
    hotkey: Hotkey,
    binding: String,
    stop: Arc<AtomicBool>,
    event_sender: mpsc::Sender<HotkeyEvent>,
    startup_sender: SyncSender<Result<(), String>>,
) {
    let manager = match HotkeyManager::new_with_blocking() {
        Ok(manager) => manager,
        Err(error) => {
            let _ = startup_sender.send(Err(format!(
                "Could not start the global hotkey listener: {error}"
            )));
            return;
        }
    };
    let id = match manager.register(hotkey) {
        Ok(id) => id,
        Err(error) => {
            let _ = startup_sender.send(Err(format!(
                "Could not register dictation hotkey '{binding}': {error}"
            )));
            return;
        }
    };
    if startup_sender.send(Ok(())).is_err() {
        let _ = manager.unregister(id);
        return;
    }

    let mut last_kind = None;
    while !stop.load(Ordering::Acquire) {
        if let Some(event) = manager.try_recv() {
            if event.id != id {
                continue;
            }
            let kind = match event.state {
                HotkeyState::Pressed => HotkeyEventKind::Pressed,
                HotkeyState::Released => HotkeyEventKind::Released,
            };
            if should_emit(last_kind, kind) {
                last_kind = Some(kind);
                if event_sender
                    .send(HotkeyEvent {
                        binding: binding.clone(),
                        kind,
                    })
                    .is_err()
                {
                    break;
                }
            }
        } else {
            thread::sleep(Duration::from_millis(5));
        }
    }
    let _ = manager.unregister(id);
}

fn should_emit(previous: Option<HotkeyEventKind>, next: HotkeyEventKind) -> bool {
    previous != Some(next)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn filters_repeated_press_and_release_events() {
        assert!(should_emit(None, HotkeyEventKind::Pressed));
        assert!(!should_emit(
            Some(HotkeyEventKind::Pressed),
            HotkeyEventKind::Pressed
        ));
        assert!(should_emit(
            Some(HotkeyEventKind::Pressed),
            HotkeyEventKind::Released
        ));
        assert!(!should_emit(
            Some(HotkeyEventKind::Released),
            HotkeyEventKind::Released
        ));
    }
}
