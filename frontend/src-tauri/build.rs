#[path = "build/ffmpeg.rs"]
mod ffmpeg;

fn main() {
    println!("cargo:warning=Building Ubundi Meet for macOS with Metal and CoreML acceleration");
    println!("cargo:rustc-link-lib=framework=AVFoundation");
    println!("cargo:rustc-link-lib=framework=Cocoa");
    println!("cargo:rustc-link-lib=framework=Foundation");

    ffmpeg::ensure_ffmpeg_binary();
    tauri_build::build()
}
