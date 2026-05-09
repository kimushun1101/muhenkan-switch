// ── Search engines form ──
import { getConfig, getSearchPresets } from "../lib/state";
import type { SearchPreset } from "../lib/state";
import { createDispatchKeySelect } from "../lib/dispatch-key";
import { escapeHtml } from "../lib/utils";
import type { SearchEntry } from "../lib/config";
import type { CollectedConfig } from "../lib/config-io";

export function renderSearchList(): void {
  const config = getConfig();
  if (!config) return;
  const container = document.getElementById("search-list");
  if (!container) return;
  container.innerHTML = "";
  for (const [name, entry] of Object.entries(config.search ?? {})) {
    addSearchRow(container, name, entry.url, entry.key ?? "");
  }
}

// Collect search-list rows into the shared collected object.
// Mirrors the original logic from lib/config-io.ts so behavior is unchanged.
export function collectSearch(collected: CollectedConfig): void {
  for (const row of document.querySelectorAll<HTMLElement>("#search-list .list-row")) {
    const nameInput = row.querySelector<HTMLInputElement>(".key-input");
    const urlInput = row.querySelector<HTMLInputElement>(".url-input");
    const keySelect = row.querySelector<HTMLSelectElement>(".dispatch-key-select");
    if (!nameInput || !urlInput || !keySelect) continue;
    const name = nameInput.value.trim();
    const url = urlInput.value.trim();
    const dispatchKey = keySelect.value;
    if (name && url) {
      const entry: SearchEntry = { url };
      if (dispatchKey) entry.key = dispatchKey;
      collected.search[name] = entry;
    }
  }
}

export function addSearchRow(
  container: HTMLElement,
  name: string = "",
  url: string = "",
  dispatchKey: string = "",
): void {
  const row = document.createElement("div");
  row.className = "list-row";
  row.innerHTML = `
    <input type="text" class="key-input" placeholder="機能名" value="${escapeHtml(name)}">
    <input type="text" class="url-input" placeholder="URL テンプレート ({query})" value="${escapeHtml(url)}">
    <button class="btn-pick-search" title="プリセットから選択">選択</button>
    <button class="btn-remove" title="削除">&times;</button>
  `;
  const keySelect = createDispatchKeySelect(dispatchKey);
  row.insertBefore(keySelect, row.firstChild);

  const btnPick = row.querySelector<HTMLButtonElement>(".btn-pick-search");
  btnPick?.addEventListener("click", async () => {
    const selected = await showSearchPicker();
    if (selected) {
      const nameInput = row.querySelector<HTMLInputElement>(".key-input");
      const urlInput = row.querySelector<HTMLInputElement>(".url-input");
      if (nameInput) nameInput.value = selected.label;
      if (urlInput) urlInput.value = selected.url;
    }
  });

  const btnRemove = row.querySelector<HTMLButtonElement>(".btn-remove");
  btnRemove?.addEventListener("click", () => row.remove());
  container.appendChild(row);
}

// ── Search preset picker modal ──
export function showSearchPicker(): Promise<SearchPreset | null> {
  return new Promise<SearchPreset | null>((resolve) => {
    const SEARCH_PRESETS = getSearchPresets();
    const overlay = document.createElement("div");
    overlay.className = "modal-overlay";
    overlay.innerHTML = `
      <div class="modal">
        <div class="modal-header">検索サービスを選択</div>
        <div class="modal-body">
          <input type="text" class="modal-search" placeholder="フィルター...">
          <ul class="modal-list"></ul>
        </div>
        <div class="modal-footer">
          <button class="btn-cancel">キャンセル</button>
        </div>
      </div>
    `;

    const list = overlay.querySelector<HTMLUListElement>(".modal-list");
    const filterInput = overlay.querySelector<HTMLInputElement>(".modal-search");
    if (!list || !filterInput) {
      resolve(null);
      return;
    }

    function renderList(filter: string = ""): void {
      if (!list) return;
      list.innerHTML = "";
      const lf = filter.toLowerCase();
      for (const [category, services] of Object.entries(SEARCH_PRESETS)) {
        const filtered = services.filter((s) =>
          s.label.toLowerCase().includes(lf) || category.toLowerCase().includes(lf)
        );
        if (filtered.length === 0) continue;
        const header = document.createElement("li");
        header.className = "modal-list-header";
        header.textContent = category;
        list.appendChild(header);
        for (const svc of filtered) {
          const li = document.createElement("li");
          li.textContent = svc.label;
          li.addEventListener("click", () => close(svc));
          list.appendChild(li);
        }
      }
    }

    filterInput.addEventListener("input", (e) => {
      const target = e.target as HTMLInputElement;
      renderList(target.value);
    });

    function close(result: SearchPreset | null): void {
      overlay.remove();
      document.removeEventListener("keydown", onKeydown);
      resolve(result);
    }

    overlay.querySelector<HTMLButtonElement>(".btn-cancel")?.addEventListener("click", () => close(null));
    overlay.addEventListener("click", (e) => {
      if (e.target === overlay) close(null);
    });

    function onKeydown(e: KeyboardEvent): void {
      if (e.key === "Escape") close(null);
    }
    document.addEventListener("keydown", onKeydown);

    renderList();
    document.body.appendChild(overlay);
    filterInput.focus();
  });
}

export function initSearchForm(): void {
  const btn = document.getElementById("btn-add-search");
  const list = document.getElementById("search-list");
  if (!btn || !list) return;
  btn.addEventListener("click", () => {
    addSearchRow(list);
  });
}
