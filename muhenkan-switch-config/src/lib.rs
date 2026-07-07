use anyhow::{Context, Result};
use indexmap::IndexMap;
use serde::{Deserialize, Serialize};
use std::path::PathBuf;
use ts_rs::TS;

pub mod svg;

// ── Dispatch keys ──

/// kbd ファイルでディスパッチに割り当てられている物理キーの一覧。
pub const DISPATCH_KEYS: &[&str] = &[
    "1", "2", "3", "4", "5",
    "q", "w", "e", "r", "t",
    "a", "s", "d", "f", "g",
    "b",
];

// ── Types ──

/// 検索エンジンエントリ。割当キーで起動し、URL テンプレートにクエリを差し込んで検索する。
#[derive(Debug, Deserialize, Serialize, Clone, TS)]
#[ts(export, export_to = "config.ts")]
pub struct SearchEntry {
    /// ディスパッチキー（無指定可）。`DISPATCH_KEYS` から選ぶ。
    #[serde(skip_serializing_if = "Option::is_none")]
    #[ts(optional)]
    pub key: Option<String>,
    /// 検索 URL テンプレート。`{query}` プレースホルダがクエリ文字列に置換される。
    pub url: String,
}

impl SearchEntry {
    pub fn url(&self) -> &str {
        &self.url
    }

    pub fn dispatch_key(&self) -> Option<&str> {
        self.key.as_deref()
    }
}

/// フォルダエントリ。割当キーでファイルマネージャから対象フォルダを開く。
#[derive(Debug, Deserialize, Serialize, Clone, TS)]
#[ts(export, export_to = "config.ts")]
pub struct FolderEntry {
    /// ディスパッチキー（無指定可）。
    #[serde(skip_serializing_if = "Option::is_none")]
    #[ts(optional)]
    pub key: Option<String>,
    /// フォルダパス。`~/` 表記でホーム展開対応。
    pub path: String,
}

impl FolderEntry {
    pub fn path(&self) -> &str {
        &self.path
    }

    pub fn dispatch_key(&self) -> Option<&str> {
        self.key.as_deref()
    }
}

/// アプリエントリ。割当キーで対象プロセスのウィンドウを最前面化、未起動なら `command` で起動する。
#[derive(Debug, Deserialize, Serialize, Clone, TS)]
#[ts(export, export_to = "config.ts")]
pub struct AppEntry {
    /// ディスパッチキー（無指定可）。
    #[serde(skip_serializing_if = "Option::is_none")]
    #[ts(optional)]
    pub key: Option<String>,
    /// 対象プロセス名（ウィンドウ検索に使用）。
    pub process: String,
    /// 起動コマンド（省略時は `process` をフォールバックとして使用）。
    #[serde(skip_serializing_if = "Option::is_none")]
    #[ts(optional)]
    pub command: Option<String>,
}

impl AppEntry {
    pub fn process(&self) -> &str {
        &self.process
    }

    /// 起動コマンドを返す。未設定の場合はプロセス名をフォールバックとして使う。
    pub fn command(&self) -> Option<&str> {
        Some(self.command.as_deref().unwrap_or(&self.process))
    }

    pub fn dispatch_key(&self) -> Option<&str> {
        self.key.as_deref()
    }
}

#[derive(Debug, Clone)]
pub enum DispatchAction {
    Search { engine: String },
    OpenFolder { target: String },
    SwitchApp { target: String },
}

/// muhenkan-switch のトップレベル設定（`config.toml` のルート）。
#[derive(Debug, Deserialize, Serialize, Clone, TS)]
#[ts(export, export_to = "config.ts")]
pub struct Config {
    /// 検索エンジン一覧（割当キーで起動）。
    #[serde(default)]
    pub search: IndexMap<String, SearchEntry>,
    /// フォルダ一覧（割当キーで開く）。
    #[serde(default)]
    pub folders: IndexMap<String, FolderEntry>,
    /// アプリ一覧（割当キーでウィンドウ切替・起動）。
    #[serde(default)]
    pub apps: IndexMap<String, AppEntry>,
    /// タイムスタンプ挿入設定。
    #[serde(default)]
    pub timestamp: TimestampConfig,
    /// 句読点スタイル。kanata の kbd ファイルに反映される。
    #[serde(default)]
    pub punctuation_style: PunctuationStyle,
}

/// 句読点スタイル。kanata の kbd ファイルに反映される 4 種類。
/// TOML / JSON 上は `"、。"` のような文字列リテラルで表現される。
#[derive(Debug, Deserialize, Serialize, Clone, Copy, PartialEq, Eq, Default, TS)]
#[ts(export, export_to = "config.ts")]
pub enum PunctuationStyle {
    /// 「、」「。」（デフォルト）
    #[serde(rename = "、。")]
    #[default]
    TenMaru,
    /// 「，」「．」
    #[serde(rename = "，．")]
    CommaPeriod,
    /// 「，」「。」
    #[serde(rename = "，。")]
    CommaMaru,
    /// 「、」「．」
    #[serde(rename = "、．")]
    TenPeriod,
}

