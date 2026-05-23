# カスタマイズガイド

muhenkan-switch のカスタマイズは 2 つのレイヤーに分かれています。

| レイヤー | ファイル | 想定ユーザー | 編集手段 |
|----------|---------|--------------|----------|
| 検索 URL / アプリ名 / フォルダパス / キー割り当て | `config.toml` | 一般 | GUI 推奨（直接編集も可） |
| キーマッピング本体（起動キー、配列、tap-hold 等） | `muhenkan.kbd` | 上級者 | テキストエディタで直接編集 |

GUI で完結するカスタマイズは前者だけです。後者は kanata の構文知識が前提となります。

## 設定ファイルの場所

| OS | 場所 |
|----|------|
| Windows | `%LOCALAPPDATA%\muhenkan-switch\` |
| Linux | `~/.local/share/muhenkan-switch/` |
| macOS | `~/Library/Application Support/muhenkan-switch/` |

このディレクトリに `config.toml` と `muhenkan.kbd`（macOS は `muhenkan-macos.kbd`）があります。

## config.toml の変更

検索エンジン URL、アプリ名、フォルダパス、ディスパッチキーの割り当てを変更できます。GUI（システムトレイ → 設定）から編集するのが推奨です。

直接編集する場合は、保存後に GUI から kanata を再起動してください（kanata は config.toml の変更も即時には反映しません）。

### デフォルトのキー割り当て

無変換キーと同時押しで以下のアクションが発動します（`config.toml` で自由に変更可能）。

| キー | 種別 | デフォルト割り当て |
|------|------|------------------|
| 1 | フォルダ | ~ (Home) |
| 2 | フォルダ | ~/Desktop |
| 3 | フォルダ | ~/Documents |
| 4 | フォルダ | ~/Downloads |
| 5 | フォルダ | ~/proj（カスタマイズ推奨） |
| q | 検索 | Question (ChatGPT) |
| w | 検索 | Web翻訳 (Google 翻訳) |
| e | 検索 | 英語辞典 (Weblio) |
| r | 検索 | 類語辞典 (Weblio) |
| g | 検索 | Google |
| a | アプリ | エディタ (VS Code) |
| s | アプリ | チャット (Slack) |
| d | アプリ | Document (OneNote) |
| f | アプリ | ブラウザ (Firefox) |
| t | アプリ | Terminal |

`config.toml` のコメントに設定例を記載しています。

### 句読点スタイル

`config.toml` の `punctuation_style` で 4 パターンから選択できます（GUI からも変更可能）。

| 値 | カンマ | ピリオド |
|----|--------|----------|
| `JapaneseTouten` | 、 | 。 |
| `WesternStyle` | ， | ． |
| `WesternComma` | ， | 。 |
| `WesternPeriod` | 、 | ． |

## muhenkan.kbd の変更（上級者向け）

`muhenkan.kbd` は [kanata](https://github.com/jtroo/kanata) の設定ファイルです。起動キーの変更、配列の組み替え、tap-hold 閾値の調整など、`config.toml` では対応できないカスタマイズが可能ですが、kanata の構文知識が前提となります。

### 注意事項

- **構文エラーで kanata が起動しなくなります** — 編集後は GUI のログ等で起動状態を確認してください
- **アップデート時に上書きされる可能性があります** — 差分はバックアップを取ってください
- **編集後は kanata の再起動が必要です** — kanata は `.kbd` ファイルの変更を自動検知しません。GUI のメニューから kanata を再起動してください（参照: [docs/design.md — kanata プロセス管理](design.md#kanata-プロセス管理)）

### ファイル構造

```
defcfg     ;; kanata 全体設定
defsrc     ;; 監視対象キー
defalias   ;; エイリアス（tap-hold 設定、dispatch コマンド等）
deflayer default   ;; 通常レイヤー（無変換キーだけ tap-hold 化）
deflayer mh-layer  ;; 無変換キー押下中レイヤー（実際のショートカット定義）
```

`deflayer mh-layer` の各位置は `defsrc` の並びと 1:1 対応します。位置を入れ替えるときは両方を揃えて編集してください。

### 利用シーン

#### 1. 起動キーを変更する

無変換キー以外（例: 「変換」「カタカナひらがな」キー）を起動キーにしたい場合。`defsrc` の `muhenkan` と `defalias mh` 内の `muhenkan` を別のキー名に置き換えます。

OS によって kanata でのキー名が異なります（[docs/design.md — 無変換キーのOS間対応](design.md#無変換キーのos間対応) 参照）。

#### 2. Vim 風カーソル配置を変える

H/J/K/L 以外の配置にしたい場合（例: 矢印キーに近い E/S/D/F）。`deflayer mh-layer` の対応する位置で `left` `down` `up` `right` を入れ替えます。同時に `defsrc` と `deflayer default` のキー順も合わせる必要があります。

#### 3. tap-hold 閾値を調整する

無変換キーの単押し/長押し判定はデフォルト 200ms。誤動作（押しっぱなしのつもりが単押しと判定される、等）が多い場合は `defalias mh` の `(tap-hold 200 200 muhenkan ...)` の数値を 150〜300 の範囲で調整してください。

#### 4. ディスパッチ対象キーを追加する

P や ` 等もカスタムアクション化したい場合、以下 3 箇所の編集が必要です。

1. `defsrc` にキーを追加
2. `defalias` に `dsp-p (cmd muhenkan-switch-core dispatch p)` のような dispatch エイリアスを追加
3. `deflayer mh-layer` の対応位置に `@dsp-p` を配置

対応するアクションは `config.toml` 側で `key = "p"` として設定します。

#### 5. 右手の固定アクションを変える

カーソル移動 / 単語移動 / 削除 / ESC / 句読点は `deflayer mh-layer` でハードコードされています。`bspc` ↔ `del` の入れ替え、句読点を `punctuation_style` の 4 パターン以外にしたい、等の用途で編集します。

固定アクションと dispatch 対象キーの区別は [docs/design.md — キー割り当ての設計思想](design.md#キー割り当ての設計思想) を参照してください。

### kanata 設定の詳細

kanata の構文、アクション、レイヤー定義の詳細は公式ガイドを参照してください。

- [kanata Configuration Guide](https://github.com/jtroo/kanata/wiki/Configuration-guide)

## 関連設定

### CapsLock → Ctrl リマップ

muhenkan-switch（kanata）では提供していません。OS ごとの専用機構を使ってください。

| OS | 方法 |
|----|------|
| Windows | [Ctrl2Cap](https://learn.microsoft.com/sysinternals/downloads/ctrl2cap) または [PowerToys](https://learn.microsoft.com/windows/powertoys/) の Keyboard Manager |
| Linux | `gsettings set org.gnome.desktop.input-sources xkb-options "['ctrl:nocaps']"`（GNOME の場合） |
| macOS | システム環境設定 → キーボード → 修飾キー |

理由は [docs/design.md — CapsLock → Ctrl リマップを kanata で行わない理由](design.md#capslock--ctrl-リマップを-kanata-で行わない理由) を参照してください。
