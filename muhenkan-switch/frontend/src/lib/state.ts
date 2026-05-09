// ── Shared mutable state across form modules ──
// 元 main.js の `let config`, `APP_PRESETS`, `SEARCH_PRESETS` 相当。
// ESM の `let` 直 export は import 側で再代入できないので、
// getter / setter 関数経由でアクセスする (振る舞いは元コードと同一)。

import type { Config } from "./config";

/** App プリセット 1 件 (config/app-presets.json の各エントリ) */
export interface AppPreset {
  label: string;
  process: string;
  command: string;
}

/** Search プリセット 1 件 (config/search-presets.json の各エントリ) */
export interface SearchPreset {
  label: string;
  url: string;
}

/** category 名 → エントリ配列 のマップ */
export type AppPresetMap = Record<string, AppPreset[]>;
export type SearchPresetMap = Record<string, SearchPreset[]>;

let config: Config | null = null; // Current config from backend
let APP_PRESETS: AppPresetMap = {};
let SEARCH_PRESETS: SearchPresetMap = {};

export function getConfig(): Config | null {
  return config;
}

export function setConfig(next: Config): void {
  config = next;
}

export function getAppPresets(): AppPresetMap {
  return APP_PRESETS;
}

export function setAppPresets(next: AppPresetMap): void {
  APP_PRESETS = next;
}

export function getSearchPresets(): SearchPresetMap {
  return SEARCH_PRESETS;
}

export function setSearchPresets(next: SearchPresetMap): void {
  SEARCH_PRESETS = next;
}

// ── Available dispatch keys (must match kbd file) ──
export const DISPATCH_KEYS: readonly string[] = [
  "1", "2", "3", "4", "5",
  "q", "w", "e", "r", "t",
  "a", "s", "d", "f", "g",
  "z", "b",
];
