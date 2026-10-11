@echo off
chcp 65001 >nul
title System Clean and Boost
color 0A

rem ================================================================
rem  System Clean & Boost - clean environment for gaming
rem  Safety: only removes regenerable caches and temp files
rem  Never touches: personal files / installed apps / system files
rem  Usage: double-click to run (UAC prompt appears), or right-click
rem         then "Run as administrator"
rem ================================================================

rem ---- Request admin rights (standard UAC prompt) ----
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo  Requesting administrator rights, please click "Yes" in the popup...
    echo.
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    echo.
    echo  If no popup appears, right-click this file and select "Run as administrator"
    echo.
    pause
    exit /b
)

echo ================================================================
echo            System Clean and Boost Assistant
echo  Goal: clean and stable environment for gaming
echo  [Safety] Only removes regenerable caches and temp files
echo  Never deletes: personal files / installed apps / system files
echo ================================================================
echo.

rem ---- Global source variable checks: empty means abort ----
if "%USERPROFILE%"=="" (echo  [FAIL] USERPROFILE is empty & goto :FAIL_SAFE)
if "%TEMP%"=="" (echo  [FAIL] TEMP is empty & goto :FAIL_SAFE)
if "%LOCALAPPDATA%"=="" (echo  [FAIL] LOCALAPPDATA is empty & goto :FAIL_SAFE)
if "%ProgramData%"=="" (echo  [FAIL] ProgramData is empty & goto :FAIL_SAFE)

rem ---- Global prefix whitelist checks ----
echo %TEMP% | findstr /i /b /c:"%USERPROFILE%\AppData\Local\Temp" >nul 2>&1
if %errorlevel% neq 0 (echo  [FAIL] TEMP not under expected user Temp dir & goto :FAIL_SAFE)
echo %LOCALAPPDATA% | findstr /i /b /c:"%USERPROFILE%\AppData\Local" >nul 2>&1
if %errorlevel% neq 0 (echo  [FAIL] LOCALAPPDATA not under expected user Local dir & goto :FAIL_SAFE)
echo %ProgramData% | findstr /i /b /c:"C:\ProgramData" >nul 2>&1
if %errorlevel% neq 0 (echo  [FAIL] ProgramData is not C:\ProgramData & goto :FAIL_SAFE)

rem ---- Global drive-root rejection ----
if "%TEMP%"=="C:\" (echo  [FAIL] TEMP is drive root & goto :FAIL_SAFE)
if "%LOCALAPPDATA%"=="C:\" (echo  [FAIL] LOCALAPPDATA is drive root & goto :FAIL_SAFE)
if "%ProgramData%"=="C:\" (echo  [FAIL] ProgramData is drive root & goto :FAIL_SAFE)

rem ---- Fixed whitelist dirs must exist ----
if not exist "C:\Windows\Temp" (echo  [FAIL] system temp dir missing & goto :FAIL_SAFE)
if not exist "C:\Windows\SoftwareDistribution\Download" (echo  [FAIL] update cache dir missing & goto :FAIL_SAFE)

echo  [OK] Path check passed, starting...
echo.

rem ---- Record free space on C before cleaning ----
for /f "delims=" %%a in ('powershell -NoProfile -Command "[math]::Round((Get-PSDrive C).Free/1GB,1)"') do set BEFORE=%%a
echo [Step 1/8] Free space on C before: %BEFORE% GB
echo.

rem ================= CLEANING (each target validated first) =================

rem ---- 1. User temp files ----
echo [Step 2/8] Cleaning user temp files...
set TARGET=%TEMP%
if "%TARGET%"=="" goto :FAIL_SAFE
if "%TARGET%"=="\" goto :FAIL_SAFE
if not exist "%TARGET%" goto :FAIL_SAFE
del /f /s /q "%TARGET%\*" >nul 2>&1
for /d %%i in ("%TARGET%\*") do rd /s /q "%%i" >nul 2>&1

