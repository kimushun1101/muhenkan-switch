# セットアップガイド

## インストール

### Windows

1. [最新リリース](https://github.com/kimushun1101/muhenkan-switch-rs/releases/latest) から
   `muhenkan-switch_x64-setup.exe` をダウンロード
2. ダブルクリックしてインストール
3. スタートメニューから `muhenkan-switch` を起動

> **PowerShell ワンライナーでのインストール:**
> ```powershell
> irm https://raw.githubusercontent.com/kimushun1101/muhenkan-switch-rs/main/scripts/install/get.ps1 | iex
> ```

### Linux / macOS

以下のコマンドをターミナルに貼り付けて実行するだけで、最新版のダウンロードからインストールまで自動で行われます。

```bash
curl -fsSL https://raw.githubusercontent.com/kimushun1101/muhenkan-switch-rs/main/scripts/install/get.sh | sh
```

> **セキュリティについて**: スクリプトの内容を事前に確認したい場合は、先にダウンロードしてから実行できます。
> ```bash
> curl -fsSL https://raw.githubusercontent.com/kimushun1101/muhenkan-switch-rs/main/scripts/install/get.sh -o get.sh
> less get.sh    # 内容を確認
> bash get.sh    # 実行
> ```

<details>
<summary>手動インストール（アーカイブをダウンロードする方法、Linux/macOS）</summary>

[Releases](https://github.com/kimushun1101/muhenkan-switch-rs/releases) から
お使いの OS 用のアーカイブをダウンロード・展開し、インストールスクリプトを実行してください。

```bash
# Linux
./install.sh

# macOS
./install-macos.sh
```

</details>

インストールスクリプト（Linux/macOS）は以下を自動で行います:
- kanata のダウンロード（GitHub Releases から）
- ファイルの配置（下記インストール先）
- PATH の設定（`~/.local/bin` にシンボリックリンク）
- アプリランチャー（Dock）への登録（Linux: `~/.local/share/applications/` に `.desktop` ファイルを作成）
- アイコンのインストール（Linux: `~/.local/share/icons/hicolor/128x128/apps/`）
- オプション: 自動起動の設定（Linux: XDG autostart、macOS: launchd）

### インストール先

| OS | インストール先 |
|----|--------------|
| Windows | `%LOCALAPPDATA%\muhenkan-switch` |
| Linux | `~/.local/share/muhenkan-switch-rs` |
| macOS | `~/Library/Application Support/muhenkan-switch-rs` |

## 起動

スタートメニューから `muhenkan-switch` を起動してください（Windows）。システムトレイに常駐し、kanata を自動管理します。

Linux ではアプリ一覧（Super キー）から `muhenkan-switch` を起動できます。ターミナルから `muhenkan-switch` を実行しても起動できます。
macOS ではターミナルから `muhenkan-switch` を実行してください。

無変換キーを押しながら H/J/K/L でカーソルが移動すれば成功です。

### Linux の外部ツール依存

一部の機能は外部ツールに依存しています。未インストールの場合はエラーメッセージでインストール方法が案内されます。

| ツール | 用途 | インストール (Ubuntu) |
|--------|------|----------------------|
| xdotool | キー入力シミュレーション、アプリ切り替え | `sudo apt install xdotool` |
| wmctrl | アプリ切り替え（xdotool のフォールバック） | `sudo apt install wmctrl` |
| xclip | ファイルマネージャのタイムスタンプ操作 | `sudo apt install xclip` |
| xprop | ファイルマネージャの前面ウィンドウ検出 | `sudo apt install x11-utils` |
| notify-send | トースト通知 | `sudo apt install libnotify-bin` |

まとめてインストール:
```bash
sudo apt install xdotool wmctrl xclip x11-utils libnotify-bin
```

### Linux の追加設定

sudo なしで実行するため、以下のグループ設定が必要です（インストールスクリプト実行時にも案内されます）:

```bash
sudo groupadd -f uinput
sudo usermod -aG input $USER
sudo usermod -aG uinput $USER

echo 'KERNEL=="uinput", MODE="0660", GROUP="uinput", OPTIONS+="static_node=uinput"' \
  | sudo tee /etc/udev/rules.d/99-uinput.rules

sudo udevadm control --reload-rules && sudo udevadm trigger
# 再ログインが必要
```

> **Wayland をお使いの場合（Ubuntu 22.04 以降のデフォルト）:**
> アプリ切り替え機能は **X11 セッションでのみ動作** します。
> Wayland ではセキュリティ上の制約により、外部ツールからのウィンドウ操作が制限されています。
> ログイン画面で **「Ubuntu on Xorg」** を選択して X11 セッションに切り替えてください。
> Vim風カーソル移動・Web検索・フォルダオープン等の他の機能は Wayland でも動作します。

## macOS をお使いの方へ

macOS 用の設定ファイル (`muhenkan-macos.kbd`) を同梱していますが、
開発者の検証環境がないため **動作未検証** です。
JIS配列 Mac での「英数」キーが kanata 上で `eisu` として認識される前提で
作成しています。動作報告や修正 PR を歓迎します。

macOS では [Karabiner-VirtualHIDDevice](https://github.com/pqrs-org/Karabiner-DriverKit-VirtualHIDDevice)
のインストールと `sudo` 実行が必要です。
詳細は [kanata リリースページ](https://github.com/jtroo/kanata/releases) の macOS 手順を参照してください。

## アンインストール

### Windows

**設定 → アプリ → muhenkan-switch → アンインストール** で削除できます。

### Linux / macOS

```bash
# Linux
~/.local/share/muhenkan-switch-rs/uninstall.sh

# macOS
~/Library/Application\ Support/muhenkan-switch-rs/uninstall-macos.sh
```

## 更新

### Windows

[最新リリース](https://github.com/kimushun1101/muhenkan-switch-rs/releases/latest) から
新しい `muhenkan-switch_x64-setup.exe` をダウンロードしてダブルクリックするだけで上書き更新されます。
アプリ起動中に自動更新チェックも行われます。

### Linux / macOS

```bash
# Linux
~/.local/share/muhenkan-switch-rs/update.sh

# macOS
~/Library/Application\ Support/muhenkan-switch-rs/update-macos.sh
```
