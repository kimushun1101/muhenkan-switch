use anyhow::{Context, Result};
use indexmap::IndexMap;
use serde::{Deserialize, Serialize};
use std::path::PathBuf;

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

#[derive(Debug, Deserialize, Serialize, Clone)]
pub struct SearchEntry {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub key: Option<String>,
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

#[derive(Debug, Deserialize, Serialize, Clone)]
pub struct FolderEntry {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub key: Option<String>,
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

#[derive(Debug, Deserialize, Serialize, Clone)]
pub struct AppEntry {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub key: Option<String>,
    pub process: String,
    #[serde(skip_serializing_if = "Option::is_none")]
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

#[derive(Debug, Deserialize, Serialize, Clone)]
pub struct Config {
    #[serde(default)]
    pub search: IndexMap<String, SearchEntry>,
    #[serde(default)]
    pub folders: IndexMap<String, FolderEntry>,
    #[serde(default)]
    pub apps: IndexMap<String, AppEntry>,
    #[serde(default)]
    pub timestamp: TimestampConfig,
    #[serde(default = "default_punctuation_style")]
    pub punctuation_style: String,
}

fn default_punctuation_style() -> String {
    "、。".to_string()
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

#[derive(Debug, Deserialize, Serialize, Clone)]
pub struct TimestampConfig {
    #[serde(default = "default_format")]
    pub format: String,
    #[serde(default = "default_position")]
    pub position: String,
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

// ── Config path resolution ──

/// config.toml のパスを決定する。
/// 優先順位:
/// 1. 実行ファイルと同じディレクトリの config.toml（インストール環境 / dev: ./bin/ 実行時）
/// 2. CARGO_MANIFEST_DIR/../bin/config.toml（開発環境: cargo run 互換）
/// 3. 見つからなければ None（default_config() の embedded config で補完）
pub fn config_path() -> Option<PathBuf> {
    // 1. 実行ファイルと同じディレクトリ
    if let Ok(exe_path) = std::env::current_exe() {
        if let Some(dir) = exe_path.parent() {
            let path = dir.join("config.toml");
            if path.exists() {
                return Some(path);
            }
        }
    }

    // 2. ワークスペースルートの bin/（開発環境）
    let bin_dir = PathBuf::from(env!("CARGO_MANIFEST_DIR"))
        .parent()
        .map(|p| p.join("bin"));
    if let Some(ref dir) = bin_dir {
        let path = dir.join("config.toml");
        if path.exists() {
            return Some(path);
        }
    }

    None
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
        punctuation_style: default_punctuation_style(),
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
    doc["punctuation_style"] = toml_edit::value(&config.punctuation_style);

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

    // punctuation_style の検証
    if !["、。", "，．", "，。", "、．"].contains(&config.punctuation_style.as_str()) {
        errors.push(format!(
            "punctuation_style は \"、。\", \"，．\", \"，。\", \"、．\" のいずれかを指定してください (現在: \"{}\")",
            config.punctuation_style
        ));
    }

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
pub fn rewrite_kbd_punctuation(kbd_path: &std::path::Path, style: &str) -> Result<()> {
    let content = std::fs::read_to_string(kbd_path)
        .with_context(|| format!("kbd ファイルの読み込みに失敗しました: {}", kbd_path.display()))?;

    let patterns = [
        "(unicode 、)  (unicode 。)",
        "(unicode ，)  (unicode ．)",
        "(unicode ，)  (unicode 。)",
        "(unicode 、)  (unicode ．)",
    ];
    let new_fragment = match style {
        "，．" => "(unicode ，)  (unicode ．)",
        "，。" => "(unicode ，)  (unicode 。)",
        "、．" => "(unicode 、)  (unicode ．)",
        _ => "(unicode 、)  (unicode 。)",
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
            punctuation_style: default_punctuation_style(),
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
}
