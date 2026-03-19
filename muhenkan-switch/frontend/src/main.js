const { invoke } = window.__TAURI__.core;
const { listen } = window.__TAURI__.event;
const { message, ask } = window.__TAURI__.dialog;

// ── State ──
let config = null;       // Current config from backend
let guiSettings = {};    // GUI-only settings

// ── Available dispatch keys (must match kbd file) ──
const DISPATCH_KEYS = [
  "1", "2", "3", "4", "5",
  "q", "w", "e", "r", "t",
  "a", "s", "d", "f", "g",
  "z", "b",
];

// ── App presets (OS-aware) ──
function detectOS() {
  const ua = navigator.userAgent;
  if (ua.includes("Win")) return "windows";
  if (ua.includes("Mac")) return "macos";
  return "linux";
}

const APP_PRESETS = (() => {
  const os = detectOS();
  if (os === "windows") {
    return {
      "エディタ": [
        { label: "VS Code", process: "Code", command: "code" },
        { label: "Cursor", process: "Cursor", command: "cursor" },
        { label: "Zed", process: "Zed", command: "zed" },
      ],
      "ブラウザ": [
        { label: "Edge", process: "msedge", command: "msedge" },
        { label: "Chrome", process: "chrome", command: "chrome" },
        { label: "Firefox", process: "firefox", command: "firefox" },
        { label: "Zen", process: "zen", command: "zen" },
      ],
      "ドキュメント": [
        { label: "OneNote", process: "OneNote", command: "onenote" },
        { label: "Obsidian", process: "Obsidian", command: "obsidian" },
        { label: "Notion", process: "Notion", command: "notion" },
        { label: "Word", process: "WINWORD", command: "winword" },
      ],
      "チャット": [
        { label: "Slack", process: "slack", command: "slack" },
        { label: "Discord", process: "Discord", command: "discord" },
        { label: "Teams", process: "ms-teams", command: "ms-teams" },
      ],
      "ターミナル": [
        { label: "Windows Terminal", process: "WindowsTerminal", command: "wt" },
        { label: "Alacritty", process: "alacritty", command: "alacritty" },
      ],
    };
  } else if (os === "macos") {
    return {
      "エディタ": [
        { label: "VS Code", process: "Visual Studio Code", command: "code" },
        { label: "Cursor", process: "Cursor", command: "open -a Cursor" },
        { label: "Zed", process: "Zed", command: "open -a Zed" },
      ],
      "ブラウザ": [
        { label: "Safari", process: "Safari", command: "open -a Safari" },
        { label: "Chrome", process: "Google Chrome", command: "open -a 'Google Chrome'" },
        { label: "Firefox", process: "firefox", command: "open -a Firefox" },
        { label: "Zen", process: "zen", command: "open -a 'Zen Browser'" },
      ],
      "ドキュメント": [
        { label: "OneNote", process: "Microsoft OneNote", command: "open -a 'Microsoft OneNote'" },
        { label: "Obsidian", process: "Obsidian", command: "open -a Obsidian" },
        { label: "Notion", process: "Notion", command: "open -a Notion" },
        { label: "Word", process: "Microsoft Word", command: "open -a 'Microsoft Word'" },
      ],
      "チャット": [
        { label: "Slack", process: "Slack", command: "open -a Slack" },
        { label: "Discord", process: "Discord", command: "open -a Discord" },
        { label: "Teams", process: "Microsoft Teams", command: "open -a 'Microsoft Teams'" },
      ],
      "ターミナル": [
        { label: "Terminal", process: "Terminal", command: "open -a Terminal" },
        { label: "iTerm2", process: "iTerm2", command: "open -a iTerm" },
        { label: "Alacritty", process: "alacritty", command: "open -a Alacritty" },
      ],
    };
  } else {
    return {
      "エディタ": [
        { label: "VS Code", process: "code", command: "code" },
        { label: "Cursor", process: "cursor", command: "cursor" },
        { label: "Zed", process: "zed", command: "zed" },
      ],
      "ブラウザ": [
        { label: "Firefox", process: "firefox", command: "firefox" },
        { label: "Chrome", process: "google-chrome", command: "google-chrome" },
        { label: "Zen", process: "zen", command: "zen" },
      ],
      "ドキュメント": [
        { label: "OneNote", process: "onenote", command: "onenote" },
        { label: "Obsidian", process: "obsidian", command: "obsidian" },
        { label: "Notion", process: "Notion", command: "notion-app" },
        { label: "LibreOffice Writer", process: "soffice", command: "libreoffice --writer" },
      ],
      "チャット": [
        { label: "Slack", process: "Slack", command: "slack" },
        { label: "Discord", process: "Discord", command: "discord" },
      ],
      "ターミナル": [
        { label: "GNOME Terminal", process: "gnome-terminal", command: "gnome-terminal" },
        { label: "Alacritty", process: "alacritty", command: "alacritty" },
        { label: "Kitty", process: "kitty", command: "kitty" },
      ],
    };
  }
})();

