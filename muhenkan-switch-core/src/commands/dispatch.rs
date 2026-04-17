use anyhow::Result;

use crate::config::{Config, DispatchAction};

pub fn run(key: &str, config: &Config) -> Result<()> {
    let action = config
        .dispatch_lookup(key)
        .ok_or_else(|| anyhow::anyhow!("キー '{}' に割り当てられたアクションがありません。無変換+F1 で開く GUI の設定画面でキーを割り当ててください", key))?;

    match action {
        DispatchAction::Search { engine } => super::search::run(&engine, config),
        DispatchAction::OpenFolder { target } => super::open_folder::run(&target, config),
        DispatchAction::SwitchApp { target } => super::switch_app::run(&target, config),
    }
}
