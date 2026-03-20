pub mod context;
pub mod dispatch;
pub mod keys;
pub mod open_folder;
pub mod open_gui;
pub mod search;
pub mod switch_app;
pub mod timestamp;
pub mod toast;

/// Wayland セッション判定
#[cfg(target_os = "linux")]
pub fn is_wayland() -> bool {
    std::env::var("WAYLAND_DISPLAY").is_ok()
        || std::env::var("XDG_SESSION_TYPE")
            .map(|v| v == "wayland")
            .unwrap_or(false)
}
