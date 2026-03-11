use anyhow::Result;
use clap::{Parser, Subcommand};

mod commands;
mod config;

#[derive(Parser)]
#[command(
    name = "muhenkan-switch-core",
    about = "muhenkan-switch-core key action tool",
    version
)]
struct Cli {
    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
enum Commands {
    /// 選択テキスト（クリップボード）をWeb検索
    Search {
        /// 検索エンジン名 (config.toml の [search] セクションのキー)
        #[arg(long)]
        engine: String,
    },
    /// 指定アプリを最前面に
    SwitchApp {
        /// アプリ名 (config.toml の [apps] セクションのキー)
        #[arg(long)]
        target: String,
    },
    /// 指定フォルダを開く
    OpenFolder {
        /// フォルダ名 (config.toml の [folders] セクションのキー)
        #[arg(long)]
        target: String,
    },
    /// タイムスタンプ操作
    Timestamp {
        /// アクション: paste, copy, cut
        #[arg(long)]
        action: String,
    },
    /// ディスパッチキーに対応するアクションを実行
    Dispatch {
        /// ディスパッチキー (config.toml の key フィールドに対応)
        key: String,
    },
    /// クリップボードをプレーンテキストとして入力
    PlainPaste,
    /// GUI 設定ウィンドウを前面に出す（未起動なら起動する）
    OpenGui,
}

fn main() -> Result<()> {
    let cli = Cli::parse();

    // config 不要なコマンドは先に処理
    match cli.command {
        Commands::OpenGui => return commands::open_gui::run(),
        Commands::PlainPaste => return commands::plain_paste::run(),
        _ => {}
    }

    let config = config::load()?;

    match cli.command {
        Commands::Search { engine } => commands::search::run(&engine, &config),
        Commands::SwitchApp { target } => commands::switch_app::run(&target, &config),
        Commands::OpenFolder { target } => commands::open_folder::run(&target, &config),
        Commands::Timestamp { action } => commands::timestamp::run(&action, &config),
        Commands::Dispatch { key } => commands::dispatch::run(&key, &config),
        Commands::PlainPaste | Commands::OpenGui => unreachable!(),
    }
}
