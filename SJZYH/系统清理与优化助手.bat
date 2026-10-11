@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion
title 系统清理与优化助手 - 三角洲行动环境优化
color 0A

:: ========== 管理员权限检查（自动提权） ==========
>nul 2>&1 net session
if %errorlevel% neq 0 (
    echo 正在请求管理员权限，请在弹出窗口点击"是"...
    powershell -NoProfile -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

:menu
cls
echo.
echo  ============================================================
echo        系统清理与优化助手（三角洲行动 · 环境深度优化）
echo  ============================================================
echo.
echo    [1] 一键深度清理垃圾文件（临时文件/缓存/DNS缓存）
echo    [2] 网络环境优化（重置 DNS/Winsock/TCP 协议栈）
echo    [3] 系统完整性修复（SFC + DISM，耗时较长）
echo    [4] 反作弊环境体检（ACE 服务/时间同步/可疑进程）
echo    [5] 游戏模式（关闭非必要后台进程）
echo    [6] 退出
echo.
set /p choice=  请输入选项 (1-6): 

if "%choice%"=="1" goto clean
if "%choice%"=="2" goto net
if "%choice%"=="3" goto repair
if "%choice%"=="4" goto ace
if "%choice%"=="5" goto game
if "%choice%"=="6" exit /b
goto menu

:: ========== [1] 一键深度清理 ==========
:clean
cls
echo  ============================================================
echo    [1/5] 正在清理 用户临时文件...
echo  ============================================================
if exist "%TEMP%\*" (
    del /f /s /q "%TEMP%\*" >nul 2>&1
    for /d %%d in ("%TEMP%\*") do rd /s /q "%%d" 2>nul
)
echo.
echo  [2/5] 正在清理 系统临时文件...
if exist "C:\Windows\Temp\*" (
    del /f /s /q "C:\Windows\Temp\*" >nul 2>&1
    for /d %%d in ("C:\Windows\Temp\*") do rd /s /q "%%d" 2>nul
)
echo.
echo  [3/5] 正在清理 预取文件与缩略图缓存...
if exist "C:\Windows\Prefetch\*" del /f /q "C:\Windows\Prefetch\*" >nul 2>&1
if exist "%LOCALAPPDATA%\Microsoft\Windows\Explorer\thumbcache_*.db" del /f /q "%LOCALAPPDATA%\Microsoft\Windows\Explorer\thumbcache_*.db" >nul 2>&1
echo.
echo  [4/5] 正在清理 DirectX 着色器缓存（游戏会自动重建）...
if exist "%LOCALAPPDATA%\D3DSCache" rd /s /q "%LOCALAPPDATA%\D3DSCache" 2>nul
if exist "C:\Windows\SoftwareDistribution\Download\*" (
    net stop wuauserv >nul 2>&1
    del /f /s /q "C:\Windows\SoftwareDistribution\Download\*" >nul 2>&1
    for /d %%d in ("C:\Windows\SoftwareDistribution\Download\*") do rd /s /q "%%d" 2>nul
    net start wuauserv >nul 2>&1
)
echo.
echo  [5/5] 正在刷新 DNS 缓存...
ipconfig /flushdns >nul
echo.
echo  ============================================================
echo   清理完成！本次未删除回收站和任何个人文件，
echo   游戏所需的缓存（着色器等）下次启动会自动重建。
echo  ============================================================
pause
goto menu

:: ========== [2] 网络环境优化 ==========
:net
cls
echo  ============================================================
echo    网络环境优化
echo  ============================================================
echo  将依次执行：
echo    * 刷新 DNS 缓存
echo    * 重置 Winsock 目录（netsh winsock reset）
echo    * 重置 TCP/IP 协议栈（netsh int tcp reset）
echo    * 重置 IP 配置（netsh int ip reset）
echo.
echo  注意：重置后【必须重启电脑】才能生效；
echo        重启前请勿进行游戏或其他网络操作。
echo.
set /p yn=确认执行？(Y/N): 
if /i not "%yn%"=="Y" goto menu
echo.
echo [1/4] 刷新 DNS 缓存...
ipconfig /flushdns
echo.
echo [2/4] 重置 Winsock...
netsh winsock reset
echo.
echo [3/4] 重置 TCP/IP...
netsh int tcp reset
echo.
echo [4/4] 重置 IP 配置...
netsh int ip reset
echo.
echo  ============================================================
echo   网络优化已执行完毕，请【重启电脑】使其生效。
echo  ============================================================
pause
goto menu

:: ========== [3] 系统完整性修复 ==========
:repair
cls
echo  ============================================================
echo    系统完整性修复
echo  ============================================================
echo  将执行两项检查（全程约 10-30 分钟，期间请勿关机）：
echo    * sfc /scannow                    检查修复系统文件
echo    * DISM RestoreHealth              修复系统映像组件
echo  适用于：系统文件损坏、反作弊组件异常、游戏闪退掉线。
echo.
set /p yn=确认执行？(Y/N): 
if /i not "%yn%"=="Y" goto menu
echo.
echo [1/2] 正在执行系统文件检查 (sfc /scannow)...
sfc /scannow
echo.
echo [2/2] 正在修复系统映像 (DISM)，此步骤可能需要联网下载...
DISM /Online /Cleanup-Image /RestoreHealth
echo.
echo  ============================================================
echo   系统完整性检查/修复完成！
echo   （若 SFC 提示发现损坏文件且无法修复，可再次运行本项）
echo  ============================================================
pause
goto menu

:: ========== [4] 反作弊环境体检 ==========
:ace
cls
echo  ============================================================
echo    反作弊环境体检（仅检测，不修改）
echo  ============================================================
echo.
echo [1/4] 反作弊服务状态（正常应为 STOPPED 手动启动）：
sc query AntiCheatExpert Service | findstr /i "STATE"
sc query AntiCheatExpert Protection | findstr /i "STATE"
sc query EasyAntiCheat_EOS | findstr /i "STATE"
echo   若显示 DISABLED 或服务缺失：请用管理员运行本工具第[3]项
echo   修复，或到游戏官网重新安装/修复反作弊组件。
echo.
echo [2/4] 同步系统时间（反作弊对时间偏差敏感）...
w32tm /resync /force >nul 2>&1
w32tm /query /status 2>nul | findstr /i "源 Source" || echo   时间服务查询无输出（不影响，已尝试强制同步）
echo.
echo [3/4] 检测常见可疑进程（仅提示，不自动处理）...
tasklist 2>nul | findstr /i "cheatengine trainer autohotkey artmoney gamemaster"
if %errorlevel% equ 1 echo   未发现常见可疑进程
echo.
echo [4/4] 检测常见易冲突软件（按键/宏/注入类）...
reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" /s /f "AutoHotkey" 2>nul | findstr /i "HKEY" && echo   ! 发现 AutoHotkey，请卸载后再游戏
reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" /s /f "Cheat Engine" 2>nul | findstr /i "HKEY" && echo   ! 发现 Cheat Engine，请卸载后再游戏
echo   未发现需报告的项目（若上方有输出请留意）
echo.
echo  ============================================================
echo   体检完成。环境干净即可正常游戏；
echo   若已多次被判定，建议联系游戏客服申诉确认账号状态。
echo  ============================================================
pause
goto menu

:: ========== [5] 游戏模式 ==========
:game
cls
echo  ============================================================
echo    游戏模式 - 关闭非必要后台进程
echo  ============================================================
echo  将关闭以下进程（重启电脑即可全部恢复）：
echo    * 壁纸引擎 (WallpaperEngine)     * 抖音桌面版
echo    * QQ浏览器                       * WPS Office
echo  不会关闭：杀毒软件、系统服务、豆包、游戏平台。
echo.
set /p yn=确认关闭？(Y/N): 
if /i not "%yn%"=="Y" goto menu
echo.
taskkill /f /im wallpaper64.exe >nul 2>&1 && echo   [已关闭] WallpaperEngine 壁纸引擎
taskkill /f /im douyin.exe >nul 2>&1 && echo   [已关闭] 抖音桌面版
taskkill /f /im QQBrowser.exe >nul 2>&1 && echo   [已关闭] QQ浏览器
taskkill /f /im wps.exe >nul 2>&1 && echo   [已关闭] WPS Office
taskkill /f /im wpscloudsvr.exe >nul 2>&1
echo.
echo  ============================================================
echo   游戏模式已开启！现在可以直接启动游戏。
echo   后台进程将在下次重启电脑后自动恢复。
echo  ============================================================
pause
goto menu
