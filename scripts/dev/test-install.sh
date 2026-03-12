#!/usr/bin/env bash
# ローカルでインストールスクリプトをテスト（Linux のみ）
set -euo pipefail

if [ "$(uname)" != "Linux" ]; then
  echo "[test-install] Currently only supports Linux."
  exit 1
fi

STAGING="tmp-test-install/muhenkan-switch-rs-linux-x64"
rm -rf tmp-test-install
mkdir -p "$STAGING"

echo "[test-install] Creating staging directory..."

# バイナリ
cp ./bin/muhenkan-switch-core "$STAGING/"
cp ./bin/muhenkan-switch "$STAGING/" 2>/dev/null || true

# 設定ファイル
cp config/default.toml "$STAGING/config.toml"
cp kanata/muhenkan.kbd "$STAGING/"
cp kanata/muhenkan-macos.kbd "$STAGING/" 2>/dev/null || true

# スクリプト
cp scripts/install/install.sh "$STAGING/"
cp scripts/install/uninstall.sh "$STAGING/"
cp scripts/install/update.sh "$STAGING/"
chmod +x "$STAGING/"*.sh

# README
cp README.md "$STAGING/"

echo "[test-install] Staging directory: $STAGING"
echo "[test-install] Contents:"
ls -la "$STAGING/"
echo ""
echo "[test-install] Running install.sh..."
echo ""

cd "$STAGING"
bash install.sh