impl PunctuationStyle {
    /// kbd ファイル等で使う文字列表現（TOML / TS 上のリテラル値と一致）。
    pub fn as_str(&self) -> &'static str {
        match self {
            PunctuationStyle::TenMaru => "、。",
            PunctuationStyle::CommaPeriod => "，．",
            PunctuationStyle::CommaMaru => "，。",
            PunctuationStyle::TenPeriod => "、．",
        }
    }
}

impl Config {
    /// 割当キーに対応するアクションを検索する。
    pub fn dispatch_lookup(&self, key: &str) -> Option<DispatchAction> {
        for (name, entry) in &self.search {
            if entry.dispatch_key() == Some(key) {
                return Some(DispatchAction::Search {
                    engine: name.clone(),
                });
            }
        }
        for (name, entry) in &self.folders {
            if entry.dispatch_key() == Some(key) {
                return Some(DispatchAction::OpenFolder {
                    target: name.clone(),
                });
            }
        }
        for (name, entry) in &self.apps {
            if entry.dispatch_key() == Some(key) {
                return Some(DispatchAction::SwitchApp {
                    target: name.clone(),
                });
            }
        }
        None
    }
}

/// タイムスタンプ挿入設定。ファイル名等にタイムスタンプを付与するときの形式を制御する。
#[derive(Debug, Deserialize, Serialize, Clone, TS)]
#[ts(export, export_to = "config.ts")]
pub struct TimestampConfig {
    /// フォーマット文字列（chrono strftime 互換、例: `%Y%m%d`）。
    #[serde(default = "default_format")]
    pub format: String,
    /// 挿入位置: `"before"` | `"after"`。
    #[serde(default = "default_position")]
    pub position: String,
    /// 区切り文字。空文字で区切りなし。
    #[serde(default = "default_delimiter")]
    pub delimiter: String,
}

impl Default for TimestampConfig {
    fn default() -> Self {
        Self {
            format: default_format(),
            position: default_position(),
            delimiter: default_delimiter(),
        }
    }
}

fn default_format() -> String {
    "%Y%m%d".to_string()
}

fn default_position() -> String {
    "before".to_string()
}

fn default_delimiter() -> String {
    "_".to_string()
}

// ── Shared alongside-exe path resolution ──

/// 実行ファイルと同じディレクトリ、次に `manifest_dir/../bin/` の順で
/// `name` という名前のファイルを探索し、見つかった完全パスを返す。
///
/// muhenkan-switch (kanata バイナリ / kbd ファイル / muhenkan-switch-core バイナリ) と
/// muhenkan-switch-config (config.toml) に共通する「exe と同じディレクトリ →
/// ワークスペースルートの bin/」という 2 段探索を集約したヘルパー。
/// `manifest_dir` は呼び出し側クレートの `env!("CARGO_MANIFEST_DIR")` を渡す
/// (`env!` はマクロ展開されるクレート側のパスになるため、呼び出し元でしか取得できない)。
///
/// 探索順序:
/// 1. 実行ファイルと同じディレクトリ（インストール環境 / dev: ./bin/ 実行時）
/// 2. `manifest_dir`/../bin/（開発環境: cargo run 互換）
pub fn resolve_alongside_exe(name: &str, manifest_dir: &str) -> Option<PathBuf> {
    // 1. 実行ファイルと同じディレクトリ
    if let Ok(exe_path) = std::env::current_exe() {
        if let Some(dir) = exe_path.parent() {
            let path = dir.join(name);
            if path.exists() {
                return Some(path);
            }
        }
    }

    // 2. ワークスペースルートの bin/（開発環境）
    let bin_dir = PathBuf::from(manifest_dir).parent().map(|p| p.join("bin"));
    if let Some(dir) = bin_dir {
        let path = dir.join(name);
        if path.exists() {
            return Some(path);
        }
    }

    None
}

// ── Config path resolution ──

/// config.toml のパスを決定する。
/// 優先順位:
/// 1. 実行ファイルと同じディレクトリの config.toml（インストール環境 / dev: ./bin/ 実行時）
/// 2. CARGO_MANIFEST_DIR/../bin/config.toml（開発環境: cargo run 互換）
/// 3. 見つからなければ None（default_config() の embedded config で補完）
pub fn config_path() -> Option<PathBuf> {
    resolve_alongside_exe("config.toml", env!("CARGO_MANIFEST_DIR"))
}

/// 指定パスから config.toml を読み込む。
pub fn load_from(path: &std::path::Path) -> Result<Config> {
    let content = std::fs::read_to_string(path)
        .with_context(|| format!("設定ファイルの読み込みに失敗しました: {}", path.display()))?;
    let config: Config = toml::from_str(&content)
        .with_context(|| format!("設定ファイルの解析に失敗しました: {}", path.display()))?;
    Ok(config)
}

/// config.toml を自動検出して読み込む。見つからなければデフォルト値。
pub fn load() -> Result<Config> {
    match config_path() {
        Some(path) => load_from(&path),
        None => {
            eprintln!("警告: config.toml が見つかりません。デフォルト値を使用します。");
            Ok(default_config())
        }
    }
}

