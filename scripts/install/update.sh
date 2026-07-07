#!/usr/bin/env bash
set -euo pipefail

# muhenkan-switch アップデートスクリプト (Linux)
#
# GitHub Releases から最新版をダウンロードし、install.sh を実行して更新します。
# root 権限は不要です。

# ── 設定 ──
REPO="kimushun1101/muhenkan-switch"
ASSET_NAME="muhenkan-switch-linux-x64.tar.gz"

echo ""
echo "=== muhenkan-switch アップデーター (Linux) ==="
echo ""

# ── 最新バージョンを取得 ──
# GitHub API (未認証 60 req/時/IP) はレート制限に当たりやすいため、
# まず releases/latest への HTTP リダイレクト先 (Location ヘッダ) からタグを
# 取得する経路を優先する (API 不要・レート制限なし)。失敗した場合のみ API に
# フォールバックする。
echo "最新バージョンを確認しています..."

latest_tag=""

if command -v curl &>/dev/null; then
    redirect_url=$(curl -fsSLI -o /dev/null -w '%{url_effective}' "https://github.com/$REPO/releases/latest" 2>/dev/null) || redirect_url=""
elif command -v wget &>/dev/null; then
    redirect_url=$(wget --max-redirect=20 --server-response --spider -q -O /dev/null "https://github.com/$REPO/releases/latest" 2>&1 \
        | grep -i 'Location:' | tail -1 | tr -d '[:space:]') || redirect_url=""
else
    echo "[ERROR] curl または wget が必要です"
    exit 1
fi

case "$redirect_url" in
    */releases/tag/v[0-9]*) latest_tag=$(echo "$redirect_url" | sed 's#.*/releases/tag/##') ;;
esac

# フォールバック: GitHub API (未認証 60 req/時/IP のレート制限あり)
if [ -z "$latest_tag" ]; then
    if command -v curl &>/dev/null; then
        api_response=$(curl -fsSL "https://api.github.com/repos/$REPO/releases/latest")
    else
        api_response=$(wget -qO- "https://api.github.com/repos/$REPO/releases/latest")
    fi
    # jq なしで tag_name を抽出
    latest_tag=$(echo "$api_response" | grep -o '"tag_name"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/"tag_name"[[:space:]]*:[[:space:]]*"\(.*\)"/\1/')
fi

if [ -z "$latest_tag" ]; then
    echo "[ERROR] 最新バージョンの取得に失敗しました"
    echo "        ネットワーク接続を確認してください。"
    exit 1
fi

# ── 現在のバージョンを取得 ──
current_version="(不明)"
if command -v muhenkan-switch-core &>/dev/null; then
    version_output=$(muhenkan-switch-core --version 2>/dev/null || true)
    if [ -n "$version_output" ]; then
        # "muhenkan-switch-core x.y.z" → "vx.y.z"
        version_string=$(echo "$version_output" | sed 's/^muhenkan-switch-core[[:space:]]*//')
        current_version="v$version_string"
    fi
fi

# ── バージョン表示 ──
echo ""
echo "  現在のバージョン: $current_version"
echo "  最新のバージョン: $latest_tag"
echo ""

if [ "$current_version" = "$latest_tag" ]; then
    echo "既に最新バージョンです。"
    exit 0
fi

# ── 更新確認 ──
read -rp "更新しますか？ (y/N): " confirm
if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
    echo "更新を中止しました。"
    exit 0
fi

# ── ダウンロード ──
echo ""
echo "$latest_tag をダウンロードしています..."

download_url="https://github.com/$REPO/releases/download/$latest_tag/$ASSET_NAME"
temp_dir=$(mktemp -d)

if command -v curl &>/dev/null; then
    downloader="curl -fSL -o"
else
    downloader="wget -q -O"
fi

if ! $downloader "$temp_dir/archive.tar.gz" "$download_url"; then
    echo "[ERROR] ダウンロードに失敗しました"
    rm -rf "$temp_dir"
    exit 1
fi
echo "[OK] ダウンロード完了"

# ── 展開 ──
tar xzf "$temp_dir/archive.tar.gz" -C "$temp_dir"
echo "[OK] 展開完了"

# ── install.sh を実行 ──
install_script=$(find "$temp_dir" -name "install.sh" -type f | head -1)
if [ -n "$install_script" ]; then
    echo ""
    echo "インストールスクリプトを実行しています..."
    chmod +x "$install_script"
    bash "$install_script"
else
    echo "[ERROR] install.sh が見つかりませんでした"
    rm -rf "$temp_dir"
    exit 1
fi

# ── クリーンアップ ──
rm -rf "$temp_dir"

echo ""
echo "=== アップデート完了 ==="
echo ""
