@echo off
:: Run the PowerShell IPTV Launcher script
:: This batch file launches the PowerShell script with proper execution policy

PowerShell.exe -ExecutionPolicy Bypass -File "%~dp0IPTV_Launcher.ps1"

pause