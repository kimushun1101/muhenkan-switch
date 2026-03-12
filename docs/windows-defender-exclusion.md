# Windows Defender 除外設定（開発者向け）

## 問題

ビルド後の `.exe` 実行時に、Windows Defender のリアルタイム保護により以下の問題が発生することがある。

- **ビルドエラー**: `cargo clean` 後のフルビルドで `target/` 内の exe がブロックされる
  ```
  Os { code: 4551, kind: Uncategorized, message: "このアプリは、システム管理者によってブロックされています。" }
  ```
- **実行エラー**: `mise run dev` で `bin/` にコピーした exe の実行が間欠的に失敗する
  ```
  ./bin/muhenkan-switch.exe: Permission denied
  ```

## 原因

Windows Defender のリアルタイム保護が、新しく生成・コピーされた未署名の `.exe` をスキャンし、一時的にロックする。スキャン完了前にビルドや実行が進むと Permission denied になる。

## 除外設定（管理者権限 PowerShell）

リポジトリのルートディレクトリごと除外するのが簡単。

```powershell
# リポジトリを除外に追加
Add-MpPreference -ExclusionPath "C:\Users\<ユーザー名>\repos\muhenkan-switch-rs"
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
# 除外を解除
Remove-MpPreference -ExclusionPath "C:\Users\<ユーザー名>\repos\muhenkan-switch-rs"
```

## 備考

- この問題は Windows Home エディションでも発生する（確認済み）
- `target/` のビルドエラーと `bin/` の実行エラーは同じ原因（リアルタイムスキャン）
- `bin/` の Permission denied は間欠的に発生し、リトライすると成功することが多い
- CI/CD（GitHub Actions）では影響なし
