// ── Keyboard shortcuts ──
import { invoke, getCurrentWindow } from './tauri';

export function initShortcuts(): void {
  document.addEventListener('keydown', (e: KeyboardEvent) => {
    // モーダル表示中はショートカット無効（Escapeはモーダル側で処理済み）
    if (document.querySelector('.modal-overlay')) return;

    // Ctrl+S → 適用（保存）
    if (e.ctrlKey && e.key === 's') {
      e.preventDefault();
      const btn = document.getElementById('btn-apply') as HTMLButtonElement | null;
      if (btn) {
        btn.focus();
        btn.click();
      }
      return;
    }

    // Ctrl+Q → 終了
    if (e.ctrlKey && e.key === 'q') {
      e.preventDefault();
      void invoke('quit_app');
      return;
    }

    // F1 → ヘルプ
    if (e.key === 'F1') {
      e.preventDefault();
      void invoke('open_help_window');
      return;
    }

    // Escape → ウィンドウを隠す（トレイ格納）
    if (e.key === 'Escape') {
      e.preventDefault();
      void getCurrentWindow().hide();
      return;
    }
  });
}