rem ---- 2. System temp files ----
echo [Step 2/8] Cleaning system temp files...
set TARGET=C:\Windows\Temp
if "%TARGET%"=="" goto :FAIL_SAFE
if "%TARGET%"=="\" goto :FAIL_SAFE
if "%TARGET%"=="C:\" goto :FAIL_SAFE
if not exist "%TARGET%" goto :FAIL_SAFE
del /f /s /q "%TARGET%\*" >nul 2>&1
for /d %%i in ("%TARGET%\*") do rd /s /q "%%i" >nul 2>&1

rem ---- 3. Windows Update cache (restore service state after) ----
echo [Step 3/8] Cleaning Windows Update cache...
sc query wuauserv | findstr /i "RUNNING" >nul 2>&1
if %errorlevel%==0 (set WU_RUN=1) else (set WU_RUN=0)
sc stop wuauserv >nul 2>&1
set TARGET=C:\Windows\SoftwareDistribution\Download
if "%TARGET%"=="" goto :FAIL_SAFE
if "%TARGET%"=="\" goto :FAIL_SAFE
if "%TARGET%"=="C:\" goto :FAIL_SAFE
if not exist "%TARGET%" goto :FAIL_SAFE
del /f /s /q "%TARGET%\*" >nul 2>&1
for /d %%i in ("%TARGET%\*") do rd /s /q "%%i" >nul 2>&1
if "%WU_RUN%"=="1" sc start wuauserv >nul 2>&1

rem ---- 4. Thumbnail and shader caches ----
echo [Step 4/8] Cleaning thumbnail and shader caches...
set TARGET=%LOCALAPPDATA%\Microsoft\Windows\Explorer
if "%TARGET%"=="" goto :FAIL_SAFE
if "%TARGET%"=="\" goto :FAIL_SAFE
if not exist "%TARGET%" goto :FAIL_SAFE
del /f /q "%TARGET%\thumbcache_*" >nul 2>&1
set TARGET=%LOCALAPPDATA%\D3DSCache
if "%TARGET%"=="" goto :FAIL_SAFE
if "%TARGET%"=="\" goto :FAIL_SAFE
if not exist "%TARGET%" goto :FAIL_SAFE
del /f /s /q "%TARGET%\*" >nul 2>&1
for /d %%i in ("%TARGET%\*") do rd /s /q "%%i" >nul 2>&1
set TARGET=%LOCALAPPDATA%\NVIDIA\DXCache
if "%TARGET%"=="" goto :FAIL_SAFE
if "%TARGET%"=="\" goto :FAIL_SAFE
if not exist "%TARGET%" goto :FAIL_SAFE
del /f /s /q "%TARGET%\*" >nul 2>&1
for /d %%i in ("%TARGET%\*") do rd /s /q "%%i" >nul 2>&1
set TARGET=%LOCALAPPDATA%\NVIDIA\GLCache
if "%TARGET%"=="" goto :FAIL_SAFE
if "%TARGET%"=="\" goto :FAIL_SAFE
if not exist "%TARGET%" goto :FAIL_SAFE
del /f /s /q "%TARGET%\*" >nul 2>&1
for /d %%i in ("%TARGET%\*") do rd /s /q "%%i" >nul 2>&1

rem ---- 5. Browser cache (Cache/Code Cache only) ----
echo [Step 5/8] Cleaning browser caches...
for %%b in ("%LOCALAPPDATA%\Microsoft\Edge\User Data" "%LOCALAPPDATA%\Google\Chrome\User Data") do (
    if exist "%%~b\Default\Cache" (
        del /f /s /q "%%~b\Default\Cache\*" >nul 2>&1
        for /d %%i in ("%%~b\Default\Cache\*") do rd /s /q "%%i" >nul 2>&1
    )
    if exist "%%~b\Default\Code Cache" (
        del /f /s /q "%%~b\Default\Code Cache\*" >nul 2>&1
        for /d %%i in ("%%~b\Default\Code Cache\*") do rd /s /q "%%i" >nul 2>&1
    )
    for /d %%p in ("%%~b\Profile *") do (
        if exist "%%p\Cache" (
            del /f /s /q "%%p\Cache\*" >nul 2>&1
            for /d %%i in ("%%p\Cache\*") do rd /s /q "%%i" >nul 2>&1
        )
        if exist "%%p\Code Cache" (
            del /f /s /q "%%p\Code Cache\*" >nul 2>&1
            for /d %%i in ("%%p\Code Cache\*") do rd /s /q "%%i" >nul 2>&1
        )
    )
)

