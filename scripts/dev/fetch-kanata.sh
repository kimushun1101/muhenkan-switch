#!/usr/bin/env bash
# 開発用 kanata バイナリをダウンロード
set -euo pipefail

VERSION="v1.11.0"
EXT=""; [ "${OS:-}" = "Windows_NT" ] && EXT=".exe"
mkdir -p ./bin
DEST="./bin/kanata_cmd_allowed${EXT}"

if [ -f "$DEST" ]; then
  echo "[fetch-kanata] kanata_cmd_allowed already exists -- skipping."
  exit 0
fi

# ── OS・アーキテクチャ検出 ──
SYSTEM=$(uname -s)
MACHINE=$(uname -m)

case "$SYSTEM" in
  Linux)
    ASSET="linux-binaries-x64.zip"
    BINARY="kanata_linux_cmd_allowed_x64"
    ;;
  Darwin)
    case "$MACHINE" in
      arm64)
        ASSET="macos-binaries-arm64.zip"
        BINARY="kanata_macos_cmd_allowed_arm64"
        ;;
      *)
        ASSET="macos-binaries-x64.zip"
        BINARY="kanata_macos_cmd_allowed_x64"
        ;;
    esac
    ;;
  MINGW*|MSYS*|CYGWIN*|Windows_NT)
    ASSET="windows-binaries-x64.zip"
    BINARY="kanata_windows_tty_winIOv2_cmd_allowed_x64.exe"
    ;;
  *)
    echo "[fetch-kanata] Unsupported OS: $SYSTEM"
    exit 1
    ;;
esac

URL="https://github.com/jtroo/kanata/releases/download/${VERSION}/${ASSET}"
DLDIR=".tmp-kanata-dl"
mkdir -p "$DLDIR"

echo "[fetch-kanata] Downloading kanata ${VERSION} (${ASSET})..."
curl -fsSL "$URL" -o "$DLDIR/kanata.zip"

unzip -o "$DLDIR/kanata.zip" "$BINARY" -d "$DLDIR"

if [ -f "$DLDIR/$BINARY" ]; then
  cp "$DLDIR/$BINARY" "$DEST"
  [ "${OS:-}" != "Windows_NT" ] && chmod +x "$DEST"
fi

rm -rf "$DLDIR"

if [ ! -f "$DEST" ]; then
  echo "[fetch-kanata] ERROR: Binary not found in archive."
  exit 1
fi

# GLIBC check (Linux only)
if [ "$SYSTEM" = "Linux" ]; then
  if ! "$DEST" --version >/dev/null 2>&1; then
    rm -f "$DEST"
    echo "[fetch-kanata] Prebuilt binary incompatible (likely GLIBC mismatch)."
    echo "[fetch-kanata] Building kanata from source..."
    cargo install kanata --version "${VERSION#v}" --features cmd --root ./tmp-kanata-install
    cp "./tmp-kanata-install/bin/kanata" "$DEST"
    rm -rf ./tmp-kanata-install
    echo "[fetch-kanata] Done -> $DEST (built from source)"
  else
    echo "[fetch-kanata] Done -> $DEST (prebuilt)"
  fi
else
  echo "[fetch-kanata] Done -> $DEST (prebuilt)"
fi
