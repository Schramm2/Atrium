//! macOS clipboard transaction for dictation paste.
//!
//! Adapted from Handy's MIT-licensed save, paste, and guarded restore pattern:
//! https://github.com/cjpais/Handy/blob/e449f69c9f2abc4299333b952b9728323a76952d/src-tauri/src/clipboard.rs
//! and its change-count guard:
//! https://github.com/cjpais/Handy/blob/e449f69c9f2abc4299333b952b9728323a76952d/src-tauri/src/paste_tx/macos.rs

use std::thread;
use std::time::Duration;

use objc2::rc::Retained;
use objc2::runtime::ProtocolObject;
use objc2_app_kit::{NSPasteboard, NSPasteboardItem, NSPasteboardTypeString, NSPasteboardWriting};
use objc2_foundation::{NSArray, NSData, NSString};

use super::focus::FocusToken;
use super::input::send_paste_chord;

#[derive(Clone, Copy, Debug)]
pub struct PasteOptions {
    /// Time for the target application to observe the temporary clipboard.
    pub paste_delay: Duration,
    /// Time for the target application to read the clipboard before restore.
    pub restore_delay: Duration,
}

impl Default for PasteOptions {
    fn default() -> Self {
        Self {
            paste_delay: Duration::from_millis(20),
            restore_delay: Duration::from_millis(180),
        }
    }
}

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum PasteOutcome {
    Restored,
    /// Another application changed the clipboard after the paste. Its content
    /// was kept instead of being overwritten with the old snapshot.
    ClipboardChanged,
}

#[derive(Clone, Debug, Eq, PartialEq)]
struct PasteboardEntry {
    data_type: String,
    data: Vec<u8>,
}

#[derive(Clone, Debug, Default, Eq, PartialEq)]
struct PasteboardSnapshot {
    items: Vec<Vec<PasteboardEntry>>,
}

impl PasteboardSnapshot {
    fn capture(pasteboard: &NSPasteboard) -> Self {
        let Some(items) = pasteboard.pasteboardItems() else {
            return Self::default();
        };

        let items = items
            .iter()
            .map(|item| {
                item.types()
                    .iter()
                    .filter_map(|data_type| {
                        item.dataForType(&data_type).map(|data| PasteboardEntry {
                            data_type: data_type.to_string(),
                            data: data.to_vec(),
                        })
                    })
                    .collect()
            })
            .collect();
        Self { items }
    }

    fn restore(&self, pasteboard: &NSPasteboard) -> Result<(), String> {
        if self.items.is_empty() {
            pasteboard.clearContents();
            return Ok(());
        }

        let items: Vec<Retained<ProtocolObject<dyn NSPasteboardWriting>>> = self
            .items
            .iter()
            .map(|entries| {
                let item = NSPasteboardItem::new();
                for entry in entries {
                    let data_type = NSString::from_str(&entry.data_type);
                    let data = NSData::with_bytes(&entry.data);
                    if !item.setData_forType(&data, &data_type) {
                        return Err(format!(
                            "Could not restore clipboard type {}",
                            entry.data_type
                        ));
                    }
                }
                Ok(ProtocolObject::from_retained(item))
            })
            .collect::<Result<_, String>>()?;
        let items = NSArray::from_retained_slice(&items);
        pasteboard.clearContents();
        if pasteboard.writeObjects(&items) {
            Ok(())
        } else {
            Err("Could not restore clipboard items".to_string())
        }
    }
}

pub fn paste_text_preserving_clipboard(
    text: &str,
    expected_focus: Option<&FocusToken>,
    options: PasteOptions,
) -> Result<PasteOutcome, String> {
    if let Some(focus) = expected_focus {
        if !focus.is_still_frontmost() {
            return Err("The focused application changed during dictation".to_string());
        }
    }

    let pasteboard = NSPasteboard::generalPasteboard();
    let snapshot = PasteboardSnapshot::capture(&pasteboard);
    pasteboard.clearContents();
    if !pasteboard.setString_forType(&NSString::from_str(text), unsafe { NSPasteboardTypeString }) {
        snapshot.restore(&pasteboard)?;
        return Err("Could not write dictation text to the clipboard".to_string());
    }
    let transaction_change_count = pasteboard.changeCount();

    thread::sleep(options.paste_delay);
    if let Err(error) = send_paste_chord() {
        if should_restore(transaction_change_count, pasteboard.changeCount()) {
            snapshot.restore(&pasteboard)?;
        }
        return Err(error);
    }
    thread::sleep(options.restore_delay);

    if !should_restore(transaction_change_count, pasteboard.changeCount()) {
        return Ok(PasteOutcome::ClipboardChanged);
    }
    snapshot.restore(&pasteboard)?;
    Ok(PasteOutcome::Restored)
}

fn should_restore(transaction_change_count: isize, current_change_count: isize) -> bool {
    transaction_change_count == current_change_count
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn restores_only_when_transaction_still_owns_clipboard() {
        assert!(should_restore(42, 42));
        assert!(!should_restore(42, 43));
    }

    #[test]
    fn snapshot_keeps_all_items_and_types() {
        let snapshot = PasteboardSnapshot {
            items: vec![
                vec![
                    PasteboardEntry {
                        data_type: "public.utf8-plain-text".to_string(),
                        data: b"text".to_vec(),
                    },
                    PasteboardEntry {
                        data_type: "public.html".to_string(),
                        data: b"<b>text</b>".to_vec(),
                    },
                ],
                vec![PasteboardEntry {
                    data_type: "public.file-url".to_string(),
                    data: b"file:///tmp/example".to_vec(),
                }],
            ],
        };

        assert_eq!(snapshot.items.len(), 2);
        assert_eq!(snapshot.items[0].len(), 2);
        assert_eq!(snapshot.items[1][0].data_type, "public.file-url");
    }
}
