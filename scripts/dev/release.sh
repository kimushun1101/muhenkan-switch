#!/usr/bin/env bash
# Release ビルド → bin/ にコピー
set -euo pipefail

EXT=""; [ "${OS:-}" = "Windows_NT" ] && EXT=".exe"
TRIPLE=$(rustc -vV | grep host | awk '{print $2}')

# ── Tauri externalBin の準備 ──
cargo build -p muhenkan-switch-core --release
mkdir -p muhenkan-switch/binaries
cp "target/release/muhenkan-switch-core${EXT}" "muhenkan-switch/binaries/muhenkan-switch-core-${TRIPLE}${EXT}"
echo "Prepared externalBin: muhenkan-switch-core-${TRIPLE}${EXT}"

cp "./bin/kanata_cmd_allowed${EXT}" "muhenkan-switch/binaries/kanata_cmd_allowed-${TRIPLE}${EXT}"
echo "Prepared externalBin: kanata_cmd_allowed-${TRIPLE}${EXT}"

# ── ワークスペース全体をビルド ──
cargo build --workspace --release

mkdir -p ./bin
cp "target/release/muhenkan-switch-core${EXT}" "./bin/muhenkan-switch-core${EXT}"
echo "Copied -> ./bin/muhenkan-switch-core${EXT}"
if [ -f "target/release/muhenkan-switch${EXT}" ]; then
  cp "target/release/muhenkan-switch${EXT}" "./bin/muhenkan-switch${EXT}"
  echo "Copied -> ./bin/muhenkan-switch${EXT}"
fi
