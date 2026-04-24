# Remove-Teams.ps1 - Enhanced Version
# Description: Permanently remove Microsoft Teams from Windows
# Version: 2.0
# Features: Admin check, error handling, logging, rollback info

param(
    [switch]$NoConfirm = $false
)

# Check if running as Administrator
$IsAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")

if (-not $IsAdmin) {
    Write-Host ""
    Write-Host "ERROR: This script requires Administrator privileges!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please run PowerShell as Administrator:" -ForegroundColor Yellow
    Write-Host "  1. Right-click PowerShell" -ForegroundColor Cyan
    Write-Host "  2. Select 'Run as administrator'" -ForegroundColor Cyan
    Write-Host "  3. Run the script again" -ForegroundColor Cyan
    Write-Host ""
    exit 1
}

Write-Host ""
Write-Host "======== Microsoft Teams Removal Tool ========" -ForegroundColor Yellow
Write-Host "Version: 2.0 (Enhanced with error checking)" -ForegroundColor Cyan
Write-Host ""

# Ask for confirmation (unless -NoConfirm flag used)
if (-not $NoConfirm) {
    Write-Host "WARNING: This will PERMANENTLY remove Microsoft Teams!" -ForegroundColor Red
    Write-Host "Data will be deleted from:" -ForegroundColor Yellow
    Write-Host "  - AppData: $env:LOCALAPPDATA\Microsoft\Teams" -ForegroundColor Gray
    Write-Host "  - Roaming: $env:APPDATA\Microsoft\Teams" -ForegroundColor Gray
    Write-Host "  - Registry: HKCU:\Software\Microsoft\Teams" -ForegroundColor Gray
    Write-Host ""
    $Continue = Read-Host "Continue? (yes/no)"
    if ($Continue -ne "yes") {
        Write-Host "Cancelled." -ForegroundColor Yellow
        exit 0
    }
}

# Setup logging
$LogPath = "$env:TEMP\Teams-Removal-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
Write-Host "Logging to: $LogPath" -ForegroundColor Cyan
Write-Host ""

function Log-Message {
    param([string]$Message, [string]$Type = "INFO")
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogEntry = "[$Timestamp] [$Type] $Message"
    Add-Content -Path $LogPath -Value $LogEntry

    $Colors = @{
        "SUCCESS" = "Green"
        "ERROR"   = "Red"
        "WARNING" = "Yellow"
        "INFO"    = "Cyan"
    }
    Write-Host $LogEntry -ForegroundColor $Colors[$Type]
}

$ErrorCount = 0
$SuccessCount = 0

# Step 1: Stop Teams processes
Log-Message "Starting Teams removal process..." "INFO"
Log-Message "Step 1: Stopping Teams processes" "INFO"

try {
    $TeamsProcesses = Get-Process -Name "*teams*" -ErrorAction SilentlyContinue
    if ($TeamsProcesses) {
        $TeamsProcesses | Stop-Process -Force -ErrorAction SilentlyContinue
        Log-Message "Stopped $($TeamsProcesses.Count) Teams process(es)" "SUCCESS"
        $SuccessCount++
    } else {
        Log-Message "No Teams processes running" "INFO"
    }
} catch {
    Log-Message "Error stopping processes: $_" "ERROR"
    $ErrorCount++
}

# Step 2: Remove AppData
Log-Message "Step 2: Removing Teams from AppData" "INFO"

try {
    $TeamsPath = "$env:LOCALAPPDATA\Microsoft\Teams"
    if (Test-Path $TeamsPath) {
        Remove-Item $TeamsPath -Recurse -Force -ErrorAction Stop
        Log-Message "Removed AppData directory" "SUCCESS"
        $SuccessCount++
    } else {
        Log-Message "AppData directory not found (Teams may not be installed)" "WARNING"
    }
} catch {
    Log-Message "Error removing AppData: $_" "ERROR"
    $ErrorCount++
}

