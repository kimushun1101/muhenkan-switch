#!/usr/bin/env bash
# ビルド済み GUI を起動する
set -euo pipefail

EXT=""; [ "${OS:-}" = "Windows_NT" ] && EXT=".exe"

# 前回のプロセスが残っていれば終了させる
if [ "${OS:-}" = "Windows_NT" ]; then
  taskkill //F //IM muhenkan-switch.exe 2>/dev/null || true
fi

echo "Starting GUI from ./bin/ ..."
./bin/muhenkan-switch${EXT}
