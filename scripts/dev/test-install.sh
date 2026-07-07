#!/usr/bin/env bash
# ローカルでインストールスクリプトをテスト（Linux のみ）
set -euo pipefail

if [ "$(uname)" != "Linux" ]; then
  echo "Currently only supports Linux."
  exit 1
fi

STAGING="tmp-test-install/muhenkan-switch-linux-x64"
rm -rf tmp-test-install
mkdir -p "$STAGING"

echo "Creating staging directory..."

# バイナリ
cp ./bin/muhenkan-switch-core "$STAGING/"
cp ./bin/muhenkan-switch "$STAGING/" 2>/dev/null || true

# 設定ファイル
# config.toml は同梱しない（リリース archive と同じ構成。#220）。
# install.sh は config.toml 不在時にスキップし、初回起動時に
# muhenkan-switch が OS 別デフォルトから自動生成する。
cp kanata/muhenkan.kbd "$STAGING/"
cp kanata/muhenkan-macos.kbd "$STAGING/" 2>/dev/null || true

# スクリプト
cp scripts/install/install.sh "$STAGING/"
cp scripts/install/uninstall.sh "$STAGING/"
cp scripts/install/update.sh "$STAGING/"
chmod +x "$STAGING/"*.sh

# README
cp README.md "$STAGING/"

echo "Staging directory: $STAGING"
echo "Contents:"
ls -la "$STAGING/"
echo ""
echo "Running install.sh..."
echo ""

cd "$STAGING"
bash install.sh
