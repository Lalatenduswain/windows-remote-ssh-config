@echo off
REM ============================================================================
REM SSH Setup - Simple One-Click Installer
REM ============================================================================
REM
REM Instructions:
REM 1. Right-click this file and choose "Run as administrator"
REM 2. Follow the prompts
REM 3. Done! SSH will be configured on this PC
REM
REM ============================================================================

echo.
echo ======== SSH Installation for Your Company ========
echo.
echo This script will:
echo   1. Install OpenSSH Server
echo   2. Add your company SSH public key
echo   3. Start SSH service
echo   4. Configure Windows Firewall
echo.

REM Check if running as Administrator
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo ERROR: This script must be run as Administrator!
    echo Please right-click and select "Run as administrator"
    pause
    exit /b 1
)

echo Starting installation...
echo.

REM Run the PowerShell setup script
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "Setup-SSH-YourCompany.ps1"

if %errorLevel% neq 0 (
    echo.
    echo ERROR: Setup failed. Check the log file for details.
    pause
    exit /b 1
)

echo.
echo ======== Installation Complete! ========
echo.
echo SSH is now configured on %COMPUTERNAME%
echo.
echo To connect from your machine:
echo   ssh -i your-private-key Administrator@%COMPUTERNAME%
echo.
pause
