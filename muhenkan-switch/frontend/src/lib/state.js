// ── Shared mutable state across form modules ──
// 元 main.js の `let config`, `guiSettings`, `APP_PRESETS`, `SEARCH_PRESETS` 相当。
// ESM の `let` 直 export は import 側で再代入できないので、
// getter / setter 関数経由でアクセスする (振る舞いは元コードと同一)。

let config = null; // Current config from backend
let guiSettings = {}; // GUI-only settings
let APP_PRESETS = {};
let SEARCH_PRESETS = {};

export function getConfig() {
  return config;
}

export function setConfig(next) {
  config = next;
}

export function getGuiSettings() {
  return guiSettings;
}

export function setGuiSettings(next) {
  guiSettings = next;
}

export function getAppPresets() {
  return APP_PRESETS;
}

export function setAppPresets(next) {
  APP_PRESETS = next;
}

export function getSearchPresets() {
  return SEARCH_PRESETS;
}

export function setSearchPresets(next) {
  SEARCH_PRESETS = next;
}

// ── Available dispatch keys (must match kbd file) ──
export const DISPATCH_KEYS = [
  "1", "2", "3", "4", "5",
  "q", "w", "e", "r", "t",
  "a", "s", "d", "f", "g",
  "z", "b",
];
