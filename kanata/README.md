# kanata 設定ファイル

## ファイル一覧

| ファイル | 対象OS | 状態 |
|---------|--------|------|
| `muhenkan.kbd` | Windows / Linux | 検証済み |
| `muhenkan-macos.kbd` | macOS | ⚠️ 未検証 |

## カスタマイズ

### tap-hold のタイミング調整

```lisp
;; デフォルト: 200ms
(defalias
  mh (tap-hold 200 200 muhenkan (layer-while-held mh-layer))
)
```

最初の `200` が tap のタイムアウト、次の `200` が hold の判定時間です。
短くすると反応が速くなりますが、誤判定が増えます。

### キーマッピングの追加・変更

`defsrc` にキーを追加し、`deflayer` の対応位置にアクションを記述してください。
kanata の設定ガイドは [こちら](https://github.com/jtroo/kanata/wiki/Configuration-guide)。
