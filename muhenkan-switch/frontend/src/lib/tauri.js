// ── Tauri API facade (Phase 2: `@tauri-apps/api` + plugins, no global) ──
// Phase 1 では Tauri グローバルを本ファイルへ集約しただけだったが、
// Phase 2 で `@tauri-apps/api` を npm 経由 import し、`withGlobalTauri: false`
// でグローバル汚染を完全排除した。本ファイルが Tauri runtime への唯一の窓口。
// Phase 3 で `.ts` 化し `invoke<T>(...)` の型ファサードに発展させる予定。

import { invoke } from "@tauri-apps/api/core";
import { listen } from "@tauri-apps/api/event";
import { getCurrentWindow } from "@tauri-apps/api/window";
import { open as shellOpen } from "@tauri-apps/plugin-shell";
import { message, ask } from "@tauri-apps/plugin-dialog";

export { invoke, listen, getCurrentWindow, shellOpen, message, ask };
