// ── Generic filterable picker modal ──
// forms/apps.ts の showProcessPicker と forms/search.ts の showSearchPicker で
// ほぼ同一だった overlay 生成 / .modal 骨格 / フィルタ入力 / close() /
// overlay クリック・Escape での閉じる処理を集約 (Issue #229)。
// 一覧の描画方法 (フラット / グループ化) と選択後の後処理は呼び出し側に委ねるため、
// DOM 構造・クラス名・フォーカス挙動は元実装から変更していない。

export interface PickerModalOptions<T> {
  /** .modal-header に表示するタイトル (静的文字列想定。エスケープ不要) */
  title: string;
  /**
   * `.modal-list` の中身を再描画するコールバック。
   * `filter` はフィルタ入力欄の現在値、`select` は項目クリック時に呼ぶと
   * モーダルを閉じてその値で Promise を解決する。
   */
  renderList: (list: HTMLUListElement, filter: string, select: (result: T) => void) => void;
}

export function createPickerModal<T>({
  title,
  renderList,
}: PickerModalOptions<T>): Promise<T | null> {
  return new Promise<T | null>((resolve) => {
    const overlay = document.createElement('div');
    overlay.className = 'modal-overlay';
    overlay.innerHTML = `
      <div class="modal">
        <div class="modal-header">${title}</div>
        <div class="modal-body">
          <input type="text" class="modal-search" placeholder="フィルター...">
          <ul class="modal-list"></ul>
        </div>
        <div class="modal-footer">
          <button class="btn-cancel">キャンセル</button>
        </div>
      </div>
    `;

    const list = overlay.querySelector<HTMLUListElement>('.modal-list');
    const searchInput = overlay.querySelector<HTMLInputElement>('.modal-search');
    if (!list || !searchInput) {
      resolve(null);
      return;
    }

    function close(result: T | null): void {
      overlay.remove();
      document.removeEventListener('keydown', onKeydown);
      resolve(result);
    }

    function render(filter = ''): void {
      if (!list) return;
      renderList(list, filter, close);
    }

    searchInput.addEventListener('input', (e) => {
      const target = e.target as HTMLInputElement;
      render(target.value);
    });

    overlay
      .querySelector<HTMLButtonElement>('.btn-cancel')
      ?.addEventListener('click', () => close(null));

    overlay.addEventListener('click', (e) => {
      if (e.target === overlay) close(null);
    });

    function onKeydown(e: KeyboardEvent): void {
      if (e.key === 'Escape') close(null);
    }
    document.addEventListener('keydown', onKeydown);

    render();
    document.body.appendChild(overlay);
    searchInput.focus();
  });
}
