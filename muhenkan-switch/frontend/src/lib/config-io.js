// ── Config load / render / collect / apply / reset / defaults ──
//
// 依存方向: lib/config-io.js は forms/* を直接 import せず、
// `initConfigIo({ renderers, collectors })` で受け取った関数群へ fan-out する
// (Issue #140)。Phase 3 TS 化や Phase 4 単体テストでの差し替え/モックを
// しやすくする目的の純リファクタ。
import { invoke, message, ask } from "./tauri";
import {
  getConfig, setConfig,
  setAppPresets, setSearchPresets,
} from "./state.js";
import { validateDispatchKeys } from "./dispatch-key.js";

// ── Renderer / collector registries (set via initConfigIo) ──
let renderers = [];
let collectors = [];

export function initConfigIo({ renderers: r = [], collectors: c = [] } = {}) {
  renderers = r;
  collectors = c;
}

// ── Load config on startup ──
export async function loadConfig() {
  try {
    const [config, appPresets, searchPresets] = await Promise.all([
      invoke("get_config"),
      invoke("get_app_presets"),
      invoke("get_search_presets"),
    ]);
    setConfig(config);
    setAppPresets(appPresets);
    setSearchPresets(searchPresets);
    renderConfig();
  } catch (e) {
    console.error("設定の読み込みに失敗:", e);
  }
}

// ── Render config to UI ──
export function renderConfig() {
  const config = getConfig();
  if (!config) return;

  // Punctuation style (lib/config-io が直接保持する唯一の DOM 操作)
  document.getElementById("punctuation-style").value = config.punctuation_style || "、。";

  // Fan out to per-form renderers (順序は main.js の初期化順)
  for (const render of renderers) render();
}

// ── Collect config from UI ──
export function collectConfig() {
  const collected = {
    search: {},
    folders: {},
    apps: {},
    timestamp: {},
    punctuation_style: document.getElementById("punctuation-style").value || "、。",
  };

  // Fan out to per-form collectors
  for (const collect of collectors) collect(collected);

  return collected;
}

// ── Apply / Reset / Defaults ──
export function initConfigActions() {
  document.getElementById("btn-apply").addEventListener("click", async () => {
    try {
      // Client-side dispatch key validation
      const dupError = validateDispatchKeys();
      if (dupError) {
        await message(dupError, { title: "エラー", kind: "error" });
        return;
      }

      const newConfig = collectConfig();
      console.log("[apply] saving config:", JSON.stringify(newConfig).slice(0, 200));
      await invoke("save_config", { config: newConfig });
      setConfig(newConfig);

      // Brief save success indicator
      const btn = document.getElementById("btn-apply");
      const orig = btn.textContent;
      btn.textContent = "保存しました";
      setTimeout(() => { btn.textContent = orig; }, 1500);
    } catch (e) {
      console.error("[apply] error:", e);
      await message("保存に失敗しました:\n" + e, { title: "エラー", kind: "error" });
    }
  });

  document.getElementById("btn-reset").addEventListener("click", async () => {
    const yes = await ask("未保存の変更を破棄して、最後に保存した設定に戻しますか？", { title: "リセット", kind: "warning" });
    if (!yes) return;
    await loadConfig();
  });

  document.getElementById("btn-defaults").addEventListener("click", async () => {
    const yes = await ask("現在の設定を破棄して、初期値に戻しますか？", { title: "初期値に戻す", kind: "warning" });
    if (!yes) return;
    try {
      const next = await invoke("default_config");
      setConfig(next);
      renderConfig();
    } catch (e) {
      console.error("初期値の取得に失敗:", e);
    }
  });
}
