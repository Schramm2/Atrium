use log::info;
use sherpa_onnx::{SpeakerEmbeddingExtractor, SpeakerEmbeddingExtractorConfig};
use std::path::PathBuf;

const MODEL_FILE_NAME: &str = "3dspeaker_speech_eres2net_base_sv_zh-cn_3dspeaker_16k.onnx";
const MODEL_URL: &str = "https://github.com/k2-fsa/sherpa-onnx/releases/download/speaker-recongition-models/3dspeaker_speech_eres2net_base_sv_zh-cn_3dspeaker_16k.onnx";
const SAMPLE_RATE: i32 = 16_000;
const MIN_SAMPLES: usize = SAMPLE_RATE as usize;
const MATCH_THRESHOLD: f32 = 0.72;

struct SpeakerProfile {
    label: String,
    centroid: Vec<f32>,
    observations: u32,
}

/// Assigns stable, anonymous labels to voices for one recording session.
///
/// The model runs on the user's computer. Profiles are held only in memory and
/// are discarded when the recording ends.
pub struct SpeakerDiarizer {
    extractor: SpeakerEmbeddingExtractor,
    profiles: Vec<SpeakerProfile>,
}

impl SpeakerDiarizer {
    pub async fn new() -> Result<Self, String> {
        let model_path = ensure_model().await?;
        let extractor = tokio::task::spawn_blocking(move || {
            let config = SpeakerEmbeddingExtractorConfig {
                model: Some(model_path.to_string_lossy().into_owned()),
                num_threads: 2,
                debug: false,
                provider: Some("cpu".to_string()),
            };

            SpeakerEmbeddingExtractor::create(&config)
                .ok_or_else(|| "Failed to initialize the speaker model".to_string())
        })
        .await
        .map_err(|error| format!("Speaker model setup failed: {error}"))??;

        Ok(Self {
            extractor,
            profiles: Vec::new(),
        })
    }

    /// Return the detected speaker for a VAD speech segment.
    pub fn label(&mut self, samples: &[f32]) -> Option<String> {
        if samples.len() < MIN_SAMPLES {
            return self.profiles.first().map(|profile| profile.label.clone());
        }

        let stream = self.extractor.create_stream()?;
        stream.accept_waveform(SAMPLE_RATE, samples);
        if !self.extractor.is_ready(&stream) {
            return self.profiles.first().map(|profile| profile.label.clone());
        }

        let embedding = self.extractor.compute(&stream)?;
        self.assign(embedding)
    }

    fn assign(&mut self, embedding: Vec<f32>) -> Option<String> {
        let embedding = normalize(embedding)?;
        let best_match = self
            .profiles
            .iter()
            .enumerate()
            .map(|(index, profile)| (index, dot(&embedding, &profile.centroid)))
            .max_by(|(_, left), (_, right)| left.total_cmp(right));

        if let Some((index, score)) = best_match {
            if score >= MATCH_THRESHOLD {
                let profile = &mut self.profiles[index];
                profile.observations += 1;
                profile.centroid = updated_centroid(
                    &profile.centroid,
                    &embedding,
                    profile.observations,
                )?;
                return Some(profile.label.clone());
            }
        }

        let label = format!("Speaker {}", self.profiles.len() + 1);
        self.profiles.push(SpeakerProfile {
            label: label.clone(),
            centroid: embedding,
            observations: 1,
        });
        info!("Detected {} in the active recording", label);
        Some(label)
    }
}

async fn ensure_model() -> Result<PathBuf, String> {
    let model_dir = dirs::data_local_dir()
        .ok_or_else(|| "Could not find a local data directory for the speaker model".to_string())?
        .join("Ubundi Meet")
        .join("models")
        .join("speaker-diarization");
    let model_path = model_dir.join(MODEL_FILE_NAME);

    if model_path.is_file() {
        return Ok(model_path);
    }

    tokio::fs::create_dir_all(&model_dir)
        .await
        .map_err(|error| format!("Could not create the speaker model directory: {error}"))?;

    info!("Downloading the local speaker-diarization model");
    let response = reqwest::Client::new()
        .get(MODEL_URL)
        .header(reqwest::header::USER_AGENT, "Notive")
        .send()
        .await
        .map_err(|error| format!("Could not download the speaker model: {error}"))?
        .error_for_status()
        .map_err(|error| format!("Could not download the speaker model: {error}"))?;
    let bytes = response
        .bytes()
        .await
        .map_err(|error| format!("Could not read the speaker model: {error}"))?;

    let temporary_path = model_dir.join(format!(".{MODEL_FILE_NAME}.download"));
    tokio::fs::write(&temporary_path, bytes)
        .await
        .map_err(|error| format!("Could not save the speaker model: {error}"))?;
    tokio::fs::rename(&temporary_path, &model_path)
        .await
        .map_err(|error| format!("Could not activate the speaker model: {error}"))?;

    Ok(model_path)
}

fn normalize(mut vector: Vec<f32>) -> Option<Vec<f32>> {
    let magnitude = vector.iter().map(|value| value * value).sum::<f32>().sqrt();
    if magnitude <= f32::EPSILON {
        return None;
    }
    for value in &mut vector {
        *value /= magnitude;
    }
    Some(vector)
}

fn dot(left: &[f32], right: &[f32]) -> f32 {
    left.iter().zip(right).map(|(left, right)| left * right).sum()
}

fn updated_centroid(current: &[f32], next: &[f32], observations: u32) -> Option<Vec<f32>> {
    let previous_weight = (observations - 1) as f32;
    normalize(
        current
            .iter()
            .zip(next)
            .map(|(current, next)| (current * previous_weight + next) / observations as f32)
            .collect(),
    )
}

#[cfg(test)]
mod tests {
    use super::{dot, normalize, updated_centroid};

    #[test]
    fn normalizes_vectors_for_cosine_matching() {
        let vector = normalize(vec![3.0, 4.0]).expect("non-zero vector");
        assert!((dot(&vector, &vector) - 1.0).abs() < 0.0001);
    }

    #[test]
    fn updates_a_normalized_centroid() {
        let centroid = updated_centroid(&[1.0, 0.0], &[0.0, 1.0], 2).expect("valid centroid");
        assert!((centroid[0] - centroid[1]).abs() < 0.0001);
    }
}
