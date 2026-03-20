use anyhow::Result;
#[cfg(not(target_os = "windows"))]
use std::process::Command;

use super::toast::Toast;
use crate::config::Config;

pub fn run(target: &str, config: &Config) -> Result<()> {
    let entry = config
        .apps
        .get(target)
        .ok_or_else(|| anyhow::anyhow!("アプリ '{}' が config.toml に定義されていません", target))?;

    let process_name = entry.process();
    let command = entry.command();

    imp::activate_window(process_name, command)
}

/// プロセスが見つからず launch コマンドも未設定の場合に Toast で通知する。
fn notify_process_not_found(app: &str) {
    let msg = format!("'{}' が見つかりません — config.toml の command を設定してください", app);
    let toast = Toast::show(&msg);
    toast.finish(&msg);
}

/// wmctrl / xdotool の両方が未インストールの場合に警告を出す。
#[cfg(target_os = "linux")]
fn warn_no_window_tools() {
    eprintln!(
        "Warning: wmctrl / xdotool がインストールされていません。\n\
         アプリ切り替え機能を使うには以下のコマンドでインストールしてください:\n  \
         sudo apt install wmctrl xdotool"
    );
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
    use windows::Win32::System::Threading::{AttachThreadInput, GetCurrentThreadId};
    use windows::Win32::UI::Input::KeyboardAndMouse::{
        SendInput, INPUT, INPUT_0, INPUT_KEYBOARD, KEYBDINPUT, KEYEVENTF_KEYUP,
        VK_MENU,
    };
    use windows::Win32::UI::WindowsAndMessaging::{
        EnumWindows, GetForegroundWindow, GetWindowThreadProcessId, IsIconic, IsWindowVisible,
        SetForegroundWindow, ShowWindow, SW_RESTORE,
    };
    use windows::core::BOOL;
    use windows::Win32::Foundation::{HWND, LPARAM};

    pub(super) fn activate_window(app: &str, launch: Option<&str>) -> Result<()> {
        // --- Step 1: Find PIDs matching the process name ---
        let app_lower = app.to_ascii_lowercase();
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
                    // Match with or without .exe extension
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
            // Process not found — launch if configured, otherwise notify
            if let Some(cmd) = launch {
                shell_execute(cmd)?;
            } else {
                notify_process_not_found(app);
            }
            return Ok(());
        }

        // --- Step 2: Find a visible top-level window belonging to one of the PIDs ---
        struct CallbackData {
            pids: Vec<u32>,
            hwnd: Option<HWND>,
        }

        unsafe extern "system" fn enum_callback(hwnd: HWND, lparam: LPARAM) -> BOOL {
            let data = &mut *(lparam.0 as *mut CallbackData);
            let mut pid: u32 = 0;
            GetWindowThreadProcessId(hwnd, Some(&mut pid));
            if data.pids.contains(&pid) && IsWindowVisible(hwnd).as_bool() {
                data.hwnd = Some(hwnd);
                return BOOL(0); // stop enumeration
            }
            BOOL(1) // continue
        }

        let mut data = CallbackData {
            pids,
            hwnd: None,
        };

        unsafe {
            let _ = EnumWindows(
                Some(enum_callback),
                LPARAM(&mut data as *mut CallbackData as isize),
            );
        }

        let hwnd = match data.hwnd {
            Some(h) => h,
            None => {
                // Window not found — launch if configured, otherwise notify
                if let Some(cmd) = launch {
                    shell_execute(cmd)?;
                } else {
                    notify_process_not_found(app);
                }
                return Ok(());
            }
        };

        // --- Step 3: Activate the window ---
        unsafe {
            let fg_hwnd = GetForegroundWindow();
            let fg_thread = GetWindowThreadProcessId(fg_hwnd, None);
            let cur_thread = GetCurrentThreadId();

            let attached = if fg_thread != cur_thread {
                AttachThreadInput(cur_thread, fg_thread, true).as_bool()
            } else {
                false
            };

            // Alt キーの press/release をシミュレートして、Windows に
            // 「このプロセスがキー入力を受けた」と認識させる。
            // これにより SetForegroundWindow がバックグラウンドからでも成功する。
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

    /// コンソールウィンドウを出さずにアプリを起動する。
    /// .cmd/.bat は cmd.exe 経由(CREATE_NO_WINDOW)、それ以外は ShellExecuteW。
    fn shell_execute(cmd: &str) -> Result<()> {
        // コマンドが .cmd/.bat で終わるか、PATH 上に .cmd/.bat として存在するか確認
        if needs_cmd_exe(cmd) {
            use std::os::windows::process::CommandExt;
            use std::process::Command;
            const CREATE_NO_WINDOW: u32 = 0x08000000;
            Command::new("cmd")
                .args(["/C", "start", "/B", "", cmd])
                .creation_flags(CREATE_NO_WINDOW)
                .spawn()?;
        } else {
            use windows::core::PCWSTR;
            use windows::Win32::UI::Shell::ShellExecuteW;
            use windows::Win32::UI::WindowsAndMessaging::SW_SHOWNORMAL;

            let cmd_wide: Vec<u16> = cmd.encode_utf16().chain(std::iter::once(0)).collect();
            unsafe {
                ShellExecuteW(
                    None,
                    None,
                    PCWSTR::from_raw(cmd_wide.as_ptr()),
                    None,
                    None,
                    SW_SHOWNORMAL,
                );
            }
        }
        Ok(())
    }

    /// コマンドが .cmd/.bat ファイルかどうかを判定する
    fn needs_cmd_exe(cmd: &str) -> bool {
        let cmd_lower = cmd.to_ascii_lowercase();
        // 明示的な拡張子
        if cmd_lower.ends_with(".cmd") || cmd_lower.ends_with(".bat") {
            return true;
        }
        // PATH 上に .cmd/.bat として存在するか探索
        if let Ok(path_var) = std::env::var("PATH") {
            for dir in path_var.split(';') {
                let dir = std::path::Path::new(dir);
                if dir.join(format!("{}.cmd", cmd)).exists()
                    || dir.join(format!("{}.bat", cmd)).exists()
                {
                    return true;
                }
            }
        }
        false
    }
}

// ── Platform: Linux ──

#[cfg(target_os = "linux")]
mod imp {
    use super::*;

    pub(super) fn activate_window(app: &str, launch: Option<&str>) -> Result<()> {
        if is_wayland() {
            activate_window_wayland(app, launch)
        } else {
            activate_window_x11(app, launch)
        }
    }

    fn is_wayland() -> bool {
        super::super::is_wayland()
    }

    /// Wayland 環境でのウィンドウアクティブ化
    /// GNOME Shell の Eval API は制限されているため、以下の順で試行:
    /// 1. xdotool (XWayland 経由で動く場合がある)
    /// 2. wmctrl -x (XWayland 経由)
    /// 3. アプリを起動（既存インスタンスがあれば D-Bus 経由でフォーカスされるアプリもある）
    fn activate_window_wayland(app: &str, launch: Option<&str>) -> Result<()> {
        // XWayland 経由で動く可能性があるので X11 ツールを試す
        let activated = try_wmctrl(app)
            || try_xdotool(app, "--class")
            || try_xdotool(app, "--name");

        if !activated {
            if !has_command("wmctrl") && !has_command("xdotool") {
                warn_no_window_tools();
            }
            if let Some(cmd) = launch {
                if let Err(e) = Command::new("sh").args(["-c", cmd]).spawn() {
                    eprintln!("Warning: failed to launch '{}': {}", cmd, e);
                }
            } else {
                notify_process_not_found(app);
            }
        }

        Ok(())
    }

    /// X11 環境でのウィンドウアクティブ化
    /// 1. wmctrl -x -a (WM_CLASS でマッチ — タイトルより安定)
    /// 2. xdotool search --class (WM_CLASS でマッチ)
    /// 3. xdotool search --name (ウィンドウタイトルでマッチ)
    fn activate_window_x11(app: &str, launch: Option<&str>) -> Result<()> {
        let activated = try_wmctrl(app)
            || try_xdotool(app, "--class")
            || try_xdotool(app, "--name");

        if !activated {
            if !has_command("wmctrl") && !has_command("xdotool") {
                warn_no_window_tools();
            }
            if let Some(cmd) = launch {
                if let Err(e) = Command::new("sh").args(["-c", cmd]).spawn() {
                    eprintln!("Warning: failed to launch '{}': {}", cmd, e);
                }
            } else {
                notify_process_not_found(app);
            }
        }

        Ok(())
    }

    /// コマンドが PATH 上に存在するか確認する
    fn has_command(cmd: &str) -> bool {
        Command::new("which")
            .arg(cmd)
            .output()
            .map(|o| o.status.success())
            .unwrap_or(false)
    }

    pub(super) fn try_wmctrl(app: &str) -> bool {
        // -x: WM_CLASS でマッチ（ウィンドウタイトルより安定）
        Command::new("wmctrl")
            .args(["-x", "-a", app])
            .output()
            .map(|o| o.status.success())
            .unwrap_or(false)
    }

    pub(super) fn try_xdotool(app: &str, search_flag: &str) -> bool {
        // --onlyvisible: 不可視の内部ウィンドウを除外（これがないと GNOME で失敗する）
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
}

// ── Platform: macOS ──

#[cfg(target_os = "macos")]
mod imp {
    use super::*;

    pub(super) fn activate_window(app: &str, launch: Option<&str>) -> Result<()> {
        // osascript の activate は未起動アプリも自動起動する
        // launch が設定されていればそちらを優先
        let target = launch.unwrap_or(app);
        Command::new("osascript")
            .args(["-e", &format!(r#"tell application "{}" to activate"#, target)])
            .output()?;
        Ok(())
    }
}

// ── Tests ──

#[cfg(test)]
mod tests {
    use super::*;

    #[cfg(target_os = "linux")]
    #[test]
    fn try_wmctrl_nonexistent_app_returns_false() {
        // 存在しないアプリ名で wmctrl を試行 → false（パニックしない）
        assert!(!imp::try_wmctrl("__nonexistent_app_muhenkan_test_99999__"));
    }

    #[cfg(target_os = "linux")]
    #[test]
    fn try_xdotool_class_nonexistent_returns_false() {
        assert!(!imp::try_xdotool(
            "__nonexistent_app_muhenkan_test_99999__",
            "--class"
        ));
    }

    #[cfg(target_os = "linux")]
    #[test]
    fn try_xdotool_name_nonexistent_returns_false() {
        assert!(!imp::try_xdotool(
            "__nonexistent_app_muhenkan_test_99999__",
            "--name"
        ));
    }

    #[cfg(target_os = "linux")]
    #[test]
    fn activate_window_nonexistent_no_launch_returns_ok() {
        // 存在しないアプリ、launch なし → エラーにならず Ok
        let result = imp::activate_window("__nonexistent_app_muhenkan_test_99999__", None);
        assert!(result.is_ok());
    }

    #[cfg(target_os = "linux")]
    #[test]
    fn activate_window_nonexistent_with_bad_launch_returns_ok() {
        // launch コマンドが失敗しても eprintln で警告のみ、Ok を返す
        let result = imp::activate_window(
            "__nonexistent_app_muhenkan_test_99999__",
            Some("/bin/__nonexistent_command_99999__"),
        );
        assert!(result.is_ok());
    }

    #[cfg(target_os = "linux")]
    #[test]
    fn is_wayland_returns_bool() {
        // Wayland 判定がパニックしないことを確認（結果は環境依存）
        let _ = super::super::is_wayland();
    }

    #[test]
    fn run_missing_app_errors() {
        let config = Config {
            punctuation_style: "、。".to_string(),
            search: Default::default(),
            folders: Default::default(),
            apps: Default::default(),
            timestamp: Default::default(),
        };
        let result = run("nonexistent", &config);
        assert!(result.is_err());
        assert!(result.unwrap_err().to_string().contains("定義されていません"));
    }
}
