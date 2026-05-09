// ── Dispatch key dropdown helper + duplicate validation ──
// Search / Folders / Apps の各フォームで共有される。
import { DISPATCH_KEYS } from "./state.js";

export function createDispatchKeySelect(selectedKey = "") {
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

export function validateDispatchKeys() {
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
