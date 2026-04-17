use anyhow::{Context, Result};

use super::toast::Toast;

/// タイムスタンプの position (before/after) をトグルして config.toml に保存する。
/// Toast には現在の設定でファイル名がどう変化するかの例を表示する
/// （GUI 設定画面のプレビューと同様の形式）。
pub fn toggle_position() -> Result<()> {
    let path = muhenkan_switch_config::config_path()
        .context("config.toml が見つかりません")?;

    let mut config = muhenkan_switch_config::load_from(&path)?;

    config.timestamp.position = match config.timestamp.position.as_str() {
        "before" => "after".to_string(),
        _ => "before".to_string(),
    };

    muhenkan_switch_config::save(&path, &config)?;

    let ts = chrono::Local::now()
        .format(&config.timestamp.format)
        .to_string();
    let delimiter = &config.timestamp.delimiter;
    let (label, example) = if config.timestamp.position == "after" {
        ("後", format!("FileName{delimiter}{ts}.txt"))
    } else {
        ("前", format!("{ts}{delimiter}FileName.txt"))
    };

    Toast::notify(&format!("タイムスタンプ位置: {label} ({example})"));

    Ok(())
}
