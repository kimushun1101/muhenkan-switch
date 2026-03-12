#!/usr/bin/env bash
# Linux 用 Tauri ビルド依存ライブラリのインストール + uinput 設定案内
set -euo pipefail

if [ "$(uname)" != "Linux" ]; then
  echo "[setup] Not Linux — no system dependencies needed."
  exit 0
fi

# ── Tauri ビルド依存ライブラリ ──
echo "[setup] Installing Tauri build dependencies..."
if command -v apt-get >/dev/null 2>&1; then
  sudo apt-get update
  sudo apt-get install -y libwebkit2gtk-4.1-dev libsoup-3.0-dev \
    libjavascriptcoregtk-4.1-dev build-essential libssl-dev \
    libgtk-3-dev libayatana-appindicator3-dev librsvg2-dev \
    pkexec \
    wmctrl xdotool libnotify-bin
elif command -v dnf >/dev/null 2>&1; then
  sudo dnf install -y webkit2gtk4.1-devel libsoup3-devel \
    openssl-devel gtk3-devel libappindicator-gtk3-devel librsvg2-devel \
    wmctrl xdotool libnotify
elif command -v pacman >/dev/null 2>&1; then
  sudo pacman -S --needed webkit2gtk-4.1 libsoup3 \
    openssl gtk3 libayatana-appindicator librsvg \
    wmctrl xdotool libnotify
else
  echo "[setup] ERROR: Unsupported package manager. Please install manually:"
  echo "  libwebkit2gtk-4.1-dev, libsoup-3.0-dev, libgtk-3-dev,"
  echo "  libjavascriptcoregtk-4.1-dev, libssl-dev, librsvg2-dev,"
  echo "  wmctrl, xdotool, libnotify-bin"
  exit 1
fi

# ── kanata 用 uinput パーミッション案内 ──
echo ""
echo "[setup] Done."
echo ""
if id -nG "$USER" | grep -qw uinput; then
  echo "[setup] uinput グループ: 設定済み"
else
  cat << 'GUIDE'
[setup] kanata を sudo なしで実行するには、以下を実行して再ログインしてください:

  sudo groupadd -f uinput
  sudo usermod -aG input $USER
  sudo usermod -aG uinput $USER
  echo 'KERNEL=="uinput", MODE="0660", GROUP="uinput", OPTIONS+="static_node=uinput"' \
    | sudo tee /etc/udev/rules.d/99-uinput.rules
  sudo udevadm control --reload-rules && sudo udevadm trigger
GUIDE
fi
