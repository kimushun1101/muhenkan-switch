use anyhow::Result;
use std::path::PathBuf;

/// GUI バイナリ名
const fn gui_binary_name() -> &'static str {
    if cfg!(target_os = "windows") {
        "muhenkan-switch.exe"
    } else {
        "muhenkan-switch"
    }
}

/// GUI 起動要求のシグナルファイルパス。
/// open-gui が書き込み、GUI プロセス側の監視スレッドが検出して削除する。
pub fn signal_file_path() -> PathBuf {
    std::env::temp_dir().join("muhenkan-switch-show.signal")
}

/// GUI バイナリのフルパスを取得する。
///
/// 探索順序:
/// 1. exe（muhenkan-switch-core）と同じディレクトリ（インストール環境）
/// 2. カレントディレクトリの bin/（開発環境: mise run build 後）
/// 3. ワークスペースルートの bin/（開発環境）
/// 4. target/debug/（cargo build 直後）
fn gui_binary_path() -> Option<PathBuf> {
    let name = gui_binary_name();

    // 1. exe と同じディレクトリ
    if let Ok(exe_dir) = std::env::current_exe().map(|p| p.parent().unwrap().to_path_buf()) {
        let path = exe_dir.join(name);
        if path.exists() {
            return Some(path);
        }
    }

    let workspace_root = PathBuf::from(env!("CARGO_MANIFEST_DIR"))
        .parent()
        .map(|p| p.to_path_buf());

    // 2. カレントディレクトリの bin/
    if let Ok(cwd) = std::env::current_dir() {
        let path = cwd.join("bin").join(name);
        if path.exists() {
            return Some(path);
        }
    }

    // 3. ワークスペースルートの bin/
    if let Some(ref root) = workspace_root {
        let path = root.join("bin").join(name);
        if path.exists() {
            return Some(path);
        }
    }

    // 4. target/debug/
    if let Some(ref root) = workspace_root {
        let path = root.join("target").join("debug").join(name);
        if path.exists() {
            return Some(path);
        }
    }

    None
}

pub fn run() -> Result<()> {
    imp::open_gui()
}

// ── Platform: Windows ──

#[cfg(target_os = "windows")]
mod imp {
    use super::*;
    use std::ffi::OsString;
    use std::os::windows::ffi::OsStringExt;
    use windows::Win32::System::Diagnostics::ToolHelp::{
        CreateToolhelp32Snapshot, Process32FirstW, Process32NextW, PROCESSENTRY32W,
        TH32CS_SNAPPROCESS,
    };

    pub(super) fn open_gui() -> Result<()> {
        if is_gui_running()? {
            // GUI が起動済み → シグナルファイルを書いて表示を依頼
            std::fs::write(super::signal_file_path(), b"")?;
        } else {
            // GUI が未起動 → バイナリを起動
            launch_gui()?;
        }
        Ok(())
    }

    fn is_gui_running() -> Result<bool> {
        let app_lower = "muhenkan-switch";

        unsafe {
            let snapshot = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0)?;
            let mut entry = PROCESSENTRY32W {
                dwSize: std::mem::size_of::<PROCESSENTRY32W>() as u32,
                ..Default::default()
            };

            let mut found = false;
            if Process32FirstW(snapshot, &mut entry).is_ok() {
                loop {
                    let exe_len = entry
                        .szExeFile
                        .iter()
                        .position(|&c| c == 0)
                        .unwrap_or(entry.szExeFile.len());
                    let exe_name = OsString::from_wide(&entry.szExeFile[..exe_len])
                        .to_string_lossy()
                        .to_ascii_lowercase();
                    if exe_name == app_lower || exe_name == format!("{}.exe", app_lower) {
                        found = true;
                        break;
                    }
                    if Process32NextW(snapshot, &mut entry).is_err() {
                        break;
                    }
                }
            }
            let _ = windows::Win32::Foundation::CloseHandle(snapshot);
            Ok(found)
        }
    }

    fn launch_gui() -> Result<()> {
        use std::os::windows::process::CommandExt;
        use std::process::Command;
        const CREATE_NO_WINDOW: u32 = 0x08000000;

        let path = super::gui_binary_path()
            .ok_or_else(|| anyhow::anyhow!("muhenkan-switch の実行ファイルが見つかりません"))?;

        Command::new(path)
            .creation_flags(CREATE_NO_WINDOW)
            .spawn()?;
        Ok(())
    }
}

// ── Platform: Linux ──

#[cfg(target_os = "linux")]
mod imp {
    use super::*;
    use std::process::Command;

    pub(super) fn open_gui() -> Result<()> {
        if is_gui_running() {
            std::fs::write(super::signal_file_path(), b"")?;
        } else {
            launch_gui()?;
        }
        Ok(())
    }

    fn is_gui_running() -> bool {
        Command::new("pgrep")
            .args(["-x", "muhenkan-switch"])
            .output()
            .map(|o| o.status.success())
            .unwrap_or(false)
    }

    fn launch_gui() -> Result<()> {
        let path = super::gui_binary_path()
            .ok_or_else(|| anyhow::anyhow!("muhenkan-switch の実行ファイルが見つかりません"))?;
        Command::new(path).spawn()?;
        Ok(())
    }
}

// ── Platform: macOS ──

#[cfg(target_os = "macos")]
mod imp {
    use super::*;
    use std::process::Command;

    pub(super) fn open_gui() -> Result<()> {
        // osascript の activate は未起動なら起動、起動済みなら前面化する。
        // macOS は Tauri の WebviewWindow が osascript で正しく制御できるため
        // シグナルファイル方式は不要。
        let ok = Command::new("osascript")
            .args(["-e", r#"tell application "muhenkan-switch" to activate"#])
            .output()
            .map(|o| o.status.success())
            .unwrap_or(false);

        if !ok {
            if let Some(path) = super::gui_binary_path() {
                Command::new(path).spawn()?;
            }
        }

        Ok(())
    }
}