// デフォルト設定ファイルをコンパイル時にバイナリへ埋め込む。
// インストール済み環境でも env!("CARGO_MANIFEST_DIR") に依存せず参照できる。
const DEFAULT_WINDOWS_CONFIG: &str = include_str!("../../config/default-windows.toml");
const DEFAULT_LINUX_CONFIG: &str = include_str!("../../config/default-linux.toml");
const DEFAULT_MACOS_CONFIG: &str = include_str!("../../config/default-macos.toml");
const DEFAULT_CONFIG: &str = include_str!("../../config/default.toml");

/// デフォルト設定を返す。
/// バイナリに埋め込まれた OS 別デフォルト設定 → 共通デフォルト → 最小限フォールバックの順で試みる。
pub fn default_config() -> Config {
    // 1. OS 別埋め込みデフォルト設定（コンパイル時にバイナリに組み込み済み）
    let os_default = match std::env::consts::OS {
        "windows" => DEFAULT_WINDOWS_CONFIG,
        "macos" => DEFAULT_MACOS_CONFIG,
        _ => DEFAULT_LINUX_CONFIG,
    };
    if let Ok(config) = toml::from_str(os_default) {
        return config;
    }

    // 2. 共通フォールバック（埋め込み）
    if let Ok(config) = toml::from_str(DEFAULT_CONFIG) {
        return config;
    }

    // 3. 最小限のフォールバック（通常はここに到達しない）
    Config {
        search: default_search_engines(),
        folders: IndexMap::new(),
        apps: IndexMap::new(),
        timestamp: TimestampConfig::default(),
        punctuation_style: PunctuationStyle::default(),
    }
}

fn default_search_engines() -> IndexMap<String, SearchEntry> {
    let mut m = IndexMap::new();
    m.insert(
        "google".to_string(),
        SearchEntry {
            key: None,
            url: "https://www.google.com/search?q={query}".to_string(),
        },
    );
    m
}

// ── Save (comment-preserving) ──

/// config.toml にコメントを保持しつつ保存する。
/// 既存ファイルがあればコメントを保持、なければ新規作成。
/// エントリは割当キー順でソートされる（キーなしは末尾、名前順）。
pub fn save(path: &std::path::Path, config: &Config) -> Result<()> {
    use toml_edit::{DocumentMut, InlineTable, Item, Table, Value};

    // ソート用ヘルパー: dispatch key あり → key 昇順、なし → 名前昇順で末尾
    fn sort_key<'a>(dispatch_key: Option<&'a str>, name: &'a str) -> (u8, &'a str) {
        match dispatch_key {
            Some(k) => (0, k),
            None => (1, name),
        }
    }

    // 既存ファイルがあればパースして構造を保持、なければ空ドキュメント
    let existing = if path.exists() {
        std::fs::read_to_string(path)
            .unwrap_or_default()
            .parse::<DocumentMut>()
            .unwrap_or_default()
    } else {
        DocumentMut::new()
    };

    let mut doc = existing;

    // [search] セクション
    let search_table = doc
        .entry("search")
        .or_insert_with(|| Item::Table(Table::new()))
        .as_table_mut()
        .context("search セクションがテーブル形式ではありません")?;
    search_table.clear();
    let mut search_entries: Vec<_> = config.search.iter().collect();
    search_entries.sort_by(|(na, a), (nb, b)| {
        sort_key(a.dispatch_key(), na).cmp(&sort_key(b.dispatch_key(), nb))
    });
    for (name, entry) in search_entries {
        let mut inline = InlineTable::new();
        if let Some(dk) = &entry.key {
            inline.insert("key", Value::from(dk.as_str()));
        }
        inline.insert("url", Value::from(entry.url.as_str()));
        search_table[name] = toml_edit::value(inline);
    }

    // [folders] セクション
    let folders_table = doc
        .entry("folders")
        .or_insert_with(|| Item::Table(Table::new()))
        .as_table_mut()
        .context("folders セクションがテーブル形式ではありません")?;
    folders_table.clear();
    let mut folder_entries: Vec<_> = config.folders.iter().collect();
    folder_entries.sort_by(|(na, a), (nb, b)| {
        sort_key(a.dispatch_key(), na).cmp(&sort_key(b.dispatch_key(), nb))
    });
    for (name, entry) in folder_entries {
        let mut inline = InlineTable::new();
        if let Some(dk) = &entry.key {
            inline.insert("key", Value::from(dk.as_str()));
        }
        inline.insert("path", Value::from(entry.path.as_str()));
        folders_table[name] = toml_edit::value(inline);
    }

    // [apps] セクション
    let apps_table = doc
        .entry("apps")
        .or_insert_with(|| Item::Table(Table::new()))
        .as_table_mut()
        .context("apps セクションがテーブル形式ではありません")?;
    apps_table.clear();
    let mut app_entries: Vec<_> = config.apps.iter().collect();
    app_entries.sort_by(|(na, a), (nb, b)| {
        sort_key(a.dispatch_key(), na).cmp(&sort_key(b.dispatch_key(), nb))
    });
    for (name, entry) in app_entries {
        let mut inline = InlineTable::new();
        if let Some(dk) = &entry.key {
            inline.insert("key", Value::from(dk.as_str()));
        }
        inline.insert("process", Value::from(entry.process.as_str()));
        if let Some(cmd) = &entry.command {
            inline.insert("command", Value::from(cmd.as_str()));
        }
        apps_table[name] = toml_edit::value(inline);
    }

    // punctuation_style（トップレベル）
    doc["punctuation_style"] = toml_edit::value(config.punctuation_style.as_str());

    // [timestamp] セクション
    let ts_table = doc
        .entry("timestamp")
        .or_insert_with(|| Item::Table(Table::new()))
        .as_table_mut()
        .context("timestamp セクションがテーブル形式ではありません")?;
    ts_table["format"] = toml_edit::value(&config.timestamp.format);
    ts_table["position"] = toml_edit::value(&config.timestamp.position);
    ts_table["delimiter"] = toml_edit::value(&config.timestamp.delimiter);

    std::fs::write(path, doc.to_string())
        .with_context(|| format!("設定ファイルの書き込みに失敗しました: {}", path.display()))?;

    Ok(())
}

