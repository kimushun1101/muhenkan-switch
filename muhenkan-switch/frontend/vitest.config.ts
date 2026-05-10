// Vitest config (Phase 4-C, Issue #158 — coverage 閾値追加 Issue #167)
//
// vite.config.js が `.js` のままなので test フィールドを混ぜず独立 config にする。
// vite 5.4 との互換性確保のため vitest 2.x 系を採用。
//
// 環境: happy-dom (jsdom より軽量・高速。escapeHtml のような純粋関数も含めて
//   全テストを 1 環境で揃え、forms/lib の薄い DOM 操作も賄えるため)。
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    environment: 'happy-dom',
    include: ['src/**/*.test.ts'],
    globals: false,
    coverage: {
      provider: 'v8',
      reporter: ['text', 'html'],
      // include は **テスト済ファイル** だけを whitelist。新しいテストを追加した
      // 時は対象ファイルをここに足す。未テストファイルを混ぜず、cover 済の品質
      // 維持を per-file 閾値で強制する設計 (Issue #167)。
      include: ['src/lib/utils.ts', 'src/lib/dispatch-key.ts', 'src/forms/timestamp.ts'],
      exclude: ['src/**/*.test.ts', 'src/**/__tests__/**'],
      thresholds: {
        perFile: true,
        lines: 80,
        functions: 80,
        branches: 80,
        statements: 80,
      },
    },
  },
});
