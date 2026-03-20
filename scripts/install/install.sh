#!/usr/bin/env bash
set -euo pipefail

# muhenkan-switch-rs インストールスクリプト (Linux)
#
# muhenkan-switch, config.toml, muhenkan.kbd をインストールし、
# kanata を GitHub からダウンロードします。
# root 権限は不要です。

# ── 設定 ──
KANATA_VERSION="v1.11.0"
KANATA_ASSET="linux-binaries-x64.zip"
KANATA_BINARY="kanata_linux_cmd_allowed_x64"
INSTALL_DIR="$HOME/.local/share/muhenkan-switch-rs"
BIN_DIR="$HOME/.local/bin"

# スクリプトのあるディレクトリ（展開した zip のルート）
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo ""
echo "=== muhenkan-switch-rs インストーラー (Linux) ==="
echo ""
echo "インストール先: $INSTALL_DIR"
echo "シンボリックリンク: $BIN_DIR"
echo ""

# ── インストールディレクトリ作成 ──
mkdir -p "$INSTALL_DIR"
mkdir -p "$BIN_DIR"

# ── config.toml のバックアップ ──
if [ -f "$INSTALL_DIR/config.toml" ]; then
    backup_name="config.toml.backup.$(date +%Y%m%d%H%M%S)"
    cp "$INSTALL_DIR/config.toml" "$INSTALL_DIR/$backup_name"
    echo "[OK] 既存の config.toml をバックアップしました: $backup_name"
fi

# ── ファイルコピー ──
copy_file() {
    local src="$SCRIPT_DIR/$1"
    local dest="$INSTALL_DIR/$2"
    if [ -f "$src" ]; then
        cp "$src" "$dest"
        chmod +x "$dest" 2>/dev/null || true
        echo "[OK] $1 をコピーしました"
    else
        echo "[SKIP] $1 が見つかりません"
    fi
}

copy_file "muhenkan-switch" "muhenkan-switch"
copy_file "muhenkan-switch-core" "muhenkan-switch-core"
copy_file "config.toml" "config.toml"
copy_file "muhenkan.kbd" "muhenkan.kbd"
copy_file "update.sh" "update.sh"
copy_file "uninstall.sh" "uninstall.sh"

# ── アイコンをインストール ──
ICON_DIR="$HOME/.local/share/icons/hicolor/128x128/apps"
ICON_FILE="$ICON_DIR/muhenkan-switch.png"
icon_src="$SCRIPT_DIR/icon-128x128.png"
if [ -f "$icon_src" ]; then
    mkdir -p "$ICON_DIR"
    cp "$icon_src" "$ICON_FILE"
    # index.theme がなければシステムからコピー（キャッシュ更新に必要）
    HICOLOR_DIR="$HOME/.local/share/icons/hicolor"
    if [ ! -f "$HICOLOR_DIR/index.theme" ] && [ -f /usr/share/icons/hicolor/index.theme ]; then
        cp /usr/share/icons/hicolor/index.theme "$HICOLOR_DIR/index.theme"
    fi
    # アイコンテーマキャッシュを更新
    if command -v gtk-update-icon-cache &>/dev/null; then
        gtk-update-icon-cache -f "$HICOLOR_DIR" 2>/dev/null || true
    fi
    echo "[OK] アイコンをインストールしました"
else
    echo "[SKIP] icon-128x128.png が見つかりません"
fi

# 実行権限を付与
chmod +x "$INSTALL_DIR/muhenkan-switch" 2>/dev/null || true
chmod +x "$INSTALL_DIR/muhenkan-switch-core" 2>/dev/null || true

# ── kanata ダウンロード ──
kanata_dest="$INSTALL_DIR/kanata_cmd_allowed"
if [ -f "$kanata_dest" ]; then
    echo "[SKIP] kanata_cmd_allowed は既にインストール済みです"
    echo "       再ダウンロードする場合は削除してから再実行してください"
else
    echo ""
    echo "kanata $KANATA_VERSION をダウンロードしています..."

    download_url="https://github.com/jtroo/kanata/releases/download/$KANATA_VERSION/$KANATA_ASSET"
    temp_dir=$(mktemp -d)

    if command -v curl &>/dev/null; then
        downloader="curl -fSL -o"
    elif command -v wget &>/dev/null; then
        downloader="wget -q -O"
    else
        echo "[ERROR] curl または wget が必要です"
        rm -rf "$temp_dir"
        exit 1
    fi

    if $downloader "$temp_dir/kanata.zip" "$download_url"; then
        echo "[OK] ダウンロード完了"

        # 展開
        if command -v unzip &>/dev/null; then
            unzip -q -o "$temp_dir/kanata.zip" -d "$temp_dir/extract"
        else
            echo "[ERROR] unzip が必要です: sudo apt install unzip"
            rm -rf "$temp_dir"
            exit 1
        fi

        # バイナリを探す
        kanata_file=$(find "$temp_dir/extract" -name "$KANATA_BINARY" -type f | head -1)
        if [ -n "$kanata_file" ]; then
            cp "$kanata_file" "$kanata_dest"
            chmod +x "$kanata_dest"
            echo "[OK] kanata_cmd_allowed をインストールしました"
        else
            echo "[ERROR] kanata バイナリが見つかりませんでした: $KANATA_BINARY"
            echo "        手動でダウンロードしてください: https://github.com/jtroo/kanata/releases"
        fi
    else
        echo "[ERROR] kanata のダウンロードに失敗しました"
        echo "        手動でダウンロードしてください: https://github.com/jtroo/kanata/releases"
    fi

    rm -rf "$temp_dir"
