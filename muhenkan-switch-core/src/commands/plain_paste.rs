use anyhow::{Context, Result};
use arboard::Clipboard;

/// クリップボードのテキストを書式なしで直接入力する
pub fn run() -> Result<()> {
    let mut clipboard = Clipboard::new()?;
    let text = clipboard
        .get_text()
        .context("クリップボードにテキストがありません")?;
    super::keys::simulate_type(&text)
}