// ── App select dropdown helper ──
function createAppSelect(currentProcess = "", currentCommand = "") {
  const select = document.createElement("select");
  select.className = "app-select";

  const noneOpt = document.createElement("option");
  noneOpt.value = "";
  noneOpt.textContent = "—";
  select.appendChild(noneOpt);

  let hasCurrentProcess = !currentProcess;

  for (const [category, apps] of Object.entries(APP_PRESETS)) {
    const group = document.createElement("optgroup");
    group.label = category;
    for (const app of apps) {
      const opt = document.createElement("option");
      opt.value = app.process;
      opt.textContent = app.label;
      opt.dataset.command = app.command;
      group.appendChild(opt);
      if (app.process === currentProcess) hasCurrentProcess = true;
    }
    select.appendChild(group);
  }

  if (currentProcess && !hasCurrentProcess) {
    const opt = document.createElement("option");
    opt.value = currentProcess;
    opt.textContent = `${currentProcess}（カスタム）`;
    opt.dataset.command = currentCommand || currentProcess.toLowerCase();
    select.appendChild(opt);
  }

  select.value = currentProcess || "";
  return select;
}

// ── Tab switching ──
document.querySelectorAll(".tab").forEach((tab) => {
  tab.addEventListener("click", () => {
    document.querySelectorAll(".tab").forEach((t) => t.classList.remove("active"));
    document.querySelectorAll(".panel").forEach((p) => p.classList.remove("active"));
    tab.classList.add("active");
    document.getElementById(`panel-${tab.dataset.tab}`).classList.add("active");
  });
});

// ── Load config on startup ──
async function loadConfig() {
  try {
    config = await invoke("get_config");
    renderConfig();
  } catch (e) {
    console.error("設定の読み込みに失敗:", e);
  }
}

