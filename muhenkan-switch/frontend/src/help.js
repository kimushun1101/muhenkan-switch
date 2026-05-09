// ── Help window entrypoint ──
// Phase 2 で help.html の inline script から切り出し、`@tauri-apps/api` を bundle 化。
// 従来 inline で持っていた zoom / drag / SVG load / Escape close ロジックを完全保持。
// 共通化のため Tauri API は `lib/tauri.js` facade 経由で取得する。

import { invoke, listen, getCurrentWindow } from "./lib/tauri.js";

// インストール種別 (installer / script) によって表示を切り替え
const install = new URLSearchParams(location.search).get("install");
if (install) {
  document.querySelectorAll("[data-install]").forEach((el) => {
    if (el.dataset.install !== install) el.style.display = "none";
  });
}

// キーボード配列 SVG を Tauri 経由で取得して埋め込む
const container = document.getElementById("keyboard-svg");
let scale = 1, tx = 0, ty = 0, dragging = false, sx = 0, sy = 0;

function loadSvg() {
  invoke("generate_keyboard_svg").then((svg) => {
    container.innerHTML = svg;
    scale = 1; tx = 0; ty = 0;
    const svgEl = container.querySelector("svg");
    if (svgEl) svgEl.style.transform = "";
  }).catch((err) => {
    container.textContent = "キーボード図の読み込みに失敗しました: " + err;
  });
}

function applySvgTransform() {
  const svgEl = container.querySelector("svg");
  if (svgEl) svgEl.style.transform = "translate(" + tx + "px," + ty + "px) scale(" + scale + ")";
}

// ホイールでズーム（コンテナ上のみ）
container.addEventListener("wheel", (e) => {
  e.preventDefault();
  const rect = container.getBoundingClientRect();
  const mx = e.clientX - rect.left;
  const my = e.clientY - rect.top;
  const old = scale;
  scale = Math.min(5, Math.max(0.5, scale * (e.deltaY < 0 ? 1.12 : 0.88)));
  const r = scale / old;
  tx = mx - r * (mx - tx);
  ty = my - r * (my - ty);
  applySvgTransform();
}, { passive: false });

// ドラッグで移動
container.addEventListener("mousedown", (e) => {
  if (e.button === 0) {
    dragging = true; sx = e.clientX - tx; sy = e.clientY - ty;
    container.classList.add("dragging");
    e.preventDefault();
  }
});
document.addEventListener("mousemove", (e) => {
  if (dragging) { tx = e.clientX - sx; ty = e.clientY - sy; applySvgTransform(); }
});
document.addEventListener("mouseup", () => {
  dragging = false; container.classList.remove("dragging");
});

// ダブルクリックでリセット
container.addEventListener("dblclick", () => {
  scale = 1; tx = 0; ty = 0; applySvgTransform();
});

// Escape → ヘルプウィンドウを閉じる
document.addEventListener("keydown", (e) => {
  if (e.key === "Escape") {
    e.preventDefault();
    getCurrentWindow().close();
  }
});

// 初回読み込み
loadSvg();
// 設定保存時に自動更新
listen("config-saved", () => { loadSvg(); });
