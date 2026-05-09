// ── muhenkan-switch frontend entrypoint ──
// Vanilla TS + ESM. Tauri API は `lib/tauri.ts` facade に集約 (Phase 2 で
// `@tauri-apps/api` 採用 + Tauri グローバル直叩きは廃止済み、`withGlobalTauri: false`)。
// Phase 3-B で全 .js を .ts 化し strict 設定で typecheck を pass させた。

import { invoke } from './lib/tauri';
import { initTabs } from './lib/tabs';
import { initShortcuts } from './lib/shortcuts';
import { loadConfig, renderConfig, initConfigActions, initConfigIo } from './lib/config-io';
import { initTimestampForm, renderTimestamp, collectTimestamp } from './forms/timestamp';
import { initSearchForm, renderSearchList, collectSearch } from './forms/search';
import { initFoldersForm, renderFoldersList, collectFolders } from './forms/folders';
import { initAppsForm, renderAppsList, collectApps } from './forms/apps';
import { initGeneralForm, refreshKanataStatus, loadAutostart, initUpdater } from './forms/general';

// ── Initialize ──
async function init(): Promise<void> {
  // 入力イベントリスナを先に張る (loadConfig が DOM を更新するため順序は重要)
  initTabs();
  initTimestampForm();
  initSearchForm();
  initFoldersForm();
  initAppsForm();
  initGeneralForm({ renderConfig });
  // forms/* の render/collect を config-io に注入 (Issue #140 で依存方向を逆転)
  // 順序は元の renderConfig() / collectConfig() の呼び出し順を保つこと
  initConfigIo({
    renderers: [renderTimestamp, renderSearchList, renderFoldersList, renderAppsList],
    collectors: [collectTimestamp, collectSearch, collectFolders, collectApps],
  });
  initConfigActions();
  initShortcuts();

  await loadConfig();
  await refreshKanataStatus();
  await loadAutostart();

  // フッターにバージョン表示
  try {
    const version = await invoke<string>('get_app_version');
    const footerVersion = document.getElementById('footer-version');
    if (footerVersion) footerVersion.textContent = 'v' + version;
  } catch (e) {
    console.error('バージョン情報の取得に失敗:', e);
  }

  // インストーラー版のみ自動更新チェック
  await initUpdater();
}

void init();