// ── Validation ──

/// 設定のバリデーション。エラーメッセージのリストを返す。
pub fn validate(config: &Config) -> Vec<String> {
    let mut errors = Vec::new();

    // timestamp format の検証
    if config.timestamp.format.is_empty() {
        errors.push("タイムスタンプのフォーマットを入力してください".to_string());
    } else if chrono::format::StrftimeItems::new(&config.timestamp.format)
        .any(|item| item == chrono::format::Item::Error)
    {
        errors.push(format!(
            "タイムスタンプのフォーマットが不正です（不明な指定子が含まれています）: \"{}\"",
            config.timestamp.format
        ));
    }

    // timestamp delimiter の検証 (空=区切りなし は許可)
    if !config.timestamp.delimiter.is_empty()
        && config
            .timestamp
            .delimiter
            .contains(&['/', '\\', ':', '*', '?', '"', '<', '>', '|'][..])
    {
        errors.push(format!(
            "区切り文字に使用できない文字が含まれています: \"{}\"",
            config.timestamp.delimiter
        ));
    }

    // timestamp position の検証
    if config.timestamp.position != "before" && config.timestamp.position != "after" {
        errors.push(format!(
            "タイムスタンプの位置は \"before\" か \"after\" を指定してください (現在: \"{}\")",
            config.timestamp.position
        ));
    }

    // punctuation_style は enum で型ガード済（serde が無効値を deserialize 段階で reject）。

    // search URL テンプレートの検証
    for (name, entry) in &config.search {
        if !entry.url().contains("{query}") {
            errors.push(format!(
                "検索エンジン '{}' の URL には {{query}} プレースホルダを含めてください",
                name
            ));
        }
    }

    // 割当キーの重複チェック
    let mut used_keys: IndexMap<String, String> = IndexMap::new();
    for (name, entry) in &config.search {
        if let Some(k) = entry.dispatch_key() {
            let label = format!("search/{}", name);
            if let Some(prev) = used_keys.get(k) {
                errors.push(format!(
                    "割当キー '{}' が '{}' と '{}' で重複しています",
                    k, prev, label
                ));
            } else {
                used_keys.insert(k.to_string(), label);
            }
        }
    }
    for (name, entry) in &config.folders {
        if let Some(k) = entry.dispatch_key() {
            let label = format!("folders/{}", name);
            if let Some(prev) = used_keys.get(k) {
                errors.push(format!(
                    "割当キー '{}' が '{}' と '{}' で重複しています",
                    k, prev, label
                ));
            } else {
                used_keys.insert(k.to_string(), label);
            }
        }
    }
    for (name, entry) in &config.apps {
        if let Some(k) = entry.dispatch_key() {
            let label = format!("apps/{}", name);
            if let Some(prev) = used_keys.get(k) {
                errors.push(format!(
                    "割当キー '{}' が '{}' と '{}' で重複しています",
                    k, prev, label
                ));
            } else {
                used_keys.insert(k.to_string(), label);
            }
        }
    }

    errors
}

// ── kbd punctuation rewrite ──

/// kbd ファイル内の句読点行を指定スタイルに書き換える。
pub fn rewrite_kbd_punctuation(
    kbd_path: &std::path::Path,
    style: &PunctuationStyle,
) -> Result<()> {
    let content = std::fs::read_to_string(kbd_path)
        .with_context(|| format!("kbd ファイルの読み込みに失敗しました: {}", kbd_path.display()))?;

    let patterns = [
        "(unicode 、)  (unicode 。)",
        "(unicode ，)  (unicode ．)",
        "(unicode ，)  (unicode 。)",
        "(unicode 、)  (unicode ．)",
    ];
    let new_fragment = match style {
        PunctuationStyle::TenMaru => "(unicode 、)  (unicode 。)",
        PunctuationStyle::CommaPeriod => "(unicode ，)  (unicode ．)",
        PunctuationStyle::CommaMaru => "(unicode ，)  (unicode 。)",
        PunctuationStyle::TenPeriod => "(unicode 、)  (unicode ．)",
    };

    let mut new_content = content.clone();
    for pat in &patterns {
        new_content = new_content.replace(pat, new_fragment);
    }

    std::fs::write(kbd_path, new_content)
        .with_context(|| format!("kbd ファイルの書き込みに失敗しました: {}", kbd_path.display()))?;

    Ok(())
}

