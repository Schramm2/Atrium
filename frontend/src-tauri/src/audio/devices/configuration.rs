use anyhow::{anyhow, Result};
use lazy_static::lazy_static;
use serde::{Deserialize, Serialize};
use std::fmt;
use std::sync::atomic::AtomicU64;

lazy_static! {
    pub static ref LAST_AUDIO_CAPTURE: AtomicU64 = AtomicU64::new(
        std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap_or_default()
            .as_secs()
    );
}

#[derive(Clone, Debug, PartialEq)]
pub enum AudioTranscriptionEngine {
    Deepgram,
    WhisperTiny,
    WhisperDistilLargeV3,
    WhisperLargeV3Turbo,
    WhisperLargeV3,
}

impl fmt::Display for AudioTranscriptionEngine {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::Deepgram => write!(f, "Deepgram"),
            Self::WhisperTiny => write!(f, "WhisperTiny"),
            Self::WhisperDistilLargeV3 => write!(f, "WhisperLarge"),
            Self::WhisperLargeV3Turbo => write!(f, "WhisperLargeV3Turbo"),
            Self::WhisperLargeV3 => write!(f, "WhisperLargeV3"),
        }
    }
}

impl Default for AudioTranscriptionEngine {
    fn default() -> Self { Self::WhisperLargeV3Turbo }
}

#[derive(Clone, Debug)]
pub struct DeviceControl { pub is_running: bool, pub is_paused: bool }

#[derive(Clone, Eq, PartialEq, Hash, Serialize, Debug, Deserialize)]
pub enum DeviceType { Input, Output }

#[derive(Clone, Eq, PartialEq, Hash, Serialize, Debug)]
pub struct AudioDevice { pub name: String, pub device_type: DeviceType }

impl AudioDevice {
    pub fn new(name: String, device_type: DeviceType) -> Self { Self { name, device_type } }

    pub fn from_name(name: &str) -> Result<Self> {
        if name.trim().is_empty() { return Err(anyhow!("Device name cannot be empty")); }
        let (name, device_type) = if name.to_lowercase().ends_with("(input)") {
            (name.trim_end_matches("(input)").trim().to_string(), DeviceType::Input)
        } else if name.to_lowercase().ends_with("(output)") {
            (name.trim_end_matches("(output)").trim().to_string(), DeviceType::Output)
        } else { return Err(anyhow!("Device type (input/output) not specified in the name")); };
        Ok(Self::new(name, device_type))
    }
}

impl fmt::Display for AudioDevice {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        write!(f, "{} ({})", self.name, match self.device_type { DeviceType::Input => "input", DeviceType::Output => "output" })
    }
}

pub fn parse_audio_device(name: &str) -> Result<AudioDevice> { AudioDevice::from_name(name) }

/// Get a macOS audio device and its default configuration.
pub async fn get_device_and_config(audio_device: &AudioDevice) -> Result<(cpal::Device, cpal::SupportedStreamConfig)> {
    use cpal::traits::{DeviceTrait, HostTrait};
    let host = cpal::default_host();
    let devices = match audio_device.device_type { DeviceType::Input => host.input_devices()?, DeviceType::Output => host.output_devices()? };
    for device in devices {
        if device.name().ok().as_deref() != Some(audio_device.name.as_str()) { continue; }
        let config = match audio_device.device_type { DeviceType::Input => device.default_input_config()?, DeviceType::Output => device.default_output_config()? };
        return Ok((device, config));
    }
    Err(anyhow!("Device not found: {}", audio_device.name))
}
