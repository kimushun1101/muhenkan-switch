// ── muhenkan-switch frontend entrypoint ──
// Vanilla JS + ESM. Tauri API は `lib/tauri.js` facade に集約 (Phase 2 で
// `@tauri-apps/api` 採用 + Tauri グローバル直叩きは廃止済み、`withGlobalTauri: false`)。
// Phase 3 で `lib/tauri.js` を `.ts` 化し型ファサードに発展予定。

import { invoke } from "./lib/tauri.js";
import { initTabs } from "./lib/tabs.js";
import { initShortcuts } from "./lib/shortcuts.js";
import { loadConfig, renderConfig, initConfigActions } from "./lib/config-io.js";
import { initTimestampForm } from "./forms/timestamp.js";
import { initSearchForm } from "./forms/search.js";
import { initFoldersForm } from "./forms/folders.js";
import { initAppsForm } from "./forms/apps.js";
import {
  initGeneralForm, refreshKanataStatus, loadAutostart, initUpdater,
} from "./forms/general.js";

// ── Initialize ──
async function init() {
  // 入力イベントリスナを先に張る (loadConfig が DOM を更新するため順序は重要)
  initTabs();
  initTimestampForm();
  initSearchForm();
  initFoldersForm();
  initAppsForm();
  initGeneralForm({ renderConfig });
  initConfigActions();
  initShortcuts();

  await loadConfig();
  await refreshKanataStatus();
  await loadAutostart();

  // フッターにバージョン表示
  try {
    document.getElementById("footer-version").textContent = "v" + await invoke("get_app_version");
  } catch (e) {
    console.error("バージョン情報の取得に失敗:", e);
  }

  // インストーラー版のみ自動更新チェック
  await initUpdater();
}

init();
