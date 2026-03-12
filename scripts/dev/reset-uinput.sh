#!/usr/bin/env bash
# uinput パーミッション設定をリセット（再テスト用）
set -euo pipefail

echo "Resetting uinput configuration..."
echo ""
echo "以下の操作を行います:"
echo "  1. /etc/udev/rules.d/99-uinput.rules を削除"
echo "  2. $USER を input/uinput グループから除去"
echo "  3. udev ルールをリロード"
echo ""
read -rp "続行しますか？ (y/N): " confirm
if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
  echo "中止しました。"
  exit 0
fi

sudo rm -f /etc/udev/rules.d/99-uinput.rules
sudo gpasswd -d "$USER" input 2>/dev/null || true
sudo gpasswd -d "$USER" uinput 2>/dev/null || true
sudo udevadm control --reload-rules && sudo udevadm trigger

echo ""
echo "Done. 再ログインすると uinput 設定がリセットされます。"
echo "再ログイン後に mise run dev を起動すると pkexec ダイアログが表示されます。"