// ── Helpers ──

/// 検索エンジンの URL テンプレートを取得する。
pub fn get_search_url<'a>(
    search: &'a IndexMap<String, SearchEntry>,
    engine: &str,
) -> Result<&'a str> {
    search
        .get(engine)
        .map(|e| e.url())
        .ok_or_else(|| anyhow::anyhow!("検索エンジン '{}' が config.toml に定義されていません", engine))
}

/// フォルダのパスを取得する。
pub fn get_folder_path<'a>(
    folders: &'a IndexMap<String, FolderEntry>,
    target: &str,
) -> Result<&'a str> {
    folders
        .get(target)
        .map(|e| e.path())
        .ok_or_else(|| anyhow::anyhow!("フォルダ '{}' が config.toml に定義されていません", target))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_default_config() {
        let config = default_config();
        assert_eq!(config.timestamp.format, "%Y%m%d");
        assert_eq!(config.timestamp.position, "before");
        assert!(config.search.contains_key("Google"));
        // OS 別デフォルトが正しくパースされ、全セクションが埋まっていること
        assert!(
            config.search.len() >= 5,
            "Expected at least 5 search engines, got {}",
            config.search.len()
        );
        assert!(
            !config.folders.is_empty(),
            "Expected non-empty folders, got empty"
        );
        assert!(
            !config.apps.is_empty(),
            "Expected non-empty apps, got empty"
        );
    }

    /// OS 別埋め込みデフォルト設定 (DEFAULT_WINDOWS_CONFIG / DEFAULT_LINUX_CONFIG /
    /// DEFAULT_MACOS_CONFIG) がホスト OS に関わらず全てパース可能で、
    /// folders/apps が空でないことを検証する。
    /// `default_config()` は実行時の `std::env::consts::OS` でしか分岐しないため、
    /// CI が単一 OS でしか走らない場合、他 OS 用ファイルの破損が見逃されうる (#220)。
    #[test]
    fn test_all_os_default_configs_parse_and_non_empty() {
        let cases: &[(&str, &str)] = &[
            ("windows", DEFAULT_WINDOWS_CONFIG),
            ("linux", DEFAULT_LINUX_CONFIG),
            ("macos", DEFAULT_MACOS_CONFIG),
        ];
        for (os, raw) in cases {
            let config: Config = toml::from_str(raw)
                .unwrap_or_else(|e| panic!("default-{} config が不正な TOML です: {}", os, e));
            assert!(
                !config.folders.is_empty(),
                "default-{} の folders が空です",
                os
            );
            assert!(!config.apps.is_empty(), "default-{} の apps が空です", os);
            assert!(
                config.search.len() >= 5,
                "default-{} の search エンジン数が想定未満です: {}",
                os,
                config.search.len()
            );
        }
    }

    #[test]
    fn test_validate_valid_config() {
        let config = default_config();
        let errors = validate(&config);
        assert!(errors.is_empty());
    }

    #[test]
    fn test_validate_invalid_position() {
        let mut config = default_config();
        config.timestamp.position = "middle".to_string();
        let errors = validate(&config);
        assert_eq!(errors.len(), 1);
        assert!(errors[0].contains("before"));
    }

    #[test]
    fn test_roundtrip_serialize() {
        let config = default_config();
        let toml_str = toml::to_string(&config).unwrap();
        let loaded: Config = toml::from_str(&toml_str).unwrap();
        assert_eq!(loaded.timestamp.format, config.timestamp.format);
    }

    #[test]
    fn test_parse_new_format_with_keys() {
        let toml_str = r#"
            [search]
            google = {key = "g", url = "https://www.google.com/search?q={query}"}

            [folders]
            documents = {key = "1", path = "~/Documents"}

            [apps]
            editor = {key = "a", process = "Code", command = "code"}
        "#;
        let config: Config = toml::from_str(toml_str).unwrap();
        assert_eq!(config.search["google"].url(), "https://www.google.com/search?q={query}");
        assert_eq!(config.search["google"].dispatch_key(), Some("g"));
        assert_eq!(config.folders["documents"].path(), "~/Documents");
        assert_eq!(config.folders["documents"].dispatch_key(), Some("1"));
        assert_eq!(config.apps["editor"].process(), "Code");
        assert_eq!(config.apps["editor"].dispatch_key(), Some("a"));
    }

    #[test]
    fn test_dispatch_lookup() {
        let toml_str = r#"
            [search]
            google = {key = "g", url = "https://www.google.com/search?q={query}"}

            [folders]
            documents = {key = "1", path = "~/Documents"}

            [apps]
            editor = {key = "a", process = "Code", command = "code"}
        "#;
        let config: Config = toml::from_str(toml_str).unwrap();

        match config.dispatch_lookup("g") {
            Some(DispatchAction::Search { engine }) => assert_eq!(engine, "google"),
            other => panic!("Expected Search, got {:?}", other),
        }
        match config.dispatch_lookup("1") {
            Some(DispatchAction::OpenFolder { target }) => assert_eq!(target, "documents"),
            other => panic!("Expected OpenFolder, got {:?}", other),
        }
        match config.dispatch_lookup("a") {
            Some(DispatchAction::SwitchApp { target }) => assert_eq!(target, "editor"),
            other => panic!("Expected SwitchApp, got {:?}", other),
        }
        assert!(config.dispatch_lookup("z").is_none());
    }

    #[test]
    fn test_validate_duplicate_keys() {
        let toml_str = r#"
            [search]
            google = {key = "a", url = "https://www.google.com/search?q={query}"}

            [apps]
            editor = {key = "a", process = "Code", command = "code"}
        "#;
        let config: Config = toml::from_str(toml_str).unwrap();
        let errors = validate(&config);
        assert_eq!(errors.len(), 1);
        assert!(errors[0].contains("割当キー 'a'"));
    }

    // ── A. パース (追加分) ──

    #[test]
    fn test_parse_without_key() {
        let toml_str = r#"
            [search]
            google = {url = "https://www.google.com/search?q={query}"}

            [folders]
            documents = {path = "~/Documents"}

            [apps]
            editor = {process = "Code", command = "code"}
        "#;
        let config: Config = toml::from_str(toml_str).unwrap();
        assert!(config.search["google"].dispatch_key().is_none());
        assert_eq!(config.search["google"].url(), "https://www.google.com/search?q={query}");
        assert!(config.folders["documents"].dispatch_key().is_none());
        assert!(config.apps["editor"].dispatch_key().is_none());
    }

    #[test]
    fn test_parse_empty_sections() {
        let toml_str = r#"
            [search]
            [folders]
            [apps]
        "#;
        let config: Config = toml::from_str(toml_str).unwrap();
        assert!(config.search.is_empty());
        assert!(config.folders.is_empty());
        assert!(config.apps.is_empty());
    }

    #[test]
    fn test_parse_missing_sections() {
        let toml_str = r#"
            [timestamp]
            format = "%Y%m%d"
            position = "before"
        "#;
        let config: Config = toml::from_str(toml_str).unwrap();
        assert!(config.search.is_empty());
        assert!(config.folders.is_empty());
        assert!(config.apps.is_empty());
    }

    // ── B. ディスパッチ検索 (追加分) ──

    #[test]
    fn test_dispatch_lookup_priority() {
        // search takes priority over apps when both have the same key
        let toml_str = r#"
            [search]
            google = {key = "a", url = "https://www.google.com/search?q={query}"}

            [apps]
            editor = {key = "a", process = "Code", command = "code"}
        "#;
        let config: Config = toml::from_str(toml_str).unwrap();
        match config.dispatch_lookup("a") {
            Some(DispatchAction::Search { engine }) => assert_eq!(engine, "google"),
            other => panic!("Expected Search (priority over Apps), got {:?}", other),
        }
    }

    // ── C. バリデーション (追加分) ──

    #[test]
    fn test_validate_empty_format() {
        let mut config = default_config();
        config.timestamp.format = String::new();
        let errors = validate(&config);
        assert_eq!(errors.len(), 1);
        assert!(errors[0].contains("フォーマット"));
    }

    #[test]
    fn test_validate_invalid_format_specifier() {
        // %Q は chrono に存在しない指定子 → StrftimeItems が Item::Error を返すはず
        let mut config = default_config();
        config.timestamp.format = "%Q".to_string();
        let errors = validate(&config);
        assert_eq!(errors.len(), 1, "Expected 1 error, got: {:?}", errors);
        assert!(errors[0].contains("不正"));
    }

    #[test]
    fn test_validate_valid_format_specifiers() {
        // 代表的な有効フォーマットは全て通ること
        for format in ["%Y-%m-%d", "%Y%m%d", "%Y-%m-%d_%H-%M-%S", "%F", "%c"] {
            let mut config = default_config();
            config.timestamp.format = format.to_string();
            let errors = validate(&config);
            assert!(
                errors.is_empty(),
                "format '{}' should be valid, got errors: {:?}",
                format,
                errors
            );
        }
    }

    #[test]
    fn test_validate_missing_query_placeholder() {
        let toml_str = r#"
            [search]
            bad = {key = "g", url = "https://example.com/search"}
        "#;
        let config: Config = toml::from_str(toml_str).unwrap();
        let errors = validate(&config);
        assert_eq!(errors.len(), 1);
        assert!(errors[0].contains("{query}"));
    }

    #[test]
    fn test_validate_duplicate_keys_same_section() {
        let toml_str = r#"
            [search]
            google = {key = "g", url = "https://www.google.com/search?q={query}"}
            ejje = {key = "g", url = "https://ejje.weblio.jp/content/{query}"}
        "#;
        let config: Config = toml::from_str(toml_str).unwrap();
        let errors = validate(&config);
        assert_eq!(errors.len(), 1);
        assert!(errors[0].contains("割当キー 'g'"));
        assert!(errors[0].contains("search/google"));
        assert!(errors[0].contains("search/ejje"));
    }

    #[test]
    fn test_validate_multiple_errors() {
        let mut config = default_config();
        config.timestamp.format = String::new();
        config.timestamp.position = "middle".to_string();
        config.search.insert(
            "bad".to_string(),
            SearchEntry {
                key: Some("g".to_string()),
                url: "https://example.com/no-placeholder".to_string(),
            },
        );
        let errors = validate(&config);
        assert!(errors.len() >= 3, "Expected at least 3 errors, got: {:?}", errors);
    }

    #[test]
    fn test_validate_all_keys_assigned() {
        let mut config = Config {
            search: IndexMap::new(),
            folders: IndexMap::new(),
            apps: IndexMap::new(),
            timestamp: TimestampConfig::default(),
            punctuation_style: PunctuationStyle::default(),
        };
        // Assign all 15 dispatch keys across sections
        let keys = DISPATCH_KEYS;
        for (i, key) in keys.iter().enumerate() {
            let name = format!("entry_{}", i);
            if i < 5 {
                config.search.insert(
                    name,
                    SearchEntry {
                        key: Some(key.to_string()),
                        url: format!("https://example.com/{}?q={{query}}", key),
                    },
                );
            } else if i < 10 {
                config.folders.insert(
                    name,
                    FolderEntry {
                        key: Some(key.to_string()),
                        path: format!("~/{}", key),
                    },
                );
            } else {
                config.apps.insert(
                    name,
                    AppEntry {
                        key: Some(key.to_string()),
                        process: format!("app_{}", key),
                        command: None,
                    },
                );
            }
        }
        let errors = validate(&config);
        assert!(errors.is_empty(), "Expected no errors, got: {:?}", errors);
    }

    // ── D. Save/Load ラウンドトリップ (追加分) ──

    #[test]
    fn test_roundtrip_save_load_detailed() {
        let toml_str = r#"
            [search]
            google = {key = "g", url = "https://www.google.com/search?q={query}"}

            [folders]
            documents = {key = "1", path = "~/Documents"}

            [apps]
            editor = {key = "a", process = "Code", command = "code"}

            [timestamp]
            format = "%Y%m%d"
            position = "before"
        "#;
        let config: Config = toml::from_str(toml_str).unwrap();

        let dir = std::env::temp_dir().join("muhenkan_test_roundtrip_detailed");
        std::fs::create_dir_all(&dir).unwrap();
        let path = dir.join("config.toml");

        save(&path, &config).unwrap();
        let loaded = load_from(&path).unwrap();

        // Verify search
        assert_eq!(loaded.search["google"].url(), "https://www.google.com/search?q={query}");
        assert_eq!(loaded.search["google"].dispatch_key(), Some("g"));

        // Verify folders
        assert_eq!(loaded.folders["documents"].path(), "~/Documents");
        assert_eq!(loaded.folders["documents"].dispatch_key(), Some("1"));

        // Verify apps
        assert_eq!(loaded.apps["editor"].process(), "Code");
        assert_eq!(loaded.apps["editor"].command(), Some("code"));
        assert_eq!(loaded.apps["editor"].dispatch_key(), Some("a"));

        // Verify timestamp
        assert_eq!(loaded.timestamp.format, "%Y%m%d");
        assert_eq!(loaded.timestamp.position, "before");

        // Cleanup
        std::fs::remove_dir_all(&dir).ok();
    }

    #[test]
    fn test_save_creates_file() {
        let dir = std::env::temp_dir().join("muhenkan_test_save_creates");
        // Ensure clean state
        std::fs::remove_dir_all(&dir).ok();
        std::fs::create_dir_all(&dir).unwrap();
        let path = dir.join("config.toml");
        assert!(!path.exists());

        let config = default_config();
        save(&path, &config).unwrap();
        assert!(path.exists());

        let loaded = load_from(&path).unwrap();
        assert_eq!(loaded.timestamp.format, "%Y%m%d");

        // Cleanup
        std::fs::remove_dir_all(&dir).ok();
    }

    #[test]
    fn test_save_sorts_by_dispatch_key() {
        // 名前のアルファベット順と割当キー順が異なるデータ
        let toml_str = r#"
            [search]
            gamma = {key = "g", url = "https://gamma.com/?q={query}"}
            alpha = {key = "t", url = "https://alpha.com/?q={query}"}
            beta = {key = "r", url = "https://beta.com/?q={query}"}
        "#;
        let config: Config = toml::from_str(toml_str).unwrap();

        let dir = std::env::temp_dir().join("muhenkan_test_sort_key");
        std::fs::create_dir_all(&dir).unwrap();
        let path = dir.join("config.toml");

        save(&path, &config).unwrap();
        let loaded = load_from(&path).unwrap();

        // dispatch key 順: g < r < t → gamma, beta, alpha
        let names: Vec<&String> = loaded.search.keys().collect();
        assert_eq!(names, vec!["gamma", "beta", "alpha"]);

        // Cleanup
        std::fs::remove_dir_all(&dir).ok();
    }

    // ── E. ヘルパー関数 ──

    #[test]
    fn test_get_search_url_found() {
        let mut search = IndexMap::new();
        search.insert(
            "google".to_string(),
            SearchEntry {
                key: Some("g".to_string()),
                url: "https://www.google.com/search?q={query}".to_string(),
            },
        );
        let url = get_search_url(&search, "google").unwrap();
        assert_eq!(url, "https://www.google.com/search?q={query}");
    }

    #[test]
    fn test_get_search_url_not_found() {
        let search = IndexMap::new();
        let result = get_search_url(&search, "nonexistent");
        assert!(result.is_err());
        assert!(result.unwrap_err().to_string().contains("nonexistent"));
    }

    #[test]
    fn test_get_folder_path_found() {
        let mut folders = IndexMap::new();
        folders.insert(
            "docs".to_string(),
            FolderEntry {
                key: Some("1".to_string()),
                path: "~/Documents".to_string(),
            },
        );
        let path = get_folder_path(&folders, "docs").unwrap();
        assert_eq!(path, "~/Documents");
    }

    #[test]
    fn test_get_folder_path_not_found() {
        let folders = IndexMap::new();
        let result = get_folder_path(&folders, "nonexistent");
        assert!(result.is_err());
        assert!(result.unwrap_err().to_string().contains("nonexistent"));
    }

    // ── F. PunctuationStyle (enum 化に伴うシリアライズ確認) ──

    #[test]
    fn test_punctuation_style_serde_all_variants() {
        // TOML 文字列リテラル ⇄ enum の双方向変換を全 4 variant で確認
        let cases = [
            ("、。", PunctuationStyle::TenMaru),
            ("，．", PunctuationStyle::CommaPeriod),
            ("，。", PunctuationStyle::CommaMaru),
            ("、．", PunctuationStyle::TenPeriod),
        ];
        for (literal, expected) in cases {
            let toml_str = format!("punctuation_style = \"{}\"\n", literal);
            let config: Config = toml::from_str(&toml_str).unwrap();
            assert_eq!(config.punctuation_style, expected, "deserialize: {}", literal);
            let dumped = toml::to_string(&config).unwrap();
            assert!(
                dumped.contains(&format!("punctuation_style = \"{}\"", literal)),
                "serialize round-trip should keep literal {}: actual = {}",
                literal,
                dumped
            );
        }
    }

    #[test]
    fn test_punctuation_style_default_when_missing() {
        // punctuation_style が省略された TOML はデフォルト値 (「、。」) を採用
        let config: Config = toml::from_str("[search]\n").unwrap();
        assert_eq!(config.punctuation_style, PunctuationStyle::TenMaru);
    }

    #[test]
    fn test_punctuation_style_invalid_rejected() {
        // 4 variant 以外の文字列は deserialize 時点で reject される（型ガード）
        let toml_str = "punctuation_style = \"invalid\"\n";
        let result: Result<Config, _> = toml::from_str(toml_str);
        assert!(result.is_err(), "invalid punctuation_style should fail to parse");
    }

    #[test]
    fn test_app_entry_command_fallback() {
        let entry = AppEntry {
            key: Some("a".to_string()),
            process: "Code".to_string(),
            command: None,
        };
        // command() falls back to process name when command is None
        assert_eq!(entry.command(), Some("Code"));
        assert_eq!(entry.process(), "Code");

        // When command is explicitly set, it takes priority
        let entry2 = AppEntry {
            key: Some("a".to_string()),
            process: "Code".to_string(),
            command: Some("code".to_string()),
        };
        assert_eq!(entry2.command(), Some("code"));
    }

    /// `resolve_alongside_exe` がワークスペースルート `bin/` 配下のファイルを
    /// 見つけられることを検証する（`manifest_dir/../bin/<name>` の探索順序）。
    #[test]
    fn test_resolve_alongside_exe_finds_file_in_manifest_bin_dir() {
        let workspace_root = unique_temp_dir("found");
        let bin_dir = workspace_root.join("bin");
        std::fs::create_dir_all(&bin_dir).unwrap();
        let file_name = "resolve-test-target.txt";
        let target = bin_dir.join(file_name);
        std::fs::write(&target, b"test").unwrap();

        // manifest_dir はワークスペースルート直下の架空クレートディレクトリを模す
        let manifest_dir = workspace_root.join("some-crate");
        let resolved = resolve_alongside_exe(file_name, manifest_dir.to_str().unwrap());
        assert_eq!(resolved, Some(target));

        let _ = std::fs::remove_dir_all(&workspace_root);
    }

    /// exe と同じディレクトリにも `manifest_dir/../bin/` にも見つからない場合は
    /// `None` を返すことを検証する。
    #[test]
    fn test_resolve_alongside_exe_returns_none_when_not_found() {
        let workspace_root = unique_temp_dir("missing");
        // bin/ ディレクトリ自体を作らない = 見つからないケース
        let manifest_dir = workspace_root.join("some-crate");

        let resolved = resolve_alongside_exe("does-not-exist.bin", manifest_dir.to_str().unwrap());
        assert_eq!(resolved, None);
    }

    /// テスト間で衝突しない一時ディレクトリパスを生成する（未作成。呼び出し側で mkdir する）。
    fn unique_temp_dir(label: &str) -> PathBuf {
        let nanos = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap()
            .as_nanos();
        std::env::temp_dir().join(format!(
            "muhenkan-switch-config-test-{}-{}-{}",
            label,
            std::process::id(),
            nanos
        ))
    }
}
