// ── Config types (Phase 3-A: 手書き TS interface) ──
//
// Rust 側 `muhenkan-switch-config/src/lib.rs` の `Config` 系構造体に 1:1 対応。
// 整合性は **手動チェック** で維持する (将来的には ts-rs での自動生成を検討、
// Issue #147)。
//
// シリアライズ規約:
// - `IndexMap<String, T>` は serde で TOML/JSON のテーブルにシリアライズされ、
//   フロント側では `Record<string, T>` として受け取る。
// - `Option<T>` + `#[serde(skip_serializing_if = "Option::is_none")]` フィールドは
//   保存時に省略され、読み込み時には未定義になり得るため `?:` で表現する。
// - `#[serde(default)]` のフィールドは「未指定なら Rust 側がデフォルト値で埋める」
//   ため TS 側でも一旦必須として扱う (バックエンド経由でのみ来る前提)。

/** [search] エントリ。Rust: `SearchEntry` */
export interface SearchEntry {
  /** 割当キー (省略可。dispatch_key を持たない検索エンジンもある) */
  key?: string;
  /** 検索 URL テンプレート。`{query}` プレースホルダを含む */
  url: string;
}

/** [folders] エントリ。Rust: `FolderEntry` */
export interface FolderEntry {
  /** 割当キー (省略可) */
  key?: string;
  /** フォルダパス */
  path: string;
}

/** [apps] エントリ。Rust: `AppEntry` */
export interface AppEntry {
  /** 割当キー (省略可) */
  key?: string;
  /** ウィンドウ判定に使うプロセス名 */
  process: string;
  /** 起動コマンド (省略時はバックエンドが `process` をフォールバック) */
  command?: string;
}

/** [timestamp] セクション。Rust: `TimestampConfig` */
export interface TimestampConfig {
  /** strftime フォーマット (例: "%Y%m%d") */
  format: string;
  /** "before" | "after" */
  position: string;
  /** 区切り文字 (空文字 = 区切りなし) */
  delimiter: string;
}

/** ルート設定。Rust: `Config` */
export interface Config {
  /** 検索エンジン定義 (key = エントリ名) */
  search: Record<string, SearchEntry>;
  /** フォルダ定義 (key = エントリ名) */
  folders: Record<string, FolderEntry>;
  /** アプリ定義 (key = エントリ名) */
  apps: Record<string, AppEntry>;
  /** タイムスタンプ設定 */
  timestamp: TimestampConfig;
  /** 句読点スタイル ("、。" | "，．" | "，。" | "、．") */
  punctuation_style: string;
}