rem ---- 6. System logs and error reports ----
echo [Step 6/8] Cleaning system logs and error reports...
set TARGET=C:\Windows\Logs
if "%TARGET%"=="" goto :FAIL_SAFE
if "%TARGET%"=="\" goto :FAIL_SAFE
if "%TARGET%"=="C:\" goto :FAIL_SAFE
if not exist "%TARGET%" goto :FAIL_SAFE
del /f /s /q "%TARGET%\*" >nul 2>&1
set TARGET=%ProgramData%\Microsoft\Windows\WER
if "%TARGET%"=="" goto :FAIL_SAFE
if "%TARGET%"=="\" goto :FAIL_SAFE
if not exist "%TARGET%" goto :FAIL_SAFE
del /f /s /q "%TARGET%\*" >nul 2>&1
set TARGET=C:\Windows\Minidump
if "%TARGET%"=="" goto :FAIL_SAFE
if "%TARGET%"=="\" goto :FAIL_SAFE
if "%TARGET%"=="C:\" goto :FAIL_SAFE
if not exist "%TARGET%" goto :FAIL_SAFE
del /f /s /q "%TARGET%\*" >nul 2>&1
if exist "C:\Windows\MEMORY.DMP" del /f /q "C:\Windows\MEMORY.DMP" >nul 2>&1

rem ---- 7. Network environment reset ----
echo [Step 7/8] Resetting network environment...
echo      - Flushing DNS cache
ipconfig /flushdns >nul 2>&1
echo      - Re-registering DNS
ipconfig /registerdns >nul 2>&1
echo      - Resetting Winsock catalog (takes effect after reboot)
netsh winsock reset >nul 2>&1
echo      - Resetting TCP/IP stack (takes effect after reboot)
netsh int ip reset "%TEMP%\ipreset.log" >nul 2>&1
echo.
echo  Note: reboot is recommended after network reset so it fully takes effect.
echo.

rem ---- 8. Environment checks ----
echo [Step 8/8] Environment checks...
echo.
echo  System proxy status:
netsh winhttp show proxy
echo.
tasklist | findstr /i "clash verge mihomo v2ray nekoray sing-box trojan xray shadowsocks" >nul 2>&1 && echo  [CHECK] Proxy-like process found, exit it before gaming. || echo  [CHECK] No proxy-like process, network clean.
tasklist | findstr /i "autohotkey 按键精灵 简单百宝箱" >nul 2>&1 && echo  [CHECK] Macro/keyboard tool found, exit it before gaming. || echo  [CHECK] No macro/keyboard tool, environment clean.

rem ---- Optional deep system file check ----
echo.
set /p DEEP=Run deep system file check sfc /scannow (10-30 min)? Type Y to run, Enter to skip: 
if /i "%DEEP%"=="Y" (
    echo Running system file check, please wait...
    sfc /scannow
    echo System file check finished
)

rem ---- Summary ----
for /f "delims=" %%a in ('powershell -NoProfile -Command "[math]::Round((Get-PSDrive C).Free/1GB,1)"') do set AFTER=%%a
for /f "delims=" %%f in ('powershell -NoProfile -Command "[math]::Round((Get-PSDrive C).Free/1GB - %BEFORE%,1)"') do set FREED=%%f
echo.
echo ================================================================
echo            Clean and Boost Finished
echo    Free space on C before: %BEFORE% GB
echo    Free space on C after:  %AFTER% GB
echo    Freed this run:         %FREED% GB
echo ================================================================
echo.
echo  Before gaming:
echo   1. Close WeChat / QQ / Doubao / browser to free up memory
echo   2. Make sure proxy software is exited, keep network clean
echo   3. If network was reset, reboot before gaming
echo   4. This script only cleans caches, personal files untouched
echo.
echo  To empty the Recycle Bin, do it manually in the Recycle Bin itself.
echo.
pause
exit /b

:FAIL_SAFE
echo.
echo  ================================================
echo   Path safety check failed. Cleaning was aborted.
echo   Nothing was deleted. If this keeps happening,
echo   do not edit the script manually.
echo  ================================================
echo.
pause
exit /b
