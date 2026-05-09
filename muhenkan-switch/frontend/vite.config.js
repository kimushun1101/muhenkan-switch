import { defineConfig } from 'vite';
import { resolve } from 'node:path';

const host = process.env.TAURI_DEV_HOST;

// Vite config for Tauri v2 (Phase 1: Vanilla JS, no @tauri-apps/api yet)
// See: https://v2.tauri.app/start/frontend/vite/
export default defineConfig({
  // Tauri 環境で相対パス解決するため (defensive)
  base: './',
  // Tauri CLI が出力をパースしやすくするため画面クリアを抑制
  clearScreen: false,
  server: {
    // Tauri が devUrl で見失わないよう strictPort を必須化
    port: 5173,
    strictPort: true,
    host: host || false,
    hmr: host ? { protocol: 'ws', host, port: 1421 } : undefined,
    watch: {
      // Rust 側のビルド成果物変更で無限リロードしないよう除外
      ignored: ['**/src-tauri/**'],
    },
  },
  envPrefix: ['VITE_', 'TAURI_ENV_*'],
  build: {
    target: process.env.TAURI_ENV_PLATFORM === 'windows' ? 'chrome105' : 'safari13',
    minify: !process.env.TAURI_ENV_DEBUG ? 'esbuild' : false,
    sourcemap: !!process.env.TAURI_ENV_DEBUG,
    rollupOptions: {
      input: {
        main: resolve(__dirname, 'index.html'),
        help: resolve(__dirname, 'help.html'),
      },
    },
  },
});
