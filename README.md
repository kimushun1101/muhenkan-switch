# 無変換スイッチ

`無変換キー`と他のキーを同時押しすることで様々な動作ができるようになります。
`無変換キー`単体は`無変換キー`として効きます。
現状の機能を消すことなく、覚えやすさを重視してキーボードショートカットを配置しました。

## インストール
1. [GitHub のリリース](https://github.com/kimushun1101/muhenkan-switch/releases)から`muhenkan-switch.zip` をダウンロード。
2. ユーザの書き込み権限があるところに展開。  
(例えば`C:\Users\ユーザ名` 以下であればお好みのフォルダの中に入れられます。入れては行けない場所としては`C:\Program Files` 以下など。)
3. `muhenkan.exe` を実行。設定画面を閉じた後もソフトバックグラウンドで実行され続けます。終了は[設定画面](#設定変更)から可能です。

## 使い方
初期設定は以下の通りです。

![キーボードショートカット](img/keyboard.png) 
- `無変換キー`+`左手`（右手はマウスを操作していることを想定）
  - (緑) `F1`: [設定の変更](#設定変更) を行うウィンドウを表示
  - (黄) 数字キー→エクスプローラーでフォルダを開く
    - `1`: ドキュメント
    - `2`: ダウンロード
    - `3`: デスクトップ
    - `4`: OneDrive
    - `5`: ごみ箱
  - (橙) 左手上段→選択文字列を検索
    - `Q`: 英単語検索
    - `R`: 類語辞典
    - `T`: 翻訳（Translator）
    - `G`: Web 検索
  - (赤) 左手中段→ソフトを最前面に出す
    - `A`: エディタ
    - `W`: ワード
    - `E`: Eメール
    - `S`: スライド（パワーポイント）
    - `D`: PDF ビューア（ドキュメント閲覧）
    - `F`: ブラウザ
  - (紫) 左手下段→ファイルの操作
    - `C`: コピーして、新しくできたファイルの名前に最後に編集した日付のタイムスタンプ貼り付け
    - `X`: タイムスタンプの切り取り
- (青) `無変換キー`+`右手`（両手がホームポジションにあることを想定）
  - `H`, `J`, `K`, `L`: 1文字カーソル移動
  - `U`, `I`: 単語で左右カーソル移動
  - `Y`, `O`: Home、End カーソル移動
  - `N`, `M`, `;` BackSpace, Delete, Esc
  - `,`, `.` カンマピリオドで句読点(、, 。) を入力（IMEで`．`と`，`にセットしている人は助かるかも） 
- 上記のルールから外れるもの
  - `無変換キー`+`V`: 書式なしで貼り付け
  - `無変換キー`+`P`: ウィンドウをプリントスクリーンして，そのファイルを保存，そのフォルダを開く
  - 下表に示す文字列入力後にEnter やSpace キーなどを押すとその文字が置換されます。

| 入力文字列  | 置換入力例      | 
| ---------- | -------------- | 
| ;date      | 20230225       | 
| ;dateu     | 2023_0225      | 
| ;dates     | 2023/02/25     | 
| ;dated     | 2023.02.25     | 
| ;time      | 1605           | 
| ;timec     | 16:06          | 
| ;datetime  | 20230225_1602  | 

### 選択文字列を検索
![選択文字列を検索](img/text2web.gif)

### ソフトを最前面に出す(ソフトの切り替え)
![ソフトの切り替え](img/activeapp.gif)

## キーの覚え方
- Web サイトやソフトはおおよそ推測できる割当になっているかと思います。例外としては以下のとおりです。
  - 英単語=`Q` はQuestion から連想します。
  - エディタ=`A` はAtom を使っていたからです。
  - ブラウザ=`F` はFireFox を使っていたからです。
- タイムスタンプの操作=`XCV` は、切り取り、コピー、ペーストなどを連想して覚えてください。
- カーソル移動=`HJKL` はVim 準拠
- カーソル移動=`YUIO` はキーの位置と横移動の大きさを関連付けています。
- 文字消去=`NM` は両方とも人差し指で操作する。位置関係はカーソルが動く方向に対応しています。

## 設定変更
![設定画面](img/config.png)

`無変換キー`+`F1` で設定画面が開き、設定の確認と変更ができます。
- 起動時の動作：チェックボックスにチェックを入れていると有効になります。
- タイムスタンプ：フォーマットと位置を編集できます。
- ウェブサイト：ドロップダウンリストから選択できます。好みのウェブサイトが選択肢にない場合には追加しますので教えてください。
- フォルダ：テキストボックスは好みに合わせて変更可能です。パスはクリックすると変更できます。
- ソフトウェア：テキストボックスは好みに合わせて変更可能です。ソフトをクリックすると、現在起動中のソフトの一覧がでて、そこから変更したいソフトを選ぶことができます。
- 適用：現在表示している内容に設定を変更します。上記を変更しただけでは設定の反映はされません。
- 現在の設定に戻す：設定画面上の変更をリセットして現在の設定項目に直します。
- メニューバーのファイル：バックアップの作成と読み込み、初期設定へ戻すことができます。また、このソフトの終了もここから行えます。
- メニューバーのヘルプ：この説明を見ることができます。また、このソフトの最新版がリリースされているか確認できます。

## アンイストール
1. `無変換キー`+`F1` の設定画面からファイル→終了。ソフトがあるファイルを開くか聞かれるのではい（Yes）を選択。
2. 開いた場所をフォルダごと削除。

---

## ライセンス
公式のサンプルを参考にしているため、GNU GPLv2 とします。  
AutoHotKey : [https://www.autohotkey.com/docs/v2/license.htm](https://www.autohotkey.com/docs/v2/license.htm)
