use anyhow::Result;

use crate::config::{self, Config};

pub fn run(engine: &str, config: &Config) -> Result<()> {
    // 検索エンジンのURLテンプレートを取得
    let url_template = config::get_search_url(&config.search, engine)?;

    // 選択テキストを取得
    let query = super::keys::get_selected_text()?;

    if query.trim().is_empty() {
        eprintln!("Warning: 選択テキストが空です。");
        return Ok(());
    }

    // URL組み立て＆ブラウザ起動
    let encoded = urlencoding::encode(query.trim());
    let url = url_template.replace("{query}", &encoded);
    webbrowser::open(&url)?;

    Ok(())
}
