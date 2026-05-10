// Tauri command の引数/戻り値型 (IPC 型)。
// Rust 側 `muhenkan-switch/src/commands.rs` の対応 struct と手動同期する。
// ts-rs は Tauri command シグネチャを生成できないため、tauri-specta v2 stable 化までは手作業集約で運用 (Issue #135 / #176)。

/** Tauri 側 `KanataStatus` (commands.rs) と対応 */
export interface KanataStatus {
  running: boolean;
  pid: number | null;
}

/** Tauri 側 `UpdateInfo` (commands.rs) と対応 */
export interface UpdateInfo {
  version: string;
  body: string | null;
}

/** Tauri 側 `ProcessInfo` (commands.rs) と対応 */
export interface ProcessInfo {
  name: string;
  pid: number;
}
