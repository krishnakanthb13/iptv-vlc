@echo off
:: Run the PowerShell IPTV Launcher script
:: This batch file launches the PowerShell script with proper execution policy

PowerShell.exe -ExecutionPolicy Bypass -File "%~dp0IPTV_Launcher.ps1" %*

:: Only pause for interactive use (no arguments);
:: quick-search invocations from other scripts must not block.
if "%~1"=="" pause