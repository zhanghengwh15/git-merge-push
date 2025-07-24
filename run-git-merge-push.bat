@echo off
chcp 65001 >nul
title Git Merge Push - Windows 版本

echo.
echo ========================================
echo    Git Merge Push - Windows 版本
echo ========================================
echo.

REM 检查是否在正确的目录
if not exist "git-merge-push.ps1" (
    echo [错误] 未找到 git-merge-push.ps1 文件
    echo 请确保在正确的目录中运行此批处理文件
    echo.
    pause
    exit /b 1
)

REM 检查 PowerShell 是否可用
powershell -Command "Write-Host 'PowerShell 可用'" >nul 2>&1
if errorlevel 1 (
    echo [错误] PowerShell 不可用
    echo 请确保系统已安装 PowerShell 5.1 或更高版本
    echo.
    pause
    exit /b 1
)

REM 检查执行策略
echo [信息] 检查 PowerShell 执行策略...
powershell -Command "Get-ExecutionPolicy -Scope CurrentUser" >nul 2>&1
if errorlevel 1 (
    echo [警告] 执行策略可能过于严格
    echo 如果遇到问题，请以管理员身份运行以下命令：
    echo Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
    echo.
)

echo [信息] 启动 Git Merge Push 脚本...
echo.

REM 运行 PowerShell 脚本
powershell -ExecutionPolicy Bypass -File "git-merge-push.ps1" %*

echo.
echo [信息] 脚本执行完成
pause 