// ── DOM helpers ──
// strict 化後、`document.getElementById` の `null` 戻りを fail-fast に変換する共通ヘルパー。
// 個別ファイルで再定義していた `requireContainer` / `requireEl` を本モジュールに集約する。

/**
 * 必須 DOM 要素を取得する。見つからなければ throw。
 * 元 .js では non-null 前提で書かれていたので strict 化後も例外で fail-fast する。
 */
export function requireEl<T extends HTMLElement>(id: string): T {
  const el = document.getElementById(id) as T | null;
  if (!el) throw new Error(`Required element #${id} not found`);
  return el;
}
