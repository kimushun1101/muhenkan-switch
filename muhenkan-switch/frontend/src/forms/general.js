// ── General tab: autostart / export-import / help / github / open-dir / quit / kanata status / updater ──
import { invoke, listen, message, ask, shellOpen } from "../lib/tauri.js";
import { setConfig } from "../lib/state.js";

// ── Kanata status ──
export async function refreshKanataStatus() {
  try {
    const status = await invoke("get_kanata_status");
    updateKanataUI(status.running);
  } catch (e) {
    updateKanataUI(false);
  }
}

function updateKanataUI(running) {
  // Footer
  const footerDot = document.getElementById("footer-kanata-dot");
  const footerText = document.getElementById("footer-kanata-text");
  if (footerDot) footerDot.classList.toggle("running", running);
  if (footerText) footerText.textContent = running ? "キー割当: 実行中" : "キー割当: 停止中";
}

// ── Autostart checkbox ──
export async function loadAutostart() {
  const autostartCheckbox = document.getElementById("opt-autostart");
  try {
    autostartCheckbox.checked = await invoke("get_autostart_enabled");
  } catch (e) {
    console.error("自動起動状態の取得に失敗:", e);
  }
}

// ── Updater ──
async function checkForUpdate(silent = true) {
  try {
    const currentVersion = await invoke("get_app_version");
    const update = await invoke("check_update");
    if (update) {
      if (await ask(`現在: v${currentVersion} → 最新: v${update.version}\nアップデートしますか？`, { title: "アップデート" })) {
        await invoke("stop_kanata");
        await invoke("install_update");
      }
    } else if (!silent) {
      await message(`v${currentVersion} は最新です。`, { title: "アップデート" });
    }
  } catch (e) {
    console.error("[updater]", e);
    if (!silent) await message("アップデート確認に失敗しました:\n" + e, { title: "エラー", kind: "error" });
  }
}

export function initGeneralForm({ renderConfig }) {
  // ── Config export / import ──
  document.getElementById("btn-export-config").addEventListener("click", async () => {
    try {
      const exported = await invoke("export_config");
      if (exported) {
        await message("設定ファイルをエクスポートしました。", { title: "エクスポート" });
      }
    } catch (e) {
      await message("エクスポートに失敗しました:\n" + e, { title: "エラー", kind: "error" });
    }
  });

  document.getElementById("btn-import-config").addEventListener("click", async () => {
    const ok = await ask("現在の設定を上書きします。よろしいですか？", { title: "インポート", kind: "warning" });
    if (!ok) return;
    try {
      const newConfig = await invoke("import_config");
      if (newConfig) {
        setConfig(newConfig);
        renderConfig();
        await message("設定ファイルをインポートしました。", { title: "インポート" });
      }
    } catch (e) {
      await message("インポートに失敗しました:\n" + e, { title: "エラー", kind: "error" });
    }
  });

  // ── General tab: help / install dir / quit ──
  document.getElementById("btn-help").addEventListener("click", async () => {
    try {
      await invoke("open_help_window");
    } catch (e) {
      console.error("ヘルプウィンドウの表示に失敗:", e);
    }
  });

  document.getElementById("btn-github").addEventListener("click", async () => {
    await shellOpen("https://github.com/kimushun1101/muhenkan-switch");
  });

  document.getElementById("btn-open-dir").addEventListener("click", async () => {
    try {
      await invoke("open_install_dir");
    } catch (e) {
      await message("インストール先を開けませんでした:\n" + e, { title: "エラー", kind: "error" });
    }
  });

  document.getElementById("btn-quit").addEventListener("click", async () => {
    await invoke("quit_app");
  });

  // ── Autostart checkbox listener ──
  const autostartCheckbox = document.getElementById("opt-autostart");
  autostartCheckbox.addEventListener("change", async () => {
    try {
      await invoke("set_autostart_enabled", { enabled: autostartCheckbox.checked });
    } catch (e) {
      console.error("自動起動の切り替えに失敗:", e);
      autostartCheckbox.checked = !autostartCheckbox.checked;
    }
  });

  // ── Kanata status event ──
  listen("kanata-status-changed", (event) => {
    updateKanataUI(event.payload);
  });
}

// ── Updater initialization (called from main init after install type check) ──
export async function initUpdater() {
  // インストーラー版のみ自動更新チェック
  const installType = await invoke("get_install_type");
  if (installType === "installer") {
    // 起動 5 秒後にサイレントチェック
    setTimeout(() => checkForUpdate(true), 5000);

    // トレイメニューからの手動チェック
    listen("check-update-requested", () => checkForUpdate(false));
  }
}