fi

# ── シンボリックリンク作成 ──
create_symlink() {
    local target="$1"
    local link_name="$2"
    local link_path="$BIN_DIR/$link_name"

    if [ -f "$target" ]; then
        ln -sf "$target" "$link_path"
        echo "[OK] シンボリックリンク作成: $link_name -> $target"
    fi
}

create_symlink "$INSTALL_DIR/muhenkan-switch" "muhenkan-switch"
create_symlink "$INSTALL_DIR/muhenkan-switch-core" "muhenkan-switch-core"
create_symlink "$INSTALL_DIR/kanata_cmd_allowed" "kanata_cmd_allowed"

# ── PATH チェック ──
if ! echo "$PATH" | tr ':' '\n' | grep -qx "$BIN_DIR"; then
    echo ""
    echo "[WARNING] $BIN_DIR が PATH に含まれていません"
    echo "          以下をシェルの設定ファイルに追加してください:"
    echo ""
    echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
    echo ""
fi

# ── 自動起動（オプション）──
echo ""
read -rp "自動起動（デスクトップログイン時）を設定しますか？ (y/N): " install_autostart
if [ "$install_autostart" = "y" ] || [ "$install_autostart" = "Y" ]; then
    autostart_dir="$HOME/.config/autostart"
    mkdir -p "$autostart_dir"

    cat > "$autostart_dir/muhenkan-switch.desktop" << EOF
[Desktop Entry]
Type=Application
Name=muhenkan-switch
Exec=$INSTALL_DIR/muhenkan-switch
Comment=muhenkan-switch GUI (kanata を自動管理)
X-GNOME-Autostart-enabled=true
EOF

    echo "[OK] 自動起動を設定しました"
    echo "     $autostart_dir/muhenkan-switch.desktop"
fi

# ── アプリランチャー登録 ──
APP_DESKTOP_DIR="$HOME/.local/share/applications"
APP_DESKTOP_FILE="$APP_DESKTOP_DIR/muhenkan-switch.desktop"
mkdir -p "$APP_DESKTOP_DIR"

# Icon= はアイコンがインストールされていればテーマから解決される
cat > "$APP_DESKTOP_FILE" << EOF
[Desktop Entry]
Type=Application
Name=muhenkan-switch
GenericName=キーボードカスタマイズ
Comment=無変換キーを活用するキーボードカスタマイズツール (kanata を自動管理)
Exec=$INSTALL_DIR/muhenkan-switch
Icon=muhenkan-switch
Terminal=false
Categories=Utility;
Keywords=keyboard;kanata;muhenkan;
EOF

chmod +x "$APP_DESKTOP_FILE"
echo "[OK] アプリランチャーに登録しました"
echo "     $APP_DESKTOP_FILE"

# ── 外部ツールの確認 ──
missing_tools=""
if [ "$XDG_SESSION_TYPE" = "wayland" ] || [ -n "$WAYLAND_DISPLAY" ]; then
    for tool in ydotool wl-paste notify-send; do
        if ! command -v "$tool" &>/dev/null; then
            missing_tools="$missing_tools $tool"
        fi
    done
    if [ -n "$missing_tools" ]; then
        echo ""
        echo "[WARNING] 以下の推奨ツールがインストールされていません:$missing_tools"
        echo "          一部の機能（キー入力シミュレーション・タイムスタンプ操作・通知）が動作しません。"
        echo ""
        echo "  sudo apt install ydotool wl-clipboard libnotify-bin"
        echo ""
    fi
else
    for tool in xdotool wmctrl xclip xprop notify-send; do
        if ! command -v "$tool" &>/dev/null; then
            missing_tools="$missing_tools $tool"
        fi
    done
    if [ -n "$missing_tools" ]; then
        echo ""
        echo "[WARNING] 以下の推奨ツールがインストールされていません:$missing_tools"
        echo "          一部の機能（アプリ切り替え・タイムスタンプ操作・通知）が動作しません。"
        echo ""
        echo "  sudo apt install xdotool wmctrl xclip x11-utils libnotify-bin"
        echo ""
    fi
fi

# ── uinput グループ設定の案内 ──
echo ""
echo "── uinput グループ設定 ──"
echo ""
echo "kanata を sudo なしで実行するには、以下のコマンドを実行してください:"
echo ""
echo "  sudo groupadd -f uinput"
echo "  sudo usermod -aG input \$USER"
echo "  sudo usermod -aG uinput \$USER"
echo ""
echo "  echo 'KERNEL==\"uinput\", MODE=\"0660\", GROUP=\"uinput\", OPTIONS+=\"static_node=uinput\"' \\"
echo "    | sudo tee /etc/udev/rules.d/99-uinput.rules"
echo ""
echo "  sudo udevadm control --reload-rules && sudo udevadm trigger"
echo ""
echo "  ※ 設定後、再ログインが必要です"

# ── 完了 ──
echo ""
echo "=== インストール完了 ==="
echo ""
echo "インストール先: $INSTALL_DIR"
echo ""
echo "使い方:"
echo "  1. ターミナルを再起動してください（PATH の反映）"
echo "  2. muhenkan-switch を起動してください"
echo "     ※ システムトレイに常駐し、kanata を自動管理します"
echo ""
echo "アンインストール: uninstall.sh を実行してください"
echo ""
