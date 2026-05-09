// ── Tauri API facade (Phase 3-A: `.ts` 化 + typed `invoke<T>`) ──
// Phase 1 で Tauri グローバルを本ファイルへ集約、
// Phase 2 で `@tauri-apps/api` を npm 経由 import (`withGlobalTauri: false`)。
// Phase 3-A で `.ts` 化し、`invoke<T>(...)` の戻り値型を呼び出し側で
// 受け取れる薄い wrapper に発展させる。

import { invoke as tauriInvoke } from "@tauri-apps/api/core";
import { listen } from "@tauri-apps/api/event";
import { getCurrentWindow } from "@tauri-apps/api/window";
import { open as shellOpen } from "@tauri-apps/plugin-shell";
import { message, ask } from "@tauri-apps/plugin-dialog";

/**
 * Tauri コマンドを呼び出す型付きファサード。
 * 戻り値の型 `T` を呼び出し側で指定可能 (例: `invoke<Config>("get_config")`)。
 * `args` は `Record<string, unknown>` 互換 — Tauri 側は plain object をそのまま
 * Rust 構造体へデシリアライズする。
 */
export function invoke<T>(cmd: string, args?: Record<string, unknown>): Promise<T> {
  return tauriInvoke<T>(cmd, args);
}

export { listen, getCurrentWindow, shellOpen, message, ask };
