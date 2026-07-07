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

# ── GitHub API フォールバック用ヘルパー ──
# 未認証の GitHub API は 60 req/時/IP のレート制限があるため、通常はリダイレクト
# 経由 (下記) でタグを取得する。API はリダイレクト経路が失敗した場合のみ使う。
function Get-MuhenkanReleaseInfo {
    param([string]$Repo)
    try {
        return Invoke-RestMethod -Uri "https://api.github.com/repos/$Repo/releases/latest" -UseBasicParsing
    } catch {
        Write-Host "[ERROR] 最新バージョンの取得に失敗しました: $_" -ForegroundColor Red
        Write-Host "        ネットワーク接続を確認してください。" -ForegroundColor Red
        exit 1
    }
}

function Resolve-MuhenkanAsset {
    param($ReleaseInfo, [string]$Pattern)
    $found = $ReleaseInfo.assets | Where-Object { $_.name -like $Pattern } | Select-Object -First 1
    if (-not $found) {
        Write-Host "[ERROR] インストーラー ($Pattern) がリリースに見つかりませんでした。" -ForegroundColor Red
        exit 1
    }
    return $found
}

# ── 最新バージョンを取得 ──
# 1. releases/latest への HTTP リダイレクト先 (Location ヘッダ) からタグ名を取得する。
#    API 不要・レート制限なしの経路。AllowAutoRedirect を無効にすると、
#    HttpWebRequest はリダイレクト応答をそのまま返す (3xx は例外にならない)。
Write-Host "最新バージョンを確認しています..."

$latestTag = $null
try {
    $request = [System.Net.WebRequest]::Create("https://github.com/$REPO/releases/latest")
    $request.Method = "HEAD"
    $request.AllowAutoRedirect = $false
    $request.Timeout = 10000
    $response = $request.GetResponse()
    $location = $response.Headers["Location"]
    $response.Close()
} catch {
    $location = $null
}

if ($location -and ($location -match '/releases/tag/(v[0-9][^/]+)$')) {
    $latestTag = $Matches[1]
}

$releaseInfo = $null

if ($latestTag) {
    Write-Host "最新バージョン: $latestTag"
    # NSIS 既定の命名規則 (<productName>_<version>_x64-setup.exe) からアセット名を予測する。
    $versionNumber = $latestTag -replace '^v', ''
    $ASSET_NAME = "muhenkan-switch_${versionNumber}_x64-setup.exe"
    $downloadUrl = "https://github.com/$REPO/releases/latest/download/$ASSET_NAME"
} else {
    # 2. フォールバック: GitHub API (未認証 60 req/時/IP のレート制限あり)
    Write-Host "[WARN] リダイレクトでのバージョン取得に失敗したため GitHub API を使用します。" -ForegroundColor Yellow
    $releaseInfo = Get-MuhenkanReleaseInfo -Repo $REPO
    $latestTag = $releaseInfo.tag_name
    Write-Host "最新バージョン: $latestTag"

    $asset = Resolve-MuhenkanAsset -ReleaseInfo $releaseInfo -Pattern $ASSET_PATTERN
    $ASSET_NAME = $asset.name
    $downloadUrl = $asset.browser_download_url
}

# ── ダウンロード ──
Write-Host ""
Write-Host "$ASSET_NAME をダウンロードしています..." -ForegroundColor Cyan

$tempExe = Join-Path $env:TEMP $ASSET_NAME

try {
    Invoke-WebRequest -Uri $downloadUrl -OutFile $tempExe -UseBasicParsing
    Write-Host "[OK] ダウンロード完了" -ForegroundColor Green
} catch {
    if (-not $releaseInfo) {
        # 予測したアセット名が実際には存在しなかった可能性があるため、
        # GitHub API で正確なアセット情報を取得して 1 度だけ再試行する。
        Write-Host "[WARN] 想定アセットのダウンロードに失敗したため GitHub API で確認します..." -ForegroundColor Yellow
        $releaseInfo = Get-MuhenkanReleaseInfo -Repo $REPO
        $asset = Resolve-MuhenkanAsset -ReleaseInfo $releaseInfo -Pattern $ASSET_PATTERN
        $ASSET_NAME = $asset.name
        $downloadUrl = $asset.browser_download_url
        $tempExe = Join-Path $env:TEMP $ASSET_NAME

        try {
            Invoke-WebRequest -Uri $downloadUrl -OutFile $tempExe -UseBasicParsing
            Write-Host "[OK] ダウンロード完了" -ForegroundColor Green
        } catch {
            Write-Host "[ERROR] ダウンロードに失敗しました: $_" -ForegroundColor Red
            exit 1
        }
    } else {
        Write-Host "[ERROR] ダウンロードに失敗しました: $_" -ForegroundColor Red
        exit 1
    }
}

# ── インストール (サイレント) ──
Write-Host ""
Write-Host "インストールしています..." -ForegroundColor Cyan

# 起動中のインスタンスがあるとファイル上書きに失敗するため停止（更新時）。
# Windows では Job Object により kanata も併せて終了する。
Get-Process muhenkan-switch -ErrorAction SilentlyContinue | ForEach-Object {
    try {
        $_.Kill()
        [void]$_.WaitForExit(5000)
    } catch {
        # 既に終了している等で Kill が失敗しても、以降のインストール処理は続行する
        Write-Verbose "既存プロセスの終了に失敗しました: $_"
    }
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

# ── 今すぐ起動（オプション）──
# インストール先 exe を特定（既定は per-user NSIS。念のため per-machine もフォールバック）
$installedExe = Join-Path $env:LOCALAPPDATA "muhenkan-switch\muhenkan-switch.exe"
if (-not (Test-Path $installedExe)) {
    $pfExe = Join-Path $env:ProgramFiles "muhenkan-switch\muhenkan-switch.exe"
    if (Test-Path $pfExe) { $installedExe = $pfExe }
}

Write-Host ""
$startNow = Read-Host "muhenkan-switch を今すぐ起動しますか？ (y/N)"
if ($startNow -eq "y" -or $startNow -eq "Y") {
    if (Test-Path $installedExe) {
        Start-Process -FilePath $installedExe
        Write-Host "[OK] muhenkan-switch を起動しました" -ForegroundColor Green
    } else {
        Write-Host "[WARN] 実行ファイルが見つかりませんでした。スタートメニューから起動してください。" -ForegroundColor Yellow
    }
}

# ── 完了 ──
Write-Host ""
Write-Host "=== インストール完了 ===" -ForegroundColor Green
Write-Host ""
Write-Host "muhenkan-switch はシステムトレイに常駐します（ウィンドウを閉じても終了しません）。" -ForegroundColor Cyan
Write-Host "スタートメニューから起動できます。" -ForegroundColor Cyan
Write-Host ""
