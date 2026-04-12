use anyhow::{Context, Result};

use super::toast::Toast;

/// タイムスタンプの position (before/after) をトグルして config.toml に保存する。
pub fn toggle_position() -> Result<()> {
    let path = muhenkan_switch_config::config_path()
        .context("config.toml が見つかりません")?;

    let mut config = muhenkan_switch_config::load_from(&path)?;

    config.timestamp.position = match config.timestamp.position.as_str() {
        "before" => "after".to_string(),
        _ => "before".to_string(),
    };

    muhenkan_switch_config::save(&path, &config)?;

    let msg = format!("Timestamp position: {}", config.timestamp.position);
    let toast = Toast::show(&msg);
    toast.finish(&msg);

    Ok(())
}

/// タイムスタンプの現在設定を Toast で表示する。
pub fn show_status() -> Result<()> {
    let config = muhenkan_switch_config::load()?;

    let example = chrono::Local::now()
        .format(&config.timestamp.format)
        .to_string();
    let msg = format!(
        "Timestamp: {} ({})\nposition: {}",
        config.timestamp.format, example, config.timestamp.position
    );
    let toast = Toast::show(&msg);
    toast.finish(&msg);

    Ok(())
}