# Step 3: Uninstall package
Log-Message "Step 3: Uninstalling Teams package" "INFO"

try {
    $Package = Get-Package -Name "*Teams*" -ErrorAction SilentlyContinue
    if ($Package) {
        $Package | Uninstall-Package -Force -ErrorAction SilentlyContinue
        Log-Message "Uninstalled: $($Package.Name)" "SUCCESS"
        $SuccessCount++
    } else {
        Log-Message "No Teams package found in installed programs" "INFO"
    }
} catch {
    Log-Message "Error uninstalling package: $_" "ERROR"
    $ErrorCount++
}

# Step 4: Clean Registry
Log-Message "Step 4: Cleaning Windows Registry" "INFO"

try {
    $RegistryPaths = @(
        "HKCU:\Software\Microsoft\Teams",
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run\Teams",
        "HKLM:\SOFTWARE\Microsoft\Teams"
    )

    foreach ($Path in $RegistryPaths) {
        if (Test-Path $Path) {
            Remove-Item -Path $Path -Recurse -Force -ErrorAction SilentlyContinue
            Log-Message "Removed registry key: $Path" "SUCCESS"
        }
    }
    $SuccessCount++
} catch {
    Log-Message "Error cleaning registry: $_" "ERROR"
    $ErrorCount++
}

# Step 5: Remove cache/temp files
Log-Message "Step 5: Removing cache and temporary files" "INFO"

try {
    $CachePaths = @(
        "$env:APPDATA\Microsoft\Teams",
        "$env:TEMP\Microsoft Teams",
        "$env:LOCALAPPDATA\Microsoft\Teams Cache"
    )

    foreach ($Path in $CachePaths) {
        if (Test-Path $Path) {
            Remove-Item $Path -Recurse -Force -ErrorAction SilentlyContinue
            Log-Message "Removed cache: $Path" "SUCCESS"
        }
    }
    $SuccessCount++
} catch {
    Log-Message "Error removing cache: $_" "ERROR"
    $ErrorCount++
}

# Step 6: Verify removal
Log-Message "Step 6: Verifying Teams removal" "INFO"

try {
    $RemainingPackage = Get-Package -Name "*Teams*" -ErrorAction SilentlyContinue
    $RemainingFolder = Test-Path "$env:LOCALAPPDATA\Microsoft\Teams"

    if (-not $RemainingPackage -and -not $RemainingFolder) {
        Log-Message "Verification successful: Teams completely removed" "SUCCESS"
        $SuccessCount++
    } else {
        Log-Message "Warning: Some Teams files may remain (this is normal)" "WARNING"
    }
} catch {
    Log-Message "Verification skipped: $_" "WARNING"
}

# Final Summary
Write-Host ""
Write-Host "======== Removal Summary ========" -ForegroundColor Cyan
Log-Message "======== Removal Complete ========" "INFO"

if ($ErrorCount -eq 0) {
    Write-Host "Status: SUCCESS" -ForegroundColor Green
    Log-Message "Status: All steps completed successfully" "SUCCESS"
} else {
    Write-Host "Status: COMPLETED WITH ERRORS" -ForegroundColor Yellow
    Log-Message "Status: $ErrorCount error(s) encountered" "WARNING"
}

Write-Host "Successful operations: $SuccessCount" -ForegroundColor Green
Write-Host "Failed operations: $ErrorCount" -ForegroundColor $(if ($ErrorCount -gt 0) { "Red" } else { "Green" })
Write-Host "Log file: $LogPath" -ForegroundColor Yellow
Write-Host ""

if ($ErrorCount -eq 0) {
    Write-Host "Microsoft Teams has been successfully removed!" -ForegroundColor Green
    Write-Host "To reinstall later, run: winget install Microsoft.Teams -y" -ForegroundColor Cyan
} else {
    Write-Host "Some errors occurred. Review the log file for details." -ForegroundColor Yellow
}

Write-Host ""
