// ── Folders form ──
import { invoke } from "../lib/tauri";
import { getConfig } from "../lib/state";
import { createDispatchKeySelect } from "../lib/dispatch-key";
import { escapeHtml } from "../lib/utils";
import type { FolderEntry } from "../lib/config";
import type { CollectedConfig } from "../lib/config-io";

export function renderFoldersList(): void {
  const config = getConfig();
  if (!config) return;
  const container = document.getElementById("folders-list");
  if (!container) return;
  container.innerHTML = "";
  for (const [name, entry] of Object.entries(config.folders ?? {})) {
    addFolderRow(container, name, entry.path, entry.key ?? "");
  }
}

// Collect folders-list rows into the shared collected object.
// Mirrors the original logic from lib/config-io.ts so behavior is unchanged.
export function collectFolders(collected: CollectedConfig): void {
  for (const row of document.querySelectorAll<HTMLElement>("#folders-list .list-row")) {
    const nameInput = row.querySelector<HTMLInputElement>(".key-input");
    const pathInput = row.querySelector<HTMLInputElement>(".path-input");
    const keySelect = row.querySelector<HTMLSelectElement>(".dispatch-key-select");
    if (!nameInput || !pathInput || !keySelect) continue;
    const name = nameInput.value.trim();
    const path = pathInput.value.trim();
    const dispatchKey = keySelect.value;
    if (name) {
      const entry: FolderEntry = { path };
      if (dispatchKey) entry.key = dispatchKey;
      collected.folders[name] = entry;
    }
  }
}

export function addFolderRow(
  container: HTMLElement,
  name: string = "",
  path: string = "",
  dispatchKey: string = "",
): void {
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
  row.querySelector<HTMLButtonElement>(".btn-remove")?.addEventListener("click", () => row.remove());
  row.querySelector<HTMLButtonElement>(".btn-browse")?.addEventListener("click", async () => {
    try {
      const selected = await invoke<string | null>("browse_folder");
      if (selected) {
        const pathInput = row.querySelector<HTMLInputElement>(".path-input");
        if (pathInput) pathInput.value = selected;
      }
    } catch (e) {
      console.error("フォルダ選択に失敗:", e);
    }
  });
  container.appendChild(row);
}

export function initFoldersForm(): void {
  const btn = document.getElementById("btn-add-folder");
  const list = document.getElementById("folders-list");
  if (!btn || !list) return;
  btn.addEventListener("click", () => {
    addFolderRow(list);
  });
}
