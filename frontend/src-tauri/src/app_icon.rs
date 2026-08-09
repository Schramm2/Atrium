use serde::Deserialize;
use tauri::{AppHandle, Runtime};

#[derive(Clone, Copy, Debug, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub enum AppIcon {
    Ubundi,
    FirstMotive,
}

#[cfg(target_os = "macos")]
fn icon_bytes(icon: AppIcon) -> &'static [u8] {
    match icon {
        AppIcon::Ubundi => include_bytes!("../icons/icon.png"),
        AppIcon::FirstMotive => include_bytes!("../icons/notive-first-motive-icon.png"),
    }
}

#[tauri::command]
pub fn set_app_icon<R: Runtime>(app: AppHandle<R>, icon: AppIcon) -> Result<(), String> {
    #[cfg(target_os = "macos")]
    {
        use objc2::{AnyThread, MainThreadMarker};
        use objc2_app_kit::{NSApplication, NSImage};
        use objc2_foundation::NSData;

        let bytes = icon_bytes(icon);
        app.run_on_main_thread(move || {
            let marker = MainThreadMarker::new().expect("app icon updates run on the main thread");
            let data = unsafe {
                NSData::dataWithBytes_length(bytes.as_ptr().cast(), bytes.len())
            };

            if let Some(image) = NSImage::initWithData(NSImage::alloc(), &data) {
                let application = NSApplication::sharedApplication(marker);
                unsafe { application.setApplicationIconImage(Some(&image)) };
            } else {
                log::error!("Could not decode the selected Notive app icon");
            }
        })
        .map_err(|error| format!("Could not update the Notive app icon: {error}"))?;

        return Ok(());
    }

    #[cfg(not(target_os = "macos"))]
    {
        let _ = (app, icon);
        Err("App icon selection is available on macOS only.".to_string())
    }
}

#[cfg(test)]
mod tests {
    use super::AppIcon;

    #[test]
    fn app_icon_names_match_the_frontend_contract() {
        assert!(serde_json::from_str::<AppIcon>(r#""ubundi""#).is_ok());
        assert!(serde_json::from_str::<AppIcon>(r#""first-motive""#).is_ok());
        assert!(serde_json::from_str::<AppIcon>(r#""unknown""#).is_err());
    }
}
