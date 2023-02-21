# muhenkan-switch

`無変換キー`と他のキーを同時押しすることで様々な動作ができるようになります。
`無変換キー`単体は`無変換キー`として効きます。
現状の機能を消すことなく、覚えやすさを重視してキーボードショートカットを配置しました。

## できること
![キーボードショートカット](img/keyboard.png) 

- (青)`無変換キー`+`右手`（両手がホームポジションにあることを想定）
  - `H`, `J`, `K`, `L`: 1文字カーソル移動
  - `U`, `I`: 単語で左右カーソル移動
  - `Y`, `O`: Home、End カーソル移動
  - `N`, `M`, `.` BackSpace, Delete, Esc
- `無変換キー`+`左手`（右手はマウスを操作していることを想定）
  - (黄色)数字キー→エクスプローラーでフォルダを開く ***【設定変更可能】***
    - `1`: ドキュメント
    - `2`: ダウンロード
    - `3`: デスクトップ
    - `4`: OneDrive
    - `5`: ごみ箱
  - (オレンジ)左手上段→選択文字列を検索 ***【設定変更可能】***
    - `Q`: 英単語検索、Weblio英和和英辞典
    - `R`: 類語辞典、Weblio類語辞典
    - `T`: 翻訳、DeepL Translator
    - `G`: Web 検索、Google 検索
  - (赤)左手中段→ソフトを最前面に出す ***【設定変更可能】***
    - `A`: エディタ、VS Code
    - `W`: ワード、Microsoft Word
    - `E`: Eメール、Microsoft Outlook
    - `S`: スライド作成、PowerPoint
    - `D`: ドキュメント閲覧、Adbee Acrobot Reader
    - `F`: ブラウザ、Google Chrome
  - (紫)左手下段→ファイルの操作
    - `V`: ファイル名に最後に編集した日付のタイムスタンプを貼り付け
    - `C`: コピーして、新しくできたファイルの名前に最後に編集した日付のタイムスタンプ貼り付け
    - `X`: 上記で付加したタイムスタンプ切り取り
    - `Z`: タイムスタンプの位置を前に
    - `B`: タイムスタンプの位置を後ろに
- (緑)上記のルールから外れるもの
  - `無変換キー`+`P` : PrintScreen、Alt と一緒に押すことも多いので両手をつかってもよいかなと。
  - `Ctrl` + `Shift` + `V` : 書式なしで貼り付け（エディタソフトは除く）
  - `無変換キー`+`ファンクションキー` : で本スクリプトの便利ショートカット
    - `F1`: 現在の設定とキー配置の画像を表示
    - `F2`: 設定の変更を行うウィンドウを表示
    - `F3`: 最前面のソフト（エクスプローラーの場合はフォルダ）をショートカットキーに割り当て
    - `F4`: スクリプトの終了→スクリプトの保存じているフォルダを開く
    - `F5`: スクリプトを保存して、新しい設定をリロード

## キーの覚え方
- カーソル移動=`HJKL` はVim 準拠
- カーソル移動=`YUIO` はキーの位置と横移動の大きさを関連付けています。
- 文字消去=`NM` は両方とも人差し指で操作する。位置関係はカーソルが動く方向に対応しています。
- `Esc`=`.` は終了を意味することから連想しています。
- Web サイトやソフトはおおよそ推測できる割当になっているかと思います。例外としては以下のとおりです。
  - 英単語=`Q` はQuestion から連想します。
  - エディタ=`A` はAtom を使っていたからです。
  - ブラウザ=`F` はFireFox を使っていたからです。
- タイムスタンプの操作=`XCV` は、切り取り、コピー、ペーストなどを連想して覚えてください。
- タイムスタンプ位置の変更=`ZB` は、`Z`(左=ファイル名の前)`B`(右=ファイル名の後) という具合で位置に対応。

## 選択文字列を検索
![選択文字列を検索](img/text2web.gif)

### ソフトを最前面に出す(ソフトの切り替え)
![ソフトの切り替え](img/activeapp.gif)

## 導入方法
![設定画面](img/config.png)
1. `AutoHotKey\muhenkan.exe` を実行する。
2. `無変換キー`+`F2` で設定を確認して、好みの設定に変更。
  - 自動起動ON に切り替えるとWindows 立ち上げ時にこのソフトが自動起動するようになります。
  - 好みのウェブサイトが選択肢にない場合には追加しますので教えていただけますと幸いです。
  - フォルダはパスをクリックして編集することができますが、エクスプローラを最前面に出して`無変換キー`+`F3` で変更することもできます。
  - 設定画面上では変更できません。設定したいソフトウェアを最前面に出して`無変換キー`+`F3` で変更してください。
  - 設定ファイルは以下の3つを選択肢として用意しております。
    - `conf.ini` : 起動時の設定。`設定の適用` を押すと現在の項目が保存されて再起動されます。
    - `backup.ini` : 個人的な設定をバックアップするために使います。Git の追跡から外しております。他の名前で作りたい場合には`Another File` を選択してください。
    - `default.ini` : 初期設定。`読込` のみ可能で、このファイルの書き換えはできないようにしています。

## ソースコードを編集したい場合
1. https://www.autohotkey.com/ ここのDownload からv2.0 を選択してインストール
2. `muhenkan.ahk` を編集して実行
3. デバッグには`無変換キー`+`F5` が便利
4. AutoHotkey ソフトを立ち上げ、AutoHotKeyDash のCompile からexe ファイルを作成可能

## 設定を戻す・アンイストール
お好みの状態まで段階的に戻せます。
1. 自動起動を停止：`無変換キー`+`F2 キー` から設定
2. スクリプトの停止：`無変換キー`+`F4 キー` を押下
3. AutoHotKey 自体のアンイストール：Windows の設定→アプリと機能からAutoHotKeyを選択してアンイストール

---

## ライセンス
公式のサンプルを参考にしているため、GNU GPLv2 とします。
- AutoHotKey : https://www.autohotkey.com/docs/v2/license.htm
