@echo off
setlocal EnableDelayedExpansion
title MYNA X SYSTEM - MynaTask Launcher
color 0F

:: ==================================================
:: PHASE 1: SYSTEM VERIFICATION (PRO METHOD)
:: ==================================================
echo [STEP 1] Verifying system environment...

:: Check Admin Rights first to perform Registry/Service checks
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [INFO] Requesting Administrative privileges...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

:: Check WinPE (Registry)
reg query "HKLM\System\CurrentControlSet\Control\MiniNT" >nul 2>&1
if %errorlevel% equ 0 (
    set "FAIL_REASON=Windows Preinstallation Environment (WinPE) detected."
    goto :FailExit
)

:: Check WinPE (X: Drive)
if /i "%SystemDrive%"=="X:" (
    set "FAIL_REASON=WinPE execution context detected (X: Drive)."
    goto :FailExit
)

:: Check WMI (Lite OS Detection)
if not exist "%SystemRoot%\System32\wbem\WMIADAP.exe" (
    set "FAIL_REASON=Missing WMI infrastructure (Incompatible Lite OS)."
    goto :FailExit
)

:: Check Essential Services (Lite OS Detection)
for %%S in (wuauserv WinDefend sppsvc) do (
    sc qc %%S >nul 2>&1
    if !errorlevel! neq 0 (
        set "FAIL_REASON=Essential service [%%S] is missing (Incompatible Lite OS)."
        goto :FailExit
    )
)

echo [OK] System environment is valid.
echo [OK] Standard Windows OS confirmed.
timeout /t 2 >nul
goto Main

:: ==================================================
:: PHASE 2: ERROR HANDLING
:: ==================================================
:FailExit
echo.
powershell -Command "Write-Host '--------------------------------------------------' -ForegroundColor Red"
powershell -Command "Write-Host 'CRITICAL ERROR: Unsupported OS Detected' -ForegroundColor Red"
powershell -Command "Write-Host 'This app does not support Win Lite, Win PE, or other modified OS.' -ForegroundColor Red"
powershell -Command "Write-Host 'Reason: %FAIL_REASON%' -ForegroundColor Yellow"
powershell -Command "Write-Host '--------------------------------------------------' -ForegroundColor Red"
echo.
echo Press any key to exit...
pause >nul
exit /b

:: ==================================================
:: PHASE 3: MAIN LAUNCHER
:: ==================================================
:Main
set "appPath=%~dp0MynaTask.ps1"
set "NSPath=%~dp0Assets\NSudo\NSudoLG.exe"
set "psexecPath=%~dp0Assets\OldExe\Lib.exe"

if not exist "%appPath%" (
    powershell -Command "Write-Host '[ERROR] File not found: %appPath%' -ForegroundColor Red"
    pause
    exit /b
)

:Menu
cls
echo ==================================================
echo            MYNA X SYSTEM - LAUNCHER
echo ==================================================
echo  Current OS: Standard (Verified)
echo  Target: %appPath%
echo ==================================================
echo Select privileges level:
echo.
echo [1] Run as Administrator (Standard)
echo [2] Run as SYSTEM (Advanced)
echo [3] Run as TrustedInstaller (Maximum)
echo.
echo [E] Exit
echo ==================================================
set /p "choice=Enter your choice (1-3): "

if "%choice%"=="1" goto RunAdmin
if "%choice%"=="2" goto RunSystem
if "%choice%"=="3" goto RunTrustInstaller
if /i "%choice%"=="e" exit
goto Menu

:RunAdmin
cls
echo [INFO] Launching with Administrator privileges...
powershell -ExecutionPolicy Bypass -File "%appPath%"
exit /b

:RunSystem
cls
echo [INFO] Escalating to SYSTEM privileges...
if exist "%NSPath%" (
    "%NSPath%" -U:S -P:E powershell.exe -ExecutionPolicy Bypass -File "%appPath%"
    if !errorlevel! neq 0 goto FallbackSystem
    exit /b
)
:FallbackSystem
if exist "%psexecPath%" (
    "%psexecPath%" -i -s powershell.exe -ExecutionPolicy Bypass -File "%appPath%"
) else (
    echo [ERROR] Privilege escalation tools missing!
    pause
    goto RunAdmin
)
exit /b

:RunTrustInstaller
cls
echo [INFO] Escalating to TrustedInstaller privileges...
if exist "%NSPath%" (
    "%NSPath%" -U:T -P:E powershell.exe -ExecutionPolicy Bypass -File "%appPath%"
) else (
    echo [ERROR] NSudoLG.exe is required for TrustedInstaller!
    pause
    goto Menu
)
exit /b