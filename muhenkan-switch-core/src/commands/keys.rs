use anyhow::Result;

pub fn simulate_copy() -> Result<()> {
    imp::simulate_copy()
}

pub fn simulate_type(text: &str) -> Result<()> {
    imp::simulate_type(text)
}

/// 選択中のテキストを取得する。
/// Wayland: PRIMARY セレクションから直接読み取り（キー入力シミュレーション不要）
/// X11/Windows/macOS: Ctrl+C シミュレート → CLIPBOARD から取得
pub fn get_selected_text() -> Result<String> {
    imp::get_selected_text()
}

// ── Platform: Windows ──

#[cfg(target_os = "windows")]
mod imp {
    use super::*;
    use std::mem;
    use windows::Win32::UI::Input::KeyboardAndMouse::{
        SendInput, INPUT, INPUT_KEYBOARD, KEYBDINPUT, KEYEVENTF_KEYUP, KEYEVENTF_UNICODE,
        VIRTUAL_KEY, VK_C, VK_CONTROL,
    };

    pub(super) fn simulate_copy() -> Result<()> {
        send_ctrl_key(VK_C)
    }

    pub(super) fn get_selected_text() -> Result<String> {
        simulate_copy()?;
        std::thread::sleep(std::time::Duration::from_millis(200));
        let mut clipboard = arboard::Clipboard::new()?;
        clipboard
            .get_text()
            .map_err(|e| anyhow::anyhow!("{}", e))
    }

    pub(super) fn simulate_type(text: &str) -> Result<()> {
        let mut inputs: Vec<INPUT> = Vec::new();
        for c in text.encode_utf16() {
            let mut down = INPUT::default();
            down.r#type = INPUT_KEYBOARD;
            down.Anonymous.ki = KEYBDINPUT {
                wScan: c,
                dwFlags: KEYEVENTF_UNICODE,
                ..Default::default()
            };
            let mut up = INPUT::default();
            up.r#type = INPUT_KEYBOARD;
            up.Anonymous.ki = KEYBDINPUT {
                wScan: c,
                dwFlags: KEYEVENTF_UNICODE | KEYEVENTF_KEYUP,
                ..Default::default()
            };
            inputs.push(down);
            inputs.push(up);
        }
        unsafe {
            let sent = SendInput(&inputs, mem::size_of::<INPUT>() as i32);
            if sent != inputs.len() as u32 {
                anyhow::bail!(
                    "SendInput failed: only {} of {} inputs sent",
                    sent,
                    inputs.len()
                );
            }
        }
        Ok(())
    }

    /// Send Ctrl+<key> via Win32 SendInput.
    fn send_ctrl_key(vk: VIRTUAL_KEY) -> Result<()> {
        unsafe {
            let mut inputs = [INPUT::default(), INPUT::default(), INPUT::default(), INPUT::default()];

            // Ctrl down
            inputs[0].r#type = INPUT_KEYBOARD;
            inputs[0].Anonymous.ki = KEYBDINPUT {
                wVk: VK_CONTROL,
                ..Default::default()
            };

            // Key down
            inputs[1].r#type = INPUT_KEYBOARD;
            inputs[1].Anonymous.ki = KEYBDINPUT {
                wVk: vk,
                ..Default::default()
            };

            // Key up
            inputs[2].r#type = INPUT_KEYBOARD;
            inputs[2].Anonymous.ki = KEYBDINPUT {
                wVk: vk,
                dwFlags: KEYEVENTF_KEYUP,
                ..Default::default()
            };

            // Ctrl up
            inputs[3].r#type = INPUT_KEYBOARD;
            inputs[3].Anonymous.ki = KEYBDINPUT {
                wVk: VK_CONTROL,
                dwFlags: KEYEVENTF_KEYUP,
                ..Default::default()
            };

            let sent = SendInput(&inputs, mem::size_of::<INPUT>() as i32);
            if sent != 4 {
                anyhow::bail!("SendInput failed: only {} of 4 inputs sent", sent);
            }
        }
        Ok(())
    }
}

// ── Platform: Linux ──

#[cfg(target_os = "linux")]
mod imp {
    use super::*;
    use anyhow::Context;
    use std::process::Command;

    fn run_xdotool(args: &[&str]) -> Result<()> {
        Command::new("xdotool")
            .args(args)
            .output()
            .context("xdotool が見つかりません。以下のコマンドでインストールしてください:\n  sudo apt install xdotool")?;
        Ok(())
    }

    pub(super) fn simulate_copy() -> Result<()> {
        run_xdotool(&["key", "ctrl+c"])
    }

    pub(super) fn simulate_type(text: &str) -> Result<()> {
        if super::super::is_wayland() {
            anyhow::bail!(
                "Wayland ではタイムスタンプ入力は未対応です。\n\
                 X11 セッションに切り替えるか、手動で貼り付けてください。"
            );
        }
        // IME が有効だと xdotool type が全角入力になるため、
        // クリップボード経由で貼り付ける
        let mut clipboard = arboard::Clipboard::new()?;
        let saved = clipboard.get_text().ok();
        clipboard.set_text(text)?;
        std::thread::sleep(std::time::Duration::from_millis(50));
        run_xdotool(&["key", "--clearmodifiers", "ctrl+v"])?;
        std::thread::sleep(std::time::Duration::from_millis(100));
        if let Some(prev) = saved {
            let _ = clipboard.set_text(prev);
        }
        Ok(())
    }

    pub(super) fn get_selected_text() -> Result<String> {
        if super::super::is_wayland() {
            // PRIMARY セレクションから選択テキストを直接読み取り
            let output = Command::new("wl-paste")
                .args(["--primary", "--no-newline"])
                .output()
                .context(
                    "wl-paste が見つかりません。以下のコマンドでインストールしてください:\n  \
                     sudo apt install wl-clipboard",
                )?;
            if !output.status.success() {
                anyhow::bail!("選択テキストの取得に失敗しました");
            }
            Ok(String::from_utf8_lossy(&output.stdout).into_owned())
        } else {
            // X11: Ctrl+C → CLIPBOARD から取得
            run_xdotool(&["key", "ctrl+c"])?;
            std::thread::sleep(std::time::Duration::from_millis(200));
            let mut clipboard = arboard::Clipboard::new()?;
            clipboard
                .get_text()
                .context("クリップボードにテキストがありません")
        }
    }
}

// ── Platform: macOS ──

#[cfg(target_os = "macos")]
mod imp {
    use super::*;
    use std::process::Command;

    pub(super) fn simulate_copy() -> Result<()> {
        Command::new("osascript")
            .args([
                "-e",
                r#"tell application "System Events" to keystroke "c" using command down"#,
            ])
            .output()?;
        Ok(())
    }

    pub(super) fn get_selected_text() -> Result<String> {
        simulate_copy()?;
        std::thread::sleep(std::time::Duration::from_millis(200));
        let mut clipboard = arboard::Clipboard::new()?;
        clipboard
            .get_text()
            .map_err(|e| anyhow::anyhow!("{}", e))
    }

    pub(super) fn simulate_type(text: &str) -> Result<()> {
        Command::new("osascript")
            .args([
                "-e",
                &format!(
                    r#"tell application "System Events" to keystroke "{}""#,
                    text
                ),
            ])
            .output()?;
        Ok(())
    }
}