// ── Render config to UI ──
function renderConfig() {
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

// ── Timestamp ──
function renderTimestamp() {
  // Format
  const formatPreset = document.getElementById("ts-format-preset");
  const formatCustom = document.getElementById("ts-format-custom");
  const format = config.timestamp.format;

  const formatOption = Array.from(formatPreset.options).find((o) => o.value === format);
  if (formatOption) {
    formatPreset.value = format;
    formatCustom.classList.add("hidden");
  } else {
    formatPreset.value = "custom";
    formatCustom.value = format;
    formatCustom.classList.remove("hidden");
  }

  // Delimiter
  const delimPreset = document.getElementById("ts-delimiter-preset");
  const delimCustom = document.getElementById("ts-delimiter-custom");
  const delimiter = config.timestamp.delimiter ?? "_";

  const delimOption = Array.from(delimPreset.options).find((o) => o.value === delimiter);
  if (delimOption) {
    delimPreset.value = delimiter;
    delimCustom.classList.add("hidden");
  } else {
    delimPreset.value = "custom";
    delimCustom.value = delimiter;
    delimCustom.classList.remove("hidden");
  }

  // Position
  document.querySelector(`input[name="ts-position"][value="${config.timestamp.position}"]`).checked = true;

  updateTimestampPreview();
}

function getTimestampFormat() {
  const preset = document.getElementById("ts-format-preset").value;
  if (preset === "custom") {
    return document.getElementById("ts-format-custom").value;
  }
  return preset;
}

function getTimestampDelimiter() {
  const preset = document.getElementById("ts-delimiter-preset").value;
  if (preset === "custom") {
    return document.getElementById("ts-delimiter-custom").value;
  }
  return preset;
}

async function updateTimestampPreview() {
  const format = getTimestampFormat();
  const delimiter = getTimestampDelimiter();
  const position = document.querySelector('input[name="ts-position"]:checked').value;
  try {
    const preview = await invoke("validate_timestamp_format", { format, delimiter, position });
    document.getElementById("ts-preview").textContent = preview;
    document.getElementById("ts-preview").style.color = "";
  } catch (e) {
    document.getElementById("ts-preview").textContent = e;
    document.getElementById("ts-preview").style.color = "var(--red)";
  }
}

document.getElementById("ts-format-preset").addEventListener("change", (e) => {
  const customInput = document.getElementById("ts-format-custom");
  if (e.target.value === "custom") {
    customInput.classList.remove("hidden");
    customInput.focus();
  } else {
    customInput.classList.add("hidden");
  }
  updateTimestampPreview();
});

document.getElementById("ts-format-custom").addEventListener("input", () => {
  updateTimestampPreview();
});

document.getElementById("ts-delimiter-preset").addEventListener("change", (e) => {
  const customInput = document.getElementById("ts-delimiter-custom");
  if (e.target.value === "custom") {
    customInput.classList.remove("hidden");
    customInput.focus();
  } else {
    customInput.classList.add("hidden");
  }
  updateTimestampPreview();
});

document.getElementById("ts-delimiter-custom").addEventListener("input", () => {
  updateTimestampPreview();
});

document.querySelectorAll('input[name="ts-position"]').forEach((radio) => {
  radio.addEventListener("change", () => updateTimestampPreview());
});

// ── Dispatch key dropdown helper ──
function createDispatchKeySelect(selectedKey = "") {
  const select = document.createElement("select");
  select.className = "dispatch-key-select";
  select.title = "無変換+キー";

  const noneOpt = document.createElement("option");
  noneOpt.value = "";
  noneOpt.textContent = "—";
  select.appendChild(noneOpt);

  for (const k of DISPATCH_KEYS) {
    const opt = document.createElement("option");
    opt.value = k;
    opt.textContent = k.toUpperCase();
    select.appendChild(opt);
  }

  select.value = selectedKey || "";
  return select;
}

// ── Search engines ──
function renderSearchList() {
  const container = document.getElementById("search-list");
  container.innerHTML = "";
  for (const [name, entry] of Object.entries(config.search || {})) {
    addSearchRow(container, name, entry.url, entry.key || "");
  }
}

function addSearchRow(container, name = "", url = "", dispatchKey = "") {
  const row = document.createElement("div");
  row.className = "list-row";
  row.innerHTML = `
    <input type="text" class="key-input" placeholder="キー" value="${escapeHtml(name)}">
    <input type="text" placeholder="URL テンプレート ({query})" value="${escapeHtml(url)}">
    <button class="btn-remove" title="削除">&times;</button>
  `;
  // Insert dispatch key select before the first input
  const keySelect = createDispatchKeySelect(dispatchKey);
  row.insertBefore(keySelect, row.firstChild);
  row.querySelector(".btn-remove").addEventListener("click", () => row.remove());
  container.appendChild(row);
}

document.getElementById("btn-add-search").addEventListener("click", () => {
  addSearchRow(document.getElementById("search-list"));
});

// ── Folders ──
function renderFoldersList() {
  const container = document.getElementById("folders-list");
  container.innerHTML = "";
  for (const [name, entry] of Object.entries(config.folders || {})) {
    addFolderRow(container, name, entry.path, entry.key || "");
  }
}

function addFolderRow(container, name = "", path = "", dispatchKey = "") {
  const row = document.createElement("div");
  row.className = "list-row";
  row.innerHTML = `
    <input type="text" class="key-input" placeholder="キー" value="${escapeHtml(name)}">
    <input type="text" class="path-input" placeholder="パス (~/Documents)" value="${escapeHtml(path)}">
    <button class="btn-browse" title="参照">参照</button>
    <button class="btn-remove" title="削除">&times;</button>
  `;
  const keySelect = createDispatchKeySelect(dispatchKey);
  row.insertBefore(keySelect, row.firstChild);
  row.querySelector(".btn-remove").addEventListener("click", () => row.remove());
  row.querySelector(".btn-browse").addEventListener("click", async () => {
    try {
      const selected = await invoke("browse_folder");
      if (selected) {
        row.querySelector(".path-input").value = selected;
      }
    } catch (e) {
      console.error("フォルダ選択に失敗:", e);
    }
  });
  container.appendChild(row);
}

document.getElementById("btn-add-folder").addEventListener("click", () => {
  addFolderRow(document.getElementById("folders-list"));
});

// ── Apps ──
function renderAppsList() {
  const container = document.getElementById("apps-list");
  container.innerHTML = "";
  for (const [name, entry] of Object.entries(config.apps || {})) {
    addAppRow(container, name, entry.process, entry.command || "", entry.key || "");
  }
}

function addAppRow(container, name = "", process = "", command = "", dispatchKey = "") {
  const row = document.createElement("div");
  row.className = "list-row";
  row.innerHTML = `
    <input type="text" class="key-input" placeholder="機能名" value="${escapeHtml(name)}">
    <button class="btn-pick-process" title="実行中のプロセスから選択">選択</button>
    <button class="btn-remove" title="削除">&times;</button>
  `;
  const keySelect = createDispatchKeySelect(dispatchKey);
  row.insertBefore(keySelect, row.firstChild);

  const appSelect = createAppSelect(process, command);
  const nameInput = row.querySelector(".key-input");
  nameInput.insertAdjacentElement("afterend", appSelect);

  row.querySelector(".btn-remove").addEventListener("click", () => row.remove());
  row.querySelector(".btn-pick-process").addEventListener("click", async () => {
    const selected = await showProcessPicker();
    if (selected) {
      let found = false;
      for (const opt of appSelect.options) {
        if (opt.value === selected) { found = true; break; }
      }
      if (!found) {
        const opt = document.createElement("option");
        opt.value = selected;
        opt.textContent = `${selected}（カスタム）`;
        opt.dataset.command = selected.toLowerCase();
        appSelect.appendChild(opt);
      }
      appSelect.value = selected;
    }
  });
  container.appendChild(row);
}

document.getElementById("btn-add-app").addEventListener("click", () => {
  addAppRow(document.getElementById("apps-list"));
});

// ── Process picker modal ──
async function showProcessPicker() {
  return new Promise(async (resolve) => {
    let processes = [];
    try {
      processes = await invoke("get_running_processes");
    } catch (e) {
      console.error("プロセス一覧の取得に失敗:", e);
      resolve(null);
      return;
    }

    const overlay = document.createElement("div");
    overlay.className = "modal-overlay";
    overlay.innerHTML = `
      <div class="modal">
        <div class="modal-header">プロセスを選択</div>
        <div class="modal-body">
          <input type="text" class="modal-search" placeholder="フィルター...">
          <ul class="modal-list"></ul>
        </div>
        <div class="modal-footer">
          <button class="btn-cancel">キャンセル</button>
        </div>
      </div>
    `;

    const list = overlay.querySelector(".modal-list");
    const searchInput = overlay.querySelector(".modal-search");

    function renderProcessList(filter = "") {
      list.innerHTML = "";
      const filtered = processes.filter((p) =>
        p.name.toLowerCase().includes(filter.toLowerCase())
      );
      for (const p of filtered) {
        const li = document.createElement("li");
        li.textContent = p.name;
        li.addEventListener("click", () => {
          // Remove .exe extension
          let name = p.name;
          if (name.toLowerCase().endsWith(".exe")) {
            name = name.slice(0, -4);
          }
          close(name);
        });
        list.appendChild(li);
      }
    }

    searchInput.addEventListener("input", (e) => {
      renderProcessList(e.target.value);
    });

    function close(result) {
      overlay.remove();
      document.removeEventListener("keydown", onKeydown);
      resolve(result);
    }

    overlay.querySelector(".btn-cancel").addEventListener("click", () => close(null));

    overlay.addEventListener("click", (e) => {
      if (e.target === overlay) close(null);
    });

    function onKeydown(e) {
      if (e.key === "Escape") close(null);
    }
    document.addEventListener("keydown", onKeydown);

    renderProcessList();
    document.body.appendChild(overlay);
    searchInput.focus();
  });
}

// ── Dispatch key duplicate validation ──
function validateDispatchKeys() {
  const usedKeys = {};
  for (const select of document.querySelectorAll(".dispatch-key-select")) {
    const key = select.value;
    if (!key) continue;
    if (usedKeys[key]) {
      return `割当キー "${key.toUpperCase()}" が重複しています`;
    }
    usedKeys[key] = true;
  }
  return null;
}

// ── Collect config from UI ──
function collectConfig() {
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
    const url = row.querySelectorAll("input[type='text']")[1].value.trim();
    const dispatchKey = row.querySelector(".dispatch-key-select").value;
    if (name) {
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

  // Apps
  for (const row of document.querySelectorAll("#apps-list .list-row")) {
    const name = row.querySelector(".key-input").value.trim();
    const appSelect = row.querySelector(".app-select");
    const process = appSelect.value;
    const selectedOpt = appSelect.options[appSelect.selectedIndex];
    const command = selectedOpt?.dataset?.command || "";
    const dispatchKey = row.querySelector(".dispatch-key-select").value;
    if (name && process) {
      const entry = { process };
      if (dispatchKey) entry.key = dispatchKey;
      if (command) entry.command = command;
      collected.apps[name] = entry;
    }
  }

  return collected;
}

// ── Apply / Reset / Defaults ──
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
    config = newConfig;

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
  await loadConfig();
});

