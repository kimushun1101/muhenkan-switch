use anyhow::Result;
use clap::{Parser, Subcommand};

mod commands;
mod config;

use commands::toast::Toast;

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
    /// 割当キーに対応するアクションを実行
    Dispatch {
        /// 割当キー (config.toml の key フィールドに対応)
        key: String,
    },
    /// GUI 設定ウィンドウを前面に出す（未起動なら起動する）
    OpenGui,
    /// キーボードレイアウト図を SVG で生成
    GenerateSvg {
        /// 出力ファイルパス（省略時は stdout）
        #[arg(short, long)]
        output: Option<String>,
        /// config.toml パス（省略時は自動検出）
        #[arg(short, long)]
        config: Option<String>,
    },
}

fn main() {
    if let Err(e) = run() {
        let msg = format!("{e:#}");
        eprintln!("Error: {msg}");
        let toast = Toast::show(&msg);
        toast.finish(&msg);
    }
}

fn run() -> Result<()> {
    let cli = Cli::parse();

    // config 不要なコマンドは先に処理
    if let Commands::OpenGui = cli.command {
        return commands::open_gui::run();
    }

    // GenerateSvg は独自の config 読み込みを行う
    if let Commands::GenerateSvg {
        ref output,
        ref config,
    } = cli.command
    {
        let cfg = match config {
            Some(path) => muhenkan_switch_config::load_from(std::path::Path::new(path))?,
            None => muhenkan_switch_config::load()?,
        };
        let svg = muhenkan_switch_config::svg::generate(&cfg);
        match output {
            Some(path) => std::fs::write(path, &svg)?,
            None => print!("{}", svg),
        }
        return Ok(());
    }

    let config = config::load()?;

    match cli.command {
        Commands::Search { engine } => commands::search::run(&engine, &config),
        Commands::SwitchApp { target } => commands::switch_app::run(&target, &config),
        Commands::OpenFolder { target } => commands::open_folder::run(&target, &config),
        Commands::Timestamp { action } => commands::timestamp::run(&action, &config),
        Commands::Dispatch { key } => commands::dispatch::run(&key, &config),
        Commands::OpenGui | Commands::GenerateSvg { .. } => unreachable!(),
    }
}
