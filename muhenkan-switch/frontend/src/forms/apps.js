// ── Apps form ──
import { invoke } from "../lib/tauri";
import { getConfig, getAppPresets } from "../lib/state.js";
import { createDispatchKeySelect } from "../lib/dispatch-key.js";
import { escapeHtml } from "../lib/utils.js";

// ── App select dropdown helper ──
export function createAppSelect(currentProcess = "", currentCommand = "") {
  const APP_PRESETS = getAppPresets();
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

export function renderAppsList() {
  const config = getConfig();
  const container = document.getElementById("apps-list");
  container.innerHTML = "";
  for (const [name, entry] of Object.entries(config.apps || {})) {
    addAppRow(container, name, entry.process, entry.command || "", entry.key || "");
  }
}

// Collect apps-list rows into the shared collected object.
// Mirrors the original logic from lib/config-io.js so behavior is unchanged.
// 機能名の重複を防ぐ（IndexMap のキー重複で上書きされるのを回避）
export function collectApps(collected) {
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
}

export function addAppRow(container, name = "", process = "", command = "", dispatchKey = "") {
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

  appSelect.addEventListener("change", () => {
    const selected = appSelect.options[appSelect.selectedIndex];
    if (selected && selected.parentElement.tagName === "OPTGROUP") {
      const category = selected.parentElement.label;
      nameInput.value = `${category} (${selected.textContent})`;
    }
  });

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

// ── Process picker modal ──
export async function showProcessPicker() {
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

export function initAppsForm() {
  document.getElementById("btn-add-app").addEventListener("click", () => {
    addAppRow(document.getElementById("apps-list"));
  });
}
