# web-automation-toolkit Dドライブセットアップスクリプト
# 管理者権限なしで実行可能

$ErrorActionPreference = "Stop"
$DestDir = "D:\web-automation-toolkit"
$RepoUrl = "https://github.com/fortuneadventure-sketch/web-automation-toolkit.git"
$DesktopPath = [Environment]::GetFolderPath("Desktop")
$ShortcutPath = Join-Path $DesktopPath "web-automation-toolkit.lnk"
$IndexFile = Join-Path $DestDir "index.html"

function Write-Status {
    param([string]$Message, [string]$Color = "Cyan")
    Write-Host "[INFO] $Message" -ForegroundColor $Color
}

function Write-Success {
    param([string]$Message)
    Write-Host "[OK]   $Message" -ForegroundColor Green
}

function Write-Err {
    param([string]$Message)
    Write-Host "[ERR]  $Message" -ForegroundColor Red
}

# --- Dドライブ存在確認 ---
Write-Status "Dドライブの確認中..."
if (-not (Test-Path "D:\")) {
    Write-Err "Dドライブが見つかりません。USBドライブまたは外付けHDDを接続してください。"
    exit 1
}
Write-Success "Dドライブを確認しました。"

# --- セットアップ先ディレクトリの作成 ---
Write-Status "セットアップ先: $DestDir"
try {
    if (-not (Test-Path $DestDir)) {
        New-Item -ItemType Directory -Path $DestDir -Force | Out-Null
        Write-Success "ディレクトリを作成しました: $DestDir"
    } else {
        Write-Status "既存のディレクトリを使用します: $DestDir"
    }
} catch {
    Write-Err "ディレクトリの作成に失敗しました: $_"
    exit 1
}

# --- Gitクローンまたはpull ---
$GitAvailable = $null -ne (Get-Command git -ErrorAction SilentlyContinue)

if ($GitAvailable) {
    Write-Status "Gitでリポジトリを取得中..."
    try {
        if (Test-Path (Join-Path $DestDir ".git")) {
            Write-Status "既存のリポジトリを更新中 (git pull)..."
            Push-Location $DestDir
            git pull origin main 2>&1 | Out-Null
            Pop-Location
            Write-Success "リポジトリを最新の状態に更新しました。"
        } else {
            # ディレクトリが空でない場合は一時的に退避
            $files = Get-ChildItem $DestDir -Force
            if ($files.Count -gt 0) {
                Write-Status "既存ファイルをバックアップ中..."
                $backupDir = "${DestDir}_backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
                Move-Item $DestDir $backupDir -Force
                New-Item -ItemType Directory -Path $DestDir -Force | Out-Null
                Write-Success "バックアップ: $backupDir"
            }
            git clone $RepoUrl $DestDir 2>&1 | Out-Null
            Write-Success "リポジトリをクローンしました。"
        }
    } catch {
        Write-Err "Git操作に失敗しました: $_"
        Write-Status "ファイルを手動でコピーする方法に切り替えます..."
        # Gitが失敗してもファイルコピーにフォールバック
    }
} else {
    Write-Status "Gitが見つかりません。ファイルのコピーを実行します..."
}

# --- ファイルのコピー (Gitが使えない場合 or フォールバック) ---
$SourceDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not (Test-Path (Join-Path $DestDir "README.md"))) {
    Write-Status "スクリプトと同じフォルダのファイルをコピー中..."
    try {
        $filesToCopy = Get-ChildItem -Path $SourceDir -File | Where-Object { $_.Name -notmatch "^setup-d-drive" }
        foreach ($file in $filesToCopy) {
            Copy-Item $file.FullName -Destination $DestDir -Force
        }
        # サブフォルダもコピー
        $subDirs = Get-ChildItem -Path $SourceDir -Directory
        foreach ($dir in $subDirs) {
            Copy-Item $dir.FullName -Destination $DestDir -Recurse -Force
        }
        Write-Success "ファイルをコピーしました。"
    } catch {
        Write-Err "ファイルのコピーに失敗しました: $_"
        exit 1
    }
}

# --- index.html が無い場合は簡易ランチャーを作成 ---
if (-not (Test-Path $IndexFile)) {
    Write-Status "ランチャーHTMLを作成中..."
    $htmlContent = @"
<!DOCTYPE html>
<html lang="ja">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>web-automation-toolkit</title>
  <style>
    body { font-family: 'Meiryo', sans-serif; background: #1a1a2e; color: #eee; margin: 0; display: flex; justify-content: center; align-items: center; min-height: 100vh; }
    .container { text-align: center; padding: 40px; background: #16213e; border-radius: 16px; box-shadow: 0 8px 32px rgba(0,0,0,0.4); max-width: 600px; width: 90%; }
    h1 { color: #00d4ff; font-size: 1.8em; margin-bottom: 8px; }
    p { color: #aaa; margin-bottom: 32px; }
    .file-list { list-style: none; padding: 0; }
    .file-list li { margin: 10px 0; }
    .file-list a { display: block; padding: 12px 20px; background: #0f3460; border-radius: 8px; color: #00d4ff; text-decoration: none; transition: background 0.2s; }
    .file-list a:hover { background: #1a5276; }
    .badge { display: inline-block; background: #00d4ff; color: #000; font-size: 0.7em; padding: 2px 8px; border-radius: 4px; margin-left: 8px; vertical-align: middle; }
  </style>
</head>
<body>
  <div class="container">
    <h1>web-automation-toolkit</h1>
    <p>情報分析・HTML作成・業務自動化のためのツールキット</p>
    <ul class="file-list" id="fileList">
      <li><em>HTMLファイルをここに追加してください</em></li>
    </ul>
    <p style="margin-top:32px; font-size:0.8em; color:#555;">D:\web-automation-toolkit</p>
  </div>
</body>
</html>
"@
    try {
        Set-Content -Path $IndexFile -Value $htmlContent -Encoding UTF8
        Write-Success "index.html を作成しました。"
    } catch {
        Write-Err "index.html の作成に失敗しました: $_"
    }
}

# --- デスクトップショートカットの作成 ---
Write-Status "デスクトップアイコンを作成中..."
try {
    $WshShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut($ShortcutPath)
    $Shortcut.TargetPath = $IndexFile
    $Shortcut.WorkingDirectory = $DestDir
    $Shortcut.Description = "web-automation-toolkit を開く"
    # アイコンはIEのものを流用 (どのWindowsにも存在)
    $iexplore = "${env:ProgramFiles}\Internet Explorer\iexplore.exe"
    $msedge   = "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe"
    if (Test-Path $msedge) {
        $Shortcut.IconLocation = "$msedge, 0"
    } elseif (Test-Path $iexplore) {
        $Shortcut.IconLocation = "$iexplore, 0"
    }
    $Shortcut.Save()
    Write-Success "デスクトップアイコンを作成しました: $ShortcutPath"
} catch {
    Write-Err "ショートカットの作成に失敗しました: $_"
    Write-Status "手動でショートカットを作成してください。ターゲット: $IndexFile"
}

# --- 完了 ---
Write-Host ""
Write-Host "======================================" -ForegroundColor Green
Write-Host "  セットアップ完了!" -ForegroundColor Green
Write-Host "  場所: $DestDir" -ForegroundColor Green
Write-Host "  デスクトップアイコン: web-automation-toolkit" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Green
Write-Host ""

# ブラウザで開くか確認
$open = Read-Host "今すぐブラウザで開きますか? (y/N)"
if ($open -match "^[yY]") {
    Start-Process $IndexFile
}
