use core_graphics::event::{CGEvent, CGEventFlags, CGEventTapLocation};
use core_graphics::event_source::{CGEventSource, CGEventSourceStateID};

const ANSI_V_KEY_CODE: u16 = 9;

/// Post Command+V by physical key code so the active keyboard layout does not
/// change which key receives the paste command.
pub(super) fn send_paste_chord() -> Result<(), String> {
    let source = CGEventSource::new(CGEventSourceStateID::HIDSystemState)
        .map_err(|_| "Could not create a Core Graphics event source".to_string())?;
    let key_down = CGEvent::new_keyboard_event(source.clone(), ANSI_V_KEY_CODE, true)
        .map_err(|_| "Could not create the paste key-down event".to_string())?;
    let key_up = CGEvent::new_keyboard_event(source, ANSI_V_KEY_CODE, false)
        .map_err(|_| "Could not create the paste key-up event".to_string())?;

    key_down.set_flags(CGEventFlags::CGEventFlagCommand);
    key_up.set_flags(CGEventFlags::CGEventFlagCommand);
    key_down.post(CGEventTapLocation::HID);
    key_up.post(CGEventTapLocation::HID);
    Ok(())
}
