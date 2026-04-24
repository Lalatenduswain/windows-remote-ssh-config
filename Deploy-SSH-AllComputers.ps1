#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Deploy SSH setup to multiple company Windows PCs

.DESCRIPTION
    Runs Setup-SSH-AllComputers.ps1 on remote machines via PSRemoting or locally

.PARAMETER ComputerNames
    Array of computer names to configure (use "." for localhost)

.PARAMETER PublicKey
    The SSH public key to add (required)

.PARAMETER CredentialFile
    Path to stored PSRemoting credentials (optional, for remote deployment)

.EXAMPLE
    .\Deploy-SSH-AllComputers.ps1 -ComputerNames @("PC-001","PC-002","PC-003") -PublicKey "ssh-rsa AAAA..."

.EXAMPLE
    .\Deploy-SSH-AllComputers.ps1 -ComputerNames @(".") -PublicKey "ssh-rsa AAAA..."  # Local only
#>

param(
    [Parameter(Mandatory=$true)]
    [string[]]$ComputerNames,

    [Parameter(Mandatory=$true)]
    [string]$PublicKey,

    [Parameter(Mandatory=$false)]
    [string]$CredentialFile,

    [Parameter(Mandatory=$false)]
    [int]$SSHPort = 22
)

# ============================================================================
# CONFIGURATION
# ============================================================================

$SetupScriptPath = ".\Setup-SSH-AllComputers.ps1"  # Path to main setup script
$LogFile = "C:\Logs\Deploy-SSH-Summary-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
$Results = @()

if (!(Test-Path $SetupScriptPath)) {
    Write-Host "ERROR: Setup script not found at $SetupScriptPath" -ForegroundColor Red
    exit 1
}

Write-Host "======== SSH Deployment Started ========" -ForegroundColor Cyan
Write-Host "Target Computers: $($ComputerNames -join ', ')" -ForegroundColor Yellow
Write-Host "Total Systems: $($ComputerNames.Count)" -ForegroundColor Yellow
Write-Host ""

# ============================================================================
# DEPLOY TO EACH COMPUTER
# ============================================================================

foreach ($Computer in $ComputerNames) {
    Write-Host "[$Computer] Starting deployment..." -ForegroundColor Yellow

    $Result = @{
        Computer = $Computer
        Status   = "Unknown"
        Details  = ""
        Timestamp = Get-Date
    }

    try {
        if ($Computer -eq "." -or $Computer -eq "localhost" -or $Computer -eq $env:COMPUTERNAME) {
            # Local deployment
            Write-Host "[$Computer] Running locally..." -ForegroundColor Gray

            & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $SetupScriptPath `
                -PublicKey $PublicKey -SSHPort $SSHPort

            $Result.Status = "Success"
            $Result.Details = "Local deployment completed"

        } else {
            # Remote deployment via PSRemoting
            Write-Host "[$Computer] Attempting remote deployment via PSRemoting..." -ForegroundColor Gray

            # Test connection first
            if (!(Test-Connection -ComputerName $Computer -Count 1 -Quiet)) {
                throw "Computer is offline or unreachable"
            }

            # Copy setup script to remote computer
            $RemoteScriptPath = "C:\Windows\Temp\Setup-SSH-$([guid]::NewGuid()).ps1"

            Copy-Item -Path $SetupScriptPath -Destination $RemoteScriptPath `
                -ToSession (New-PSSession -ComputerName $Computer) -ErrorAction Stop

            Write-Host "[$Computer] Setup script copied, executing..." -ForegroundColor Gray

            # Execute on remote
            $Session = New-PSSession -ComputerName $Computer
            Invoke-Command -Session $Session -ScriptBlock {
                param($ScriptPath, $PubKey, $Port)
                & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $ScriptPath `
                    -PublicKey $PubKey -SSHPort $Port
            } -ArgumentList $RemoteScriptPath, $PublicKey, $SSHPort -ErrorAction Stop

            Remove-PSSession -Session $Session

            $Result.Status = "Success"
            $Result.Details = "Remote deployment completed"
        }

    } catch {
        Write-Host "[$Computer] ERROR: $_" -ForegroundColor Red
        $Result.Status = "Failed"
        $Result.Details = $_.Exception.Message
    }

    $Results += $Result
    Write-Host ""
}

# ============================================================================
# SUMMARY REPORT
# ============================================================================

Write-Host "======== Deployment Summary ========`n" -ForegroundColor Cyan

$Successful = ($Results | Where-Object Status -eq "Success").Count
$Failed = ($Results | Where-Object Status -eq "Failed").Count

Write-Host "Total Computers:  $($Results.Count)" -ForegroundColor White
Write-Host "Successful:       $Successful" -ForegroundColor Green
Write-Host "Failed:           $Failed" -ForegroundColor Red
Write-Host ""

if ($Failed -gt 0) {
    Write-Host "Failed Deployments:" -ForegroundColor Red
    $Results | Where-Object Status -eq "Failed" | ForEach-Object {
        Write-Host "  - $($_.Computer): $($_.Details)" -ForegroundColor Red
    }
    Write-Host ""
}

# Save summary to file
$Results | ConvertTo-Json | Out-File $LogFile
Write-Host "Summary saved to: $LogFile" -ForegroundColor Yellow
Write-Host ""

# Cleanup
if ($Failed -eq 0) {
    Write-Host "✓ All deployments completed successfully!" -ForegroundColor Green
} else {
    Write-Host "⚠ Some deployments failed. Review log for details." -ForegroundColor Yellow
}
