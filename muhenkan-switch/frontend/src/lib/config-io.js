// ── Config load / render / collect / apply / reset / defaults ──
import { invoke, message, ask } from "./tauri.js";
import {
  getConfig, setConfig,
  setAppPresets, setSearchPresets,
} from "./state.js";
import { validateDispatchKeys } from "./dispatch-key.js";
import {
  renderTimestamp, getTimestampFormat, getTimestampDelimiter,
} from "../forms/timestamp.js";
import { renderSearchList } from "../forms/search.js";
import { renderFoldersList } from "../forms/folders.js";
import { renderAppsList } from "../forms/apps.js";

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

  // Punctuation style
  document.getElementById("punctuation-style").value = config.punctuation_style || "、。";

  // Timestamp
  renderTimestamp();

  // Search engines
  renderSearchList();

  // Folders
  renderFoldersList();

  // Apps
  renderAppsList();
}

// ── Collect config from UI ──
export function collectConfig() {
  const collected = {
    search: {},
    folders: {},
    apps: {},
    timestamp: {
      format: getTimestampFormat(),
      position: document.querySelector('input[name="ts-position"]:checked').value,
      delimiter: getTimestampDelimiter(),
    },
    punctuation_style: document.getElementById("punctuation-style").value || "、。",
  };

  // Search
  for (const row of document.querySelectorAll("#search-list .list-row")) {
    const name = row.querySelector(".key-input").value.trim();
    const url = row.querySelector(".url-input").value.trim();
    const dispatchKey = row.querySelector(".dispatch-key-select").value;
    if (name && url) {
      const entry = { url };
      if (dispatchKey) entry.key = dispatchKey;
      collected.search[name] = entry;
    }
  }

  // Folders
  for (const row of document.querySelectorAll("#folders-list .list-row")) {
    const name = row.querySelector(".key-input").value.trim();
    const path = row.querySelector(".path-input").value.trim();
    const dispatchKey = row.querySelector(".dispatch-key-select").value;
    if (name) {
      const entry = { path };
      if (dispatchKey) entry.key = dispatchKey;
      collected.folders[name] = entry;
    }
  }

  // Apps — 機能名の重複を防ぐ（IndexMap のキー重複で上書きされるのを回避）
  for (const row of document.querySelectorAll("#apps-list .list-row")) {
    let name = row.querySelector(".key-input").value.trim();
    const appSelect = row.querySelector(".app-select");
    const process = appSelect.value;
    const selectedOpt = appSelect.options[appSelect.selectedIndex];
    const command = selectedOpt?.dataset?.command || "";
    const dispatchKey = row.querySelector(".dispatch-key-select").value;
    if (name && process) {
      if (collected.apps[name]) {
        const appLabel = selectedOpt?.textContent || process;
        name = `${name} (${appLabel})`;
      }
      const entry = { process };
      if (dispatchKey) entry.key = dispatchKey;
      if (command) entry.command = command;
      collected.apps[name] = entry;
    }
  }

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
