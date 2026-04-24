param(
    [string]$PowerShellVersion = "v1.0",  # v1.0 for PowerShell 5.1, or "7" for PowerShell 7+
    [string[]]$ComputerNames = @()
)

# ============================================================================
# SET POWERSHELL AS DEFAULT SSH SHELL
# ============================================================================
# Description: Sets PowerShell as the default shell for SSH connections
# Author: Automated SSH Setup
# Version: 1.0
#
# Usage:
#   # Local machine - PowerShell 5.1
#   .\Set-PowerShellAsDefaultSSHShell.ps1
#
#   # Local machine - PowerShell 7+
#   .\Set-PowerShellAsDefaultSSHShell.ps1 -PowerShellVersion "7"
#
#   # Remote machines
#   .\Set-PowerShellAsDefaultSSHShell.ps1 -ComputerNames "PC-001","PC-002"
# ============================================================================

$ErrorActionPreference = "Stop"

# Logging setup
$LogDir = "C:\Logs"
if (-not (Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
}

$LogFile = Join-Path $LogDir "Set-PowerShell-SSH-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogEntry = "[$Timestamp] [$Level] $Message"
    Add-Content -Path $LogFile -Value $LogEntry

    $Color = @{
        "SUCCESS" = "Green"
        "ERROR"   = "Red"
        "WARNING" = "Yellow"
        "INFO"    = "Cyan"
    }
    Write-Host $LogEntry -ForegroundColor $Color[$Level]
}

function Set-PowerShellSSHShell {
    param([string]$ComputerName = $null, [string]$PSVersion = "v1.0")

    try {
        # Determine PowerShell path based on version
        if ($PSVersion -eq "7") {
            $PowerShellPath = "C:\Program Files\PowerShell\7\pwsh.exe"
            $PSLabel = "PowerShell 7"
        } else {
            $PowerShellPath = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
            $PSLabel = "PowerShell 5.1 (Built-in)"
        }

        # Check if PowerShell path exists
        $RemoteCheck = $null
        if ($ComputerName) {
            $RemoteCheck = Invoke-Command -ComputerName $ComputerName -ScriptBlock {
                param($Path)
                Test-Path $Path
            } -ArgumentList $PowerShellPath -ErrorAction SilentlyContinue
        } else {
            $RemoteCheck = Test-Path $PowerShellPath
        }

        if (-not $RemoteCheck) {
            Write-Log "⚠ $PSLabel not found at $PowerShellPath on $($ComputerName ?? 'local machine')" "WARNING"
            return $false
        }

        # Set registry key
        $ScriptBlock = {
            param($Path, $Label)
            try {
                $RegistryPath = "HKLM:\SOFTWARE\OpenSSH"

                # Ensure registry path exists
                if (-not (Test-Path $RegistryPath)) {
                    New-Item -Path $RegistryPath -Force | Out-Null
                }

                # Set the default shell
                New-ItemProperty -Path $RegistryPath -Name "DefaultShell" -Value $Path -PropertyType String -Force | Out-Null
                return @{ Success = $true; Message = "Set $Label as default SSH shell" }
            } catch {
                return @{ Success = $false; Message = $_.Exception.Message }
            }
        }

        if ($ComputerName) {
            $Result = Invoke-Command -ComputerName $ComputerName -ScriptBlock $ScriptBlock -ArgumentList $PowerShellPath, $PSLabel
        } else {
            $Result = & $ScriptBlock -Path $PowerShellPath -Label $PSLabel
        }

        if ($Result.Success) {
            Write-Log "✓ $($Result.Message)" "SUCCESS"
            return $true
        } else {
            Write-Log "✗ Failed: $($Result.Message)" "ERROR"
            return $false
        }
    } catch {
        Write-Log "✗ Error: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# ============================================================================
# MAIN LOGIC
# ============================================================================

Write-Host ""
Write-Host "======== PowerShell SSH Shell Configuration ========" -ForegroundColor Cyan
Write-Host ""
Write-Log "======== PowerShell SSH Shell Configuration Started ========"
Write-Log "PowerShell Version: $PowerShellVersion"

if ($ComputerNames.Count -gt 0) {
    Write-Log "Target Computers: $($ComputerNames -join ', ')"
    Write-Host "Configuring $($ComputerNames.Count) computer(s)..." -ForegroundColor Yellow
    Write-Host ""

    $SuccessCount = 0
    $FailureCount = 0

    foreach ($Computer in $ComputerNames) {
        Write-Host "Processing: $Computer" -ForegroundColor Cyan
        if (Set-PowerShellSSHShell -ComputerName $Computer -PSVersion $PowerShellVersion) {
            $SuccessCount++
        } else {
            $FailureCount++
        }
    }

    Write-Host ""
    Write-Host "======== Summary ========" -ForegroundColor Cyan
    Write-Log "Configuration Summary: Success=$SuccessCount, Failed=$FailureCount"
    Write-Host "Success: $SuccessCount | Failed: $FailureCount" -ForegroundColor $(if ($FailureCount -eq 0) { "Green" } else { "Yellow" })
} else {
    Write-Log "Configuring local machine..."
    Write-Host "Configuring local machine..." -ForegroundColor Yellow

    if (Set-PowerShellSSHShell -PSVersion $PowerShellVersion) {
        Write-Host ""
        Write-Host "======== Configuration Complete ========" -ForegroundColor Green
        Write-Log "Configuration completed successfully"
    } else {
        Write-Host ""
        Write-Host "======== Configuration Failed ========" -ForegroundColor Red
        Write-Log "Configuration failed"
        exit 1
    }
}

Write-Host ""
Write-Host "Log file: $LogFile" -ForegroundColor Yellow
Write-Host "Test with: ssh -i <private-key> Administrator@COMPUTERNAME" -ForegroundColor Green
Write-Host ""
