// ── Tauri global APIs (Phase 1: keep `window.__TAURI__.*` access) ──
// Phase 2 で `@tauri-apps/api` に置換予定。本ファイルがその時の差し替えポイントになる。

const { invoke } = window.__TAURI__.core;
const { listen } = window.__TAURI__.event;
const { message, ask } = window.__TAURI__.dialog;

export { invoke, listen, message, ask };

// `shell.open` / `window.getCurrentWindow()` は使用箇所が限定的なので
// 都度 `window.__TAURI__.shell` / `window.__TAURI__.window` を呼び出す
// (元 main.js と同じ振る舞い)。
