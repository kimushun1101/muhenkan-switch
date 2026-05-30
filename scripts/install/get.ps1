<#
.SYNOPSIS
    muhenkan-switch ワンライナーインストーラー (Windows)
.DESCRIPTION
    GitHub Releases から最新の setup.exe をダウンロードし、実行します。
.NOTES
    使い方:
    irm https://raw.githubusercontent.com/kimushun1101/muhenkan-switch/main/scripts/install/get.ps1 | iex
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ── 設定 ──
$REPO = "kimushun1101/muhenkan-switch"
# NSIS インストーラーはバージョン番号入りの名前
# (例: muhenkan-switch_0.11.4_x64-setup.exe) で公開されるため、
# 固定名で決め打ちせずリリース情報から該当アセットを探す。
$ASSET_PATTERN = "*_x64-setup.exe"

Write-Host ""
Write-Host "=== muhenkan-switch インストーラー (Windows) ===" -ForegroundColor Cyan
Write-Host ""

# ── TLS 1.2 を有効化 ──
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# ── 最新バージョンを取得 ──
Write-Host "最新バージョンを確認しています..."
try {
    $releaseInfo = Invoke-RestMethod -Uri "https://api.github.com/repos/$REPO/releases/latest" -UseBasicParsing
    $latestTag = $releaseInfo.tag_name
} catch {
    Write-Host "[ERROR] 最新バージョンの取得に失敗しました: $_" -ForegroundColor Red
    Write-Host "        ネットワーク接続を確認してください。" -ForegroundColor Red
    exit 1
}

Write-Host "最新バージョン: $latestTag"

# ── ダウンロードする setup.exe を特定 ──
$asset = $releaseInfo.assets | Where-Object { $_.name -like $ASSET_PATTERN } | Select-Object -First 1
if (-not $asset) {
    Write-Host "[ERROR] インストーラー ($ASSET_PATTERN) がリリースに見つかりませんでした。" -ForegroundColor Red
    exit 1
}
$ASSET_NAME = $asset.name
$downloadUrl = $asset.browser_download_url

# ── ダウンロード ──
Write-Host ""
Write-Host "$ASSET_NAME をダウンロードしています..." -ForegroundColor Cyan

$tempExe = Join-Path $env:TEMP $ASSET_NAME

try {
    Invoke-WebRequest -Uri $downloadUrl -OutFile $tempExe -UseBasicParsing
    Write-Host "[OK] ダウンロード完了" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] ダウンロードに失敗しました: $_" -ForegroundColor Red
    exit 1
}

# ── インストール (サイレント) ──
Write-Host ""
Write-Host "インストールしています..." -ForegroundColor Cyan

# 起動中のインスタンスがあるとファイル上書きに失敗するため停止（更新時）。
# Windows では Job Object により kanata も併せて終了する。
Get-Process muhenkan-switch -ErrorAction SilentlyContinue | ForEach-Object {
    try { $_.Kill(); [void]$_.WaitForExit(5000) } catch {}
}

# /S = サイレントインストール。
# 対話ウィザードのままだと完了ボタン待ちでスクリプトが停止するため、
# NSIS のサイレントフラグで非対話インストールする。
$proc = Start-Process -FilePath $tempExe -ArgumentList "/S" -Wait -PassThru
if ($proc.ExitCode -ne 0) {
    Write-Host "[ERROR] インストールに失敗しました (終了コード: $($proc.ExitCode))" -ForegroundColor Red
    if (Test-Path $tempExe) { Remove-Item $tempExe -Force -ErrorAction SilentlyContinue }
    exit 1
}

# ── クリーンアップ ──
if (Test-Path $tempExe) { Remove-Item $tempExe -Force -ErrorAction SilentlyContinue }

Write-Host "[OK] インストール完了" -ForegroundColor Green
Write-Host ""
Write-Host "=== セットアップ完了 ===" -ForegroundColor Green
Write-Host "スタートメニューから muhenkan-switch を起動してください。" -ForegroundColor Cyan
Write-Host ""
