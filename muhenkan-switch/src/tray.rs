use std::sync::Mutex;
use std::time::Instant;

use tauri::menu::{CheckMenuItemBuilder, MenuBuilder, MenuItemBuilder, PredefinedMenuItem};
use tauri::tray::TrayIconBuilder;
use tauri::{AppHandle, Emitter, Manager};

pub fn setup(app: &tauri::App) -> Result<(), Box<dyn std::error::Error>> {
    let handle = app.handle();

    build_tray(handle)?;

    Ok(())
}

fn build_tray(handle: &AppHandle) -> Result<(), Box<dyn std::error::Error>> {
    let settings_item = MenuItemBuilder::with_id("settings", "設定...").build(handle)?;
    let sep1 = PredefinedMenuItem::separator(handle)?;
    let autostart_item =
        CheckMenuItemBuilder::with_id("autostart", "ログイン時に自動起動")
            .build(handle)?;
    let open_dir_item = MenuItemBuilder::with_id("open_dir", "インストール先を開く")
        .build(handle)?;
    let is_installer = crate::commands::is_nsis_install();
    let check_update_item = if is_installer {
        Some(MenuItemBuilder::with_id("check_update", "アップデートを確認...").build(handle)?)
    } else {
        None
    };
    let sep3 = PredefinedMenuItem::separator(handle)?;
    let quit_item = MenuItemBuilder::with_id("quit", "終了").build(handle)?;

    let mut menu = MenuBuilder::new(handle)
        .item(&settings_item)
        .item(&sep1)
        .item(&autostart_item)
        .item(&open_dir_item);
    if let Some(ref item) = check_update_item {
        menu = menu.item(item);
    }
    let menu = menu
        .item(&sep3)
        .item(&quit_item)
        .build()?;

    let _tray = TrayIconBuilder::new()
        .icon(handle.default_window_icon().cloned().ok_or("no app icon")?)
        .menu(&menu)
        .tooltip("muhenkan-switch")
        .on_menu_event(move |app, event| {
            let id = event.id().as_ref();
            match id {
                "settings" => {
                    if let Some(window) = app.get_webview_window("main") {
                        let _ = window.show();
                        let _ = window.set_focus();
                    }
                }
                "open_dir" => {
                    let _ = crate::commands::open_install_dir();
                }
                "check_update" => {
                    let _ = app.emit("check-update-requested", ());
                }
                "autostart" => {
                    use tauri_plugin_autostart::ManagerExt;
                    if let Ok(enabled) = app.autolaunch().is_enabled() {
                        if enabled {
                            let _ = app.autolaunch().disable();
                        } else {
                            let _ = app.autolaunch().enable();
                        }
                    }
                }
                "quit" => {
                    use crate::kanata::KanataManager;
                    let manager = app.state::<KanataManager>();
                    let _ = manager.stop();
                    app.exit(0);
                }
                _ => {}
            }
        })
        .on_tray_icon_event({
            let last_click = Mutex::new(Instant::now() - std::time::Duration::from_secs(1));
            move |tray, event| {
                if let tauri::tray::TrayIconEvent::Click {
                    button: tauri::tray::MouseButton::Left,
                    ..
                } = event
                {
                    // デバウンス: 500ms 以内の重複クリックを無視
                    let mut last = last_click.lock().unwrap();
                    if last.elapsed().as_millis() < 500 {
                        return;
                    }
                    *last = Instant::now();

                    let app = tray.app_handle();
                    if let Some(window) = app.get_webview_window("main") {
                        if window.is_visible().unwrap_or(false) {
                            let _ = window.hide();
                        } else {
                            let _ = window.show();
                            let _ = window.set_focus();
                        }
                    }
                }
            }
        })
        .build(handle)?;

    Ok(())
}
