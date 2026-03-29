@echo off
chcp 65001 > nul
title web-automation-toolkit セットアップ

echo.
echo  ========================================
echo   web-automation-toolkit Dドライブ セットアップ
echo  ========================================
echo.

:: PowerShell実行ポリシー確認・スクリプト実行
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup-d-drive.ps1"

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [ERROR] セットアップに失敗しました。
    echo        管理者権限で実行するか、PowerShellを直接起動して
    echo        setup-d-drive.ps1 を実行してください。
    echo.
    pause
    exit /b 1
)

echo.
pause
