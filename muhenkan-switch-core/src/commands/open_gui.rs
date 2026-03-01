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
    use windows::Win32::Foundation::{HWND, LPARAM};
    use windows::Win32::System::Diagnostics::ToolHelp::{
        CreateToolhelp32Snapshot, Process32FirstW, Process32NextW, PROCESSENTRY32W,
        TH32CS_SNAPPROCESS,
    };
    use windows::Win32::System::Threading::{AttachThreadInput, GetCurrentThreadId};
    use windows::Win32::UI::Input::KeyboardAndMouse::{
        SendInput, INPUT, INPUT_0, INPUT_KEYBOARD, KEYBDINPUT, KEYEVENTF_KEYUP, VK_MENU,
    };
    use windows::Win32::UI::WindowsAndMessaging::{
        EnumWindows, GetForegroundWindow, GetWindowThreadProcessId, IsIconic, SetForegroundWindow,
        ShowWindow, SW_RESTORE, SW_SHOW,
    };
    use windows::core::BOOL;

    pub(super) fn open_gui() -> Result<()> {
        // --- Step 1: Find PIDs matching "muhenkan-switch" ---
        let app_lower = "muhenkan-switch";
        let mut pids = Vec::new();

        unsafe {
            let snapshot = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0)?;
            let mut entry = PROCESSENTRY32W {
                dwSize: std::mem::size_of::<PROCESSENTRY32W>() as u32,
                ..Default::default()
            };

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
                        pids.push(entry.th32ProcessID);
                    }
                    if Process32NextW(snapshot, &mut entry).is_err() {
                        break;
                    }
                }
            }
            let _ = windows::Win32::Foundation::CloseHandle(snapshot);
        }

        if pids.is_empty() {
            return launch_gui();
        }

        // --- Step 2: Find a top-level window belonging to the GUI process ---
        // IsWindowVisible チェックを外すことで、トレイ格納中（非表示）の
        // ウィンドウも対象にする。
        struct CallbackData {
            pids: Vec<u32>,
            hwnd: Option<HWND>,
        }

        unsafe extern "system" fn enum_callback(hwnd: HWND, lparam: LPARAM) -> BOOL {
            let data = &mut *(lparam.0 as *mut CallbackData);
            let mut pid: u32 = 0;
            GetWindowThreadProcessId(hwnd, Some(&mut pid));
            if data.pids.contains(&pid) {
                data.hwnd = Some(hwnd);
                return BOOL(0); // stop enumeration
            }
            BOOL(1) // continue
        }

        let mut data = CallbackData { pids, hwnd: None };
        unsafe {
            let _ = EnumWindows(
                Some(enum_callback),
                LPARAM(&mut data as *mut CallbackData as isize),
            );
        }

        let hwnd = match data.hwnd {
            Some(h) => h,
            None => return Ok(()),
        };

        // --- Step 3: Show and activate the window ---
        unsafe {
            let fg_hwnd = GetForegroundWindow();
            let fg_thread = GetWindowThreadProcessId(fg_hwnd, None);
            let cur_thread = GetCurrentThreadId();

            let attached = if fg_thread != cur_thread {
                AttachThreadInput(cur_thread, fg_thread, true).as_bool()
            } else {
                false
            };

            // Alt press/release でフォアグラウンド権限を取得
            let alt_down = INPUT {
                r#type: INPUT_KEYBOARD,
                Anonymous: INPUT_0 {
                    ki: KEYBDINPUT {
                        wVk: VK_MENU,
                        ..Default::default()
                    },
                },
            };
            let alt_up = INPUT {
                r#type: INPUT_KEYBOARD,
                Anonymous: INPUT_0 {
                    ki: KEYBDINPUT {
                        wVk: VK_MENU,
                        dwFlags: KEYEVENTF_KEYUP,
                        ..Default::default()
                    },
                },
            };
            SendInput(&[alt_down, alt_up], size_of::<INPUT>() as i32);

            // トレイ格納中（非表示）のウィンドウも表示する
            let _ = ShowWindow(hwnd, SW_SHOW);
            if IsIconic(hwnd).as_bool() {
                let _ = ShowWindow(hwnd, SW_RESTORE);
            }
            let _ = SetForegroundWindow(hwnd);

            if attached {
                let _ = AttachThreadInput(cur_thread, fg_thread, false);
            }
        }

        Ok(())
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
        let activated = try_wmctrl("muhenkan-switch")
            || try_xdotool("muhenkan-switch", "--class")
            || try_xdotool("muhenkan-switch", "--name");

        if !activated {
            launch_gui()?;
        }

        Ok(())
    }

    fn try_wmctrl(app: &str) -> bool {
        Command::new("wmctrl")
            .args(["-x", "-a", app])
            .output()
            .map(|o| o.status.success())
            .unwrap_or(false)
    }

    fn try_xdotool(app: &str, search_flag: &str) -> bool {
        let result = Command::new("xdotool")
            .args(["search", "--onlyvisible", search_flag, app])
            .output();
        match result {
            Ok(output) if output.status.success() => {
                let stdout = String::from_utf8_lossy(&output.stdout);
                if let Some(wid) = stdout.lines().next() {
                    Command::new("xdotool")
                        .args(["windowactivate", "--sync", wid])
                        .output()
                        .map(|o| o.status.success())
                        .unwrap_or(false)
                } else {
                    false
                }
            }
            _ => false,
        }
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
        // osascript の activate は未起動なら起動、起動済みなら前面化する
        let ok = Command::new("osascript")
            .args(["-e", r#"tell application "muhenkan-switch" to activate"#])
            .output()
            .map(|o| o.status.success())
            .unwrap_or(false);

        if !ok {
            // アプリ未登録など osascript が失敗した場合はバイナリを直接起動
            if let Some(path) = super::gui_binary_path() {
                Command::new(path).spawn()?;
            }
        }

        Ok(())
    }
}
