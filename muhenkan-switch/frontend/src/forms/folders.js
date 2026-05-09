// ── Folders form ──
import { invoke } from "../lib/tauri.js";
import { getConfig } from "../lib/state.js";
import { createDispatchKeySelect } from "../lib/dispatch-key.js";
import { escapeHtml } from "../lib/utils.js";

export function renderFoldersList() {
  const config = getConfig();
  const container = document.getElementById("folders-list");
  container.innerHTML = "";
  for (const [name, entry] of Object.entries(config.folders || {})) {
    addFolderRow(container, name, entry.path, entry.key || "");
  }
}

export function addFolderRow(container, name = "", path = "", dispatchKey = "") {
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

export function initFoldersForm() {
  document.getElementById("btn-add-folder").addEventListener("click", () => {
    addFolderRow(document.getElementById("folders-list"));
  });
}
