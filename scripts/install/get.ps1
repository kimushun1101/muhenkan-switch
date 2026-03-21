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
$ASSET_NAME = "muhenkan-switch_x64-setup.exe"

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

# ── ダウンロード ──
Write-Host ""
Write-Host "$latestTag をダウンロードしています..." -ForegroundColor Cyan

$downloadUrl = "https://github.com/$REPO/releases/download/$latestTag/$ASSET_NAME"
$tempExe = Join-Path $env:TEMP $ASSET_NAME

try {
    Invoke-WebRequest -Uri $downloadUrl -OutFile $tempExe -UseBasicParsing
    Write-Host "[OK] ダウンロード完了" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] ダウンロードに失敗しました: $_" -ForegroundColor Red
    exit 1
}

# ── setup.exe を実行 ──
Write-Host ""
Write-Host "インストーラーを起動しています..." -ForegroundColor Cyan
Start-Process -FilePath $tempExe -Wait

# ── クリーンアップ ──
if (Test-Path $tempExe) { Remove-Item $tempExe -Force -ErrorAction SilentlyContinue }

Write-Host ""
Write-Host "=== インストール完了 ===" -ForegroundColor Green
Write-Host ""
