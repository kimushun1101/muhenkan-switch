// ── Config load / render / collect / apply / reset / defaults ──
//
// 依存方向: lib/config-io.ts は forms/* を直接 import せず、
// `initConfigIo({ renderers, collectors })` で受け取った関数群へ fan-out する
// (Issue #140)。Phase 3 TS 化や Phase 4 単体テストでの差し替え/モックを
// しやすくする目的の純リファクタ。
import { invoke, message, ask } from './tauri';
import type { Config, TimestampConfig } from './config';
import { getConfig, setConfig, setAppPresets, setSearchPresets } from './state';
import type { AppPresetMap, SearchPresetMap } from './state';
import { validateDispatchKeys } from './dispatch-key';

/**
 * collectConfig() の途中で組み立てる中間表現。
 * timestamp は collectTimestamp が完全な値で上書きするため、初期化時点では
 * 空オブジェクト (`{} as TimestampConfig`) で開始する。最終的に Config と
 * 同形になる。
 */
export type CollectedConfig = Config;

export type Renderer = () => void;
export type Collector = (collected: CollectedConfig) => void;

export interface InitConfigIoOptions {
  renderers?: Renderer[];
  collectors?: Collector[];
}

// ── Renderer / collector registries (set via initConfigIo) ──
let renderers: Renderer[] = [];
let collectors: Collector[] = [];

export function initConfigIo({
  renderers: r = [],
  collectors: c = [],
}: InitConfigIoOptions = {}): void {
  renderers = r;
  collectors = c;
}

// ── Load config on startup ──
export async function loadConfig(): Promise<void> {
  try {
    const [config, appPresets, searchPresets] = await Promise.all([
      invoke<Config>('get_config'),
      invoke<AppPresetMap>('get_app_presets'),
      invoke<SearchPresetMap>('get_search_presets'),
    ]);
    setConfig(config);
    setAppPresets(appPresets);
    setSearchPresets(searchPresets);
    renderConfig();
  } catch (e) {
    console.error('設定の読み込みに失敗:', e);
  }
}

// ── Render config to UI ──
export function renderConfig(): void {
  const config = getConfig();
  if (!config) return;

  // Punctuation style (lib/config-io が直接保持する唯一の DOM 操作)
  const punc = document.getElementById('punctuation-style') as
    | HTMLInputElement
    | HTMLSelectElement
    | null;
  if (punc) punc.value = config.punctuation_style || '、。';

  // Fan out to per-form renderers (順序は main.ts の初期化順)
  for (const render of renderers) render();
}

// ── Collect config from UI ──
export function collectConfig(): CollectedConfig {
  const punc = document.getElementById('punctuation-style') as
    | HTMLInputElement
    | HTMLSelectElement
    | null;
  const collected: CollectedConfig = {
    search: {},
    folders: {},
    apps: {},
    // collectTimestamp が必須フィールドを埋める前提で空オブジェクトで開始
    timestamp: {} as TimestampConfig,
    // ts-rs で literal union に強化された型に合わせるためのキャスト。
    // 不正値は Rust 側の `validate()` で検出される。
    punctuation_style: (punc?.value || '、。') as Config['punctuation_style'],
  };

  // Fan out to per-form collectors
  for (const collect of collectors) collect(collected);

  return collected;
}

// ── Apply / Reset / Defaults ──
export function initConfigActions(): void {
  const btnApply = document.getElementById('btn-apply') as HTMLButtonElement | null;
  if (btnApply) {
    btnApply.addEventListener('click', async () => {
      try {
        // Client-side dispatch key validation
        const dupError = validateDispatchKeys();
        if (dupError) {
          await message(dupError, { title: 'エラー', kind: 'error' });
          return;
        }

        const newConfig = collectConfig();
        console.log('[apply] saving config:', JSON.stringify(newConfig).slice(0, 200));
        await invoke('save_config', { config: newConfig });
        setConfig(newConfig);

        // Brief save success indicator
        const orig = btnApply.textContent;
        btnApply.textContent = '保存しました';
        setTimeout(() => {
          btnApply.textContent = orig;
        }, 1500);
      } catch (e) {
        console.error('[apply] error:', e);
        await message('保存に失敗しました:\n' + String(e), { title: 'エラー', kind: 'error' });
      }
    });
  }

  const btnReset = document.getElementById('btn-reset') as HTMLButtonElement | null;
  if (btnReset) {
    btnReset.addEventListener('click', async () => {
      const yes = await ask('未保存の変更を破棄して、最後に保存した設定に戻しますか？', {
        title: 'リセット',
        kind: 'warning',
      });
      if (!yes) return;
      await loadConfig();
    });
  }

  const btnDefaults = document.getElementById('btn-defaults') as HTMLButtonElement | null;
  if (btnDefaults) {
    btnDefaults.addEventListener('click', async () => {
      const yes = await ask('現在の設定を破棄して、初期値に戻しますか？', {
        title: '初期値に戻す',
        kind: 'warning',
      });
      if (!yes) return;
      try {
        const next = await invoke<Config>('default_config');
        setConfig(next);
        renderConfig();
      } catch (e) {
        console.error('初期値の取得に失敗:', e);
      }
    });
  }
}
