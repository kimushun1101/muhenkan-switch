# Windows Defender 除外設定（開発者向け）

## 問題

`cargo clean` 後のフルビルドや `target/` 配下の `.exe` 実行時に、Windows のアプリケーション制御ポリシー（Windows Defender SmartScreen / WDAC）によりブロックされることがある。

```
Os { code: 4551, kind: Uncategorized, message: "このアプリは、システム管理者によってブロックされています。" }
```

## 原因

`target/debug/` や `target/release/` に生成される未署名の `.exe` が、Windows Defender のポリシーにより実行を拒否される。

## 除外設定（管理者権限 PowerShell）

```powershell
# target/ ディレクトリを除外に追加
Add-MpPreference -ExclusionPath "C:\Users\<ユーザー名>\repos\muhenkan-switch-rs\target"
```

> **注意:** 管理者権限の PowerShell で実行する必要がある。
> スタートメニュー → 「PowerShell」を検索 → 「管理者として実行」

### 設定の確認

```powershell
Get-MpPreference | Select-Object -ExpandProperty ExclusionPath
```

## 除外設定の解除

開発が終わったら、セキュリティのために除外を解除する。

```powershell
# target/ ディレクトリの除外を解除
Remove-MpPreference -ExclusionPath "C:\Users\<ユーザー名>\repos\muhenkan-switch-rs\target"
```

## 備考

- この問題は Windows Home エディションでも発生する（確認済み）
- 発生条件は環境により異なる（`cargo clean` 後のフルビルドで再現しやすい）
- CI/CD（GitHub Actions）では影響なし
