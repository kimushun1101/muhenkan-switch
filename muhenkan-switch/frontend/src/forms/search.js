// ── Search engines form ──
import { getConfig, getSearchPresets } from "../lib/state.js";
import { createDispatchKeySelect } from "../lib/dispatch-key.js";
import { escapeHtml } from "../lib/utils.js";

export function renderSearchList() {
  const config = getConfig();
  const container = document.getElementById("search-list");
  container.innerHTML = "";
  for (const [name, entry] of Object.entries(config.search || {})) {
    addSearchRow(container, name, entry.url, entry.key || "");
  }
}

// Collect search-list rows into the shared collected object.
// Mirrors the original logic from lib/config-io.js so behavior is unchanged.
export function collectSearch(collected) {
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
}

export function addSearchRow(container, name = "", url = "", dispatchKey = "") {
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

  row.querySelector(".btn-pick-search").addEventListener("click", async () => {
    const selected = await showSearchPicker();
    if (selected) {
      row.querySelector(".key-input").value = selected.label;
      row.querySelector(".url-input").value = selected.url;
    }
  });

  row.querySelector(".btn-remove").addEventListener("click", () => row.remove());
  container.appendChild(row);
}

// ── Search preset picker modal ──
export function showSearchPicker() {
  return new Promise((resolve) => {
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

    const list = overlay.querySelector(".modal-list");
    const filterInput = overlay.querySelector(".modal-search");

    function renderList(filter = "") {
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

    filterInput.addEventListener("input", (e) => renderList(e.target.value));

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

    renderList();
    document.body.appendChild(overlay);
    filterInput.focus();
  });
}

export function initSearchForm() {
  document.getElementById("btn-add-search").addEventListener("click", () => {
    addSearchRow(document.getElementById("search-list"));
  });
}
