#!/usr/bin/env bash
# Debug ビルド → bin/ にコピー
set -euo pipefail

EXT=""; [ "${OS:-}" = "Windows_NT" ] && EXT=".exe"
TRIPLE=$(rustc -vV | grep host | awk '{print $2}')

# ── Tauri externalBin の準備 ──
# muhenkan-switch-core を先にビルドして binaries/ に配置
cargo build -p muhenkan-switch-core
mkdir -p muhenkan-switch/binaries
cp "target/debug/muhenkan-switch-core${EXT}" "muhenkan-switch/binaries/muhenkan-switch-core-${TRIPLE}${EXT}"
echo "[build] Prepared externalBin: muhenkan-switch-core-${TRIPLE}${EXT}"

# kanata バイナリを binaries/ に配置
cp "./bin/kanata_cmd_allowed${EXT}" "muhenkan-switch/binaries/kanata_cmd_allowed-${TRIPLE}${EXT}"
echo "[build] Prepared externalBin: kanata_cmd_allowed-${TRIPLE}${EXT}"

# ── ワークスペース全体をビルド ──
cargo build --workspace

# Linux ではバイナリ名と crate ディレクトリ名が衝突するため bin/ にコピー
mkdir -p ./bin
cp "target/debug/muhenkan-switch-core${EXT}" "./bin/muhenkan-switch-core${EXT}"
echo "[build] Copied -> ./bin/muhenkan-switch-core${EXT}"
if [ -f "target/debug/muhenkan-switch${EXT}" ]; then
  cp "target/debug/muhenkan-switch${EXT}" "./bin/muhenkan-switch${EXT}"
  echo "[build] Copied -> ./bin/muhenkan-switch${EXT}"
fi

# muhenkan.kbd を bin/ にコピー（常に最新を反映）
cp kanata/muhenkan.kbd ./bin/muhenkan.kbd
echo "[build] Copied -> ./bin/muhenkan.kbd"

# config.toml が bin/ になければ OS 別デフォルトからコピー
# （ユーザーが bin/config.toml を編集している場合は上書きしない）
if [ ! -f "./bin/config.toml" ]; then
  if [ "${OS:-}" = "Windows_NT" ]; then
    cp config/default-windows.toml ./bin/config.toml
  elif [ "$(uname)" = "Darwin" ]; then
    cp config/default-macos.toml ./bin/config.toml
  else
    cp config/default-linux.toml ./bin/config.toml
  fi
  echo "[build] Created ./bin/config.toml from default"
fi