document.getElementById("btn-defaults").addEventListener("click", async () => {
  try {
    config = await invoke("default_config");
    renderConfig();
  } catch (e) {
    console.error("初期値の取得に失敗:", e);
  }
});

// ── Kanata status ──
async function refreshKanataStatus() {
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

listen("kanata-status-changed", (event) => {
  updateKanataUI(event.payload);
});

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
      config = newConfig;
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
  const { open } = window.__TAURI__.shell;
  await open("https://github.com/kimushun1101/muhenkan-switch-rs");
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

// ── Autostart checkbox ──
const autostartCheckbox = document.getElementById("opt-autostart");
autostartCheckbox.addEventListener("change", async () => {
  try {
    await invoke("set_autostart_enabled", { enabled: autostartCheckbox.checked });
  } catch (e) {
    console.error("自動起動の切り替えに失敗:", e);
    autostartCheckbox.checked = !autostartCheckbox.checked;
  }
});

async function loadAutostart() {
  try {
    autostartCheckbox.checked = await invoke("get_autostart_enabled");
  } catch (e) {
    console.error("自動起動状態の取得に失敗:", e);
  }
}

// ── Utility ──
function escapeHtml(str) {
  return str.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;");
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

// ── Keyboard shortcuts ──
document.addEventListener("keydown", (e) => {
  // モーダル表示中はショートカット無効（Escapeはモーダル側で処理済み）
  if (document.querySelector(".modal-overlay")) return;

  // Ctrl+S → 適用（保存）
  if (e.ctrlKey && e.key === "s") {
    e.preventDefault();
    const btn = document.getElementById("btn-apply");
    btn.focus();
    btn.click();
    return;
  }

  // Ctrl+Q → 終了
  if (e.ctrlKey && e.key === "q") {
    e.preventDefault();
    invoke("quit_app");
    return;
  }

  // F1 → ヘルプ
  if (e.key === "F1") {
    e.preventDefault();
    invoke("open_help_window");
    return;
  }

  // Escape → ウィンドウを隠す（トレイ格納）
  if (e.key === "Escape") {
    e.preventDefault();
    window.__TAURI__.window.getCurrentWindow().hide();
    return;
  }
});

// ── Initialize ──
async function init() {
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
  const installType = await invoke("get_install_type");
  if (installType === "installer") {
    // 起動 5 秒後にサイレントチェック
    setTimeout(() => checkForUpdate(true), 5000);

    // トレイメニューからの手動チェック
    listen("check-update-requested", () => checkForUpdate(false));
  }
}

init();
