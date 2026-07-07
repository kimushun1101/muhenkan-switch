use std::sync::Mutex;
use std::time::Instant;

use tauri::menu::{
    CheckMenuItem, CheckMenuItemBuilder, MenuBuilder, MenuItemBuilder, PredefinedMenuItem,
};
use tauri::tray::TrayIconBuilder;
use tauri::{AppHandle, Emitter, Manager};

/// トレイの「ログイン時に自動起動」チェック項目ハンドル。
/// トレイクリック / GUI チェックボックスのどちらから状態を変更しても、
/// もう一方の表示を実状態 (`autolaunch().is_enabled()`) に揃えるため、
/// app state として保持しておき `sync_autostart_state` から参照する。
pub struct AutostartMenuHandle(pub CheckMenuItem<tauri::Wry>);

/// 自動起動の実状態を読み直し、トレイ CheckMenuItem の表示 (`set_checked`) と
/// GUI チェックボックスの両方を同期させる。
///
/// トレイの「自動起動」クリック時、および `set_autostart_enabled` コマンドの
/// 実行後に呼ぶ。enable/disable が失敗した場合でも実状態を読み直すため、
/// 表示と実状態がズレることはない。
pub fn sync_autostart_state(app: &AppHandle) {
    use tauri_plugin_autostart::ManagerExt;
    let enabled = app.autolaunch().is_enabled().unwrap_or(false);
    if let Some(state) = app.try_state::<AutostartMenuHandle>() {
        if let Err(e) = state.0.set_checked(enabled) {
            eprintln!("[tray] 自動起動メニューの表示更新に失敗: {:#}", e);
        }
    }
    let _ = app.emit("autostart-changed", enabled);
}

pub fn setup(app: &tauri::App) -> Result<(), Box<dyn std::error::Error>> {
    let handle = app.handle();

    build_tray(handle)?;

    Ok(())
}

fn build_tray(handle: &AppHandle) -> Result<(), Box<dyn std::error::Error>> {
    use tauri_plugin_autostart::ManagerExt;

    let settings_item = MenuItemBuilder::with_id("settings", "設定...").build(handle)?;
    let sep1 = PredefinedMenuItem::separator(handle)?;
    let autostart_enabled = handle.autolaunch().is_enabled().unwrap_or(false);
    let autostart_item = CheckMenuItemBuilder::with_id("autostart", "ログイン時に自動起動")
        .checked(autostart_enabled)
        .build(handle)?;
    handle.manage(AutostartMenuHandle(autostart_item.clone()));
    let open_dir_item = MenuItemBuilder::with_id("open_dir", "インストール先を開く")
        .build(handle)?;
    // インストーラー版 / スクリプト版どちらでも表示する。
    // listener 側 (initUpdater) で install type ごとに振り分け:
    //   - installer (Windows): tauri-plugin-updater 経由
    //   - script (Linux/macOS): GitHub API + ターミナル spawn
    let check_update_item =
        MenuItemBuilder::with_id("check_update", "アップデートを確認...").build(handle)?;
    let sep3 = PredefinedMenuItem::separator(handle)?;
    let quit_item = MenuItemBuilder::with_id("quit", "終了").build(handle)?;

    let menu = MenuBuilder::new(handle)
        .item(&settings_item)
        .item(&sep1)
        .item(&autostart_item)
        .item(&open_dir_item)
        .item(&check_update_item)
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
                        let result = if enabled {
                            app.autolaunch().disable()
                        } else {
                            app.autolaunch().enable()
                        };
                        if let Err(e) = result {
                            eprintln!("[tray] 自動起動の切り替えに失敗: {:#}", e);
                        }
                    }
                    // クリックで muda がチェック表示を自動トグルするため、
                    // 実状態を読み直して tray / GUI 双方を確定させる。
                    sync_autostart_state(app);
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
