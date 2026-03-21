/// 前面ウィンドウがファイルマネージャなら HWND 値を返す
pub fn get_foreground_explorer_hwnd() -> Option<isize> {
    imp::get_foreground_explorer_hwnd()
}

// ── Platform: Windows ──

#[cfg(target_os = "windows")]
mod imp {
    use std::ffi::OsString;
    use std::os::windows::ffi::OsStringExt;
    use windows::Win32::Foundation::CloseHandle;
    use windows::Win32::System::Diagnostics::ToolHelp::{
        CreateToolhelp32Snapshot, Process32FirstW, Process32NextW, PROCESSENTRY32W,
        TH32CS_SNAPPROCESS,
    };
    use windows::Win32::UI::WindowsAndMessaging::{GetForegroundWindow, GetWindowThreadProcessId};

    pub(super) fn get_foreground_explorer_hwnd() -> Option<isize> {
        unsafe {
            let hwnd = GetForegroundWindow();
            let mut pid: u32 = 0;
            GetWindowThreadProcessId(hwnd, Some(&mut pid));
            if pid == 0 {
                return None;
            }

            let snapshot = match CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0) {
                Ok(s) => s,
                Err(_) => return None,
            };

            let mut entry = PROCESSENTRY32W {
                dwSize: std::mem::size_of::<PROCESSENTRY32W>() as u32,
                ..Default::default()
            };

            let mut is_explorer = false;
            if Process32FirstW(snapshot, &mut entry).is_ok() {
                loop {
                    if entry.th32ProcessID == pid {
                        let exe_len = entry
                            .szExeFile
                            .iter()
                            .position(|&c| c == 0)
                            .unwrap_or(entry.szExeFile.len());
                        let exe_name = OsString::from_wide(&entry.szExeFile[..exe_len])
                            .to_string_lossy()
                            .to_ascii_lowercase();
                        is_explorer = exe_name == "explorer.exe";
                        break;
                    }
                    if Process32NextW(snapshot, &mut entry).is_err() {
                        break;
                    }
                }
            }
            let _ = CloseHandle(snapshot);

            if is_explorer {
                Some(hwnd.0 as isize)
            } else {
                None
            }
        }
    }
}

// ── Platform: Linux ──

#[cfg(target_os = "linux")]
mod imp {
    use std::process::Command;

    /// 既知のファイルマネージャの WM_CLASS 一覧（小文字）
    const FILE_MANAGERS: &[&str] = &[
        "nautilus",
        "org.gnome.nautilus",
        "thunar",
        "nemo",
        "pcmanfm",
        "pcmanfm-qt",
        "caja",
        "dolphin",
    ];

    /// xdotool + xprop で前面ウィンドウがファイルマネージャか判定する。
    /// ファイルマネージャならウィンドウ ID を返す（hwnd として使用）。
    pub(super) fn get_foreground_explorer_hwnd() -> Option<isize> {
        let wid_output = Command::new("xdotool")
            .arg("getactivewindow")
            .output()
            .ok()?;
        if !wid_output.status.success() {
            return None;
        }
        let wid = String::from_utf8_lossy(&wid_output.stdout)
            .trim()
            .to_string();
        if wid.is_empty() {
            return None;
        }

        let xprop_output = Command::new("xprop")
            .args(["-id", &wid, "WM_CLASS"])
            .output()
            .ok()?;
        let wm_class = String::from_utf8_lossy(&xprop_output.stdout).to_ascii_lowercase();

        if FILE_MANAGERS.iter().any(|fm| wm_class.contains(fm)) {
            wid.parse::<isize>().ok()
        } else {
            None
        }
    }
}

// ── Platform: macOS ──

#[cfg(target_os = "macos")]
mod imp {
    /// macOS: Finder の前面ウィンドウ検出は未実装。
    /// osascript で System Events / Finder の frontmost 判定が可能。
    /// See: https://github.com/kimushun1101/muhenkan-switch/issues/19
    pub(super) fn get_foreground_explorer_hwnd() -> Option<isize> {
        None
    }
}
