#!/usr/bin/env bash
# Linux 用 Tauri ビルド依存ライブラリの存在チェック
set -euo pipefail

if [ "$(uname)" != "Linux" ]; then
  exit 0
fi

MISSING=""
for lib in webkit2gtk-4.1 javascriptcoregtk-4.1 libsoup-3.0; do
  if ! pkg-config --exists "$lib" 2>/dev/null; then
    MISSING="$MISSING $lib"
  fi
done

if [ -n "$MISSING" ]; then
  echo "[check-deps] ERROR: Missing system libraries:$MISSING"
  echo "[check-deps] Run 'mise run setup' to install them."
  exit 1
fi
