# Antigravity を Dドライブへ移動するスクリプト
# 管理者権限で実行してください

$ErrorActionPreference = "Stop"

$SourcePath = "$env:LOCALAPPDATA\Programs\Antigravity"
$DestPath   = "D:\Antigravity"
$DesktopLnk = [IO.Path]::Combine([Environment]::GetFolderPath("Desktop"), "Antigravity.lnk")

function Log($msg, $col="Cyan")   { Write-Host "[INFO] $msg" -ForegroundColor $col }
function Ok($msg)                  { Write-Host "[OK]   $msg" -ForegroundColor Green }
function Err($msg)                 { Write-Host "[ERR]  $msg" -ForegroundColor Red }

# ── 1. 全プロセスを強制終了 ──────────────────────────────
Log "Antigravity / Code プロセスを停止中..."
$procs = @("Antigravity","Code","node","electron")
foreach ($p in $procs) {
    Get-Process -Name $p -ErrorAction SilentlyContinue | Stop-Process -Force
}
Start-Sleep -Seconds 2
Ok "プロセスを停止しました。"

# ── 2. Dドライブ確認 ─────────────────────────────────────
if (-not (Test-Path "D:\")) {
    Err "Dドライブが見つかりません。"; exit 1
}

# ── 3. コピー先作成 ──────────────────────────────────────
Log "コピー先を準備中: $DestPath"
if (Test-Path $DestPath) {
    $backup = "D:\Antigravity_bak_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    Log "既存フォルダをバックアップ: $backup"
    Rename-Item $DestPath $backup -Force
}
New-Item -ItemType Directory -Path $DestPath -Force | Out-Null
Ok "フォルダを作成しました。"

# ── 4. ファイルをコピー ──────────────────────────────────
if (-not (Test-Path $SourcePath)) {
    Err "コピー元が見つかりません: $SourcePath"
    Log "Antigravityが別の場所にある場合は変数 `$SourcePath を書き換えてください。"
    exit 1
}
Log "ファイルをコピー中（時間がかかる場合があります）..."
try {
    Copy-Item -Path "$SourcePath\*" -Destination $DestPath -Recurse -Force
    Ok "コピー完了: $DestPath"
} catch {
    Err "コピーに失敗しました: $_"; exit 1
}

# ── 5. デスクトップショートカット作成 ────────────────────
Log "デスクトップアイコンを作成中..."
$exeCandidates = @(
    "$DestPath\Antigravity.exe",
    "$DestPath\antigravity.exe",
    "$DestPath\Code.exe",
    (Get-ChildItem $DestPath -Filter "*.exe" -ErrorAction SilentlyContinue | Select-Object -First 1).FullName
)
$exePath = $exeCandidates | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1

if ($exePath) {
    $shell = New-Object -ComObject WScript.Shell
    $lnk = $shell.CreateShortcut($DesktopLnk)
    $lnk.TargetPath = $exePath
    $lnk.WorkingDirectory = $DestPath
    $lnk.Description = "Antigravity (D:\)"
    $lnk.IconLocation = "$exePath, 0"
    $lnk.Save()
    Ok "デスクトップアイコン作成: $DesktopLnk"
} else {
    Log "EXEが見つからないためショートカットをスキップしました。手動で $DestPath を確認してください。" "Yellow"
}

# ── 6. C:の旧フォルダ削除確認 ────────────────────────────
Write-Host ""
$del = Read-Host "C:の元フォルダ ($SourcePath) を削除しますか？ (y/N)"
if ($del -match "^[yY]") {
    try {
        Remove-Item -Path $SourcePath -Recurse -Force
        Ok "削除完了: $SourcePath"
    } catch {
        Err "削除に失敗しました（手動で削除してください）: $_"
    }
} else {
    Log "元フォルダはそのまま残します。"
}

# ── 完了 ─────────────────────────────────────────────────
Write-Host ""
Write-Host "==========================================" -ForegroundColor Green
Write-Host "  完了！Antigravity を D:\ に移動しました" -ForegroundColor Green
Write-Host "  起動: $exePath"                          -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
Write-Host ""
$open = Read-Host "今すぐ Antigravity を起動しますか？ (y/N)"
if ($open -match "^[yY]" -and $exePath) { Start-Process $exePath }
