#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Deploy SSH to multiple computers using a CSV list

.DESCRIPTION
    Reads computer names from a CSV file and deploys SSH setup to each

.PARAMETER CSVFile
    Path to CSV file with ComputerName column (required)

.EXAMPLE
    .\Deploy-SSH-FromCSV.ps1 -CSVFile "computers-list.csv"

.EXAMPLE
    .\Deploy-SSH-FromCSV.ps1 -CSVFile "computers-list.csv" -Verbose
#>

param(
    [Parameter(Mandatory=$true)]
    [ValidateScript({Test-Path $_})]
    [string]$CSVFile
)

# ============================================================================
# SETUP
# ============================================================================

$SetupScriptPath = ".\Setup-SSH-YourCompany.ps1"
$SummaryFile = "C:\Logs\Deploy-SSH-Summary-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"
$Results = @()
$TotalCount = 0
$SuccessCount = 0
$FailureCount = 0

# Create logs directory
if (!(Test-Path "C:\Logs")) {
    New-Item -ItemType Directory -Path "C:\Logs" -Force | Out-Null
}

if (!(Test-Path $SetupScriptPath)) {
    Write-Host "ERROR: Setup script not found at $SetupScriptPath" -ForegroundColor Red
    exit 1
}

# Read CSV file
try {
    $Computers = Import-Csv $CSVFile -ErrorAction Stop
    Write-Host "Loaded $($Computers.Count) computers from CSV" -ForegroundColor Green
} catch {
    Write-Host "ERROR reading CSV: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "======== SSH Batch Deployment ========" -ForegroundColor Cyan
Write-Host "CSV File: $CSVFile" -ForegroundColor Yellow
Write-Host "Total computers: $($Computers.Count)" -ForegroundColor Yellow
Write-Host "Start time: $(Get-Date)" -ForegroundColor Yellow
Write-Host ""

# ============================================================================
# DEPLOY TO EACH COMPUTER
# ============================================================================

foreach ($Computer in $Computers) {
    $ComputerName = $Computer.ComputerName.Trim()
    $Port = if ($Computer.SSHPort) { [int]$Computer.SSHPort } else { 22 }

    if ([string]::IsNullOrWhiteSpace($ComputerName)) {
        continue
    }

    $TotalCount++
    $Status = "Unknown"
    $Details = ""

    Write-Host "[$TotalCount/$($Computers.Count)] $ComputerName (Port: $Port)" -ForegroundColor Cyan

    try {
        # Test connection
        if (!(Test-Connection -ComputerName $ComputerName -Count 1 -Quiet -ErrorAction SilentlyContinue)) {
            throw "Computer is offline or unreachable"
        }

        if ($ComputerName -eq $env:COMPUTERNAME) {
            # Local
            Write-Host "  → Running locally..." -ForegroundColor Gray
            & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $SetupScriptPath -SSHPort $Port | Out-Null
            $Status = "Success"
            $Details = "Local deployment completed"
            $SuccessCount++

        } else {
            # Remote
            Write-Host "  → Connecting to remote machine..." -ForegroundColor Gray

            $Session = New-PSSession -ComputerName $ComputerName -ErrorAction Stop
            $RemoteScriptPath = "C:\Windows\Temp\Setup-SSH-$([guid]::NewGuid()).ps1"

            Copy-Item -Path $SetupScriptPath -Destination $RemoteScriptPath `
                -ToSession $Session -ErrorAction Stop

            Write-Host "  → Running setup script..." -ForegroundColor Gray

            Invoke-Command -Session $Session -ScriptBlock {
                param($ScriptPath, $Port)
                & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $ScriptPath -SSHPort $Port 2>&1 | Out-Null
            } -ArgumentList $RemoteScriptPath, $Port -ErrorAction Stop

            Remove-PSSession -Session $Session

            $Status = "Success"
            $Details = "Remote deployment completed"
            $SuccessCount++
        }

    } catch {
        $Status = "Failed"
        $Details = $_.Exception.Message
        $FailureCount++
        Write-Host "  ✗ ERROR: $Details" -ForegroundColor Red
    }

    # Record result
    $Results += [PSCustomObject]@{
        ComputerName = $ComputerName
        Location = $Computer.Location
        Department = $Computer.Department
        SSHPort = $Port
        Status = $Status
        Details = $Details
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }

    Write-Host "  ✓ $Status" -ForegroundColor $(if($Status -eq "Success") {"Green"} else {"Red"})
    Write-Host ""
}

# ============================================================================
# SUMMARY REPORT
# ============================================================================

Write-Host "======== Deployment Complete ========`n" -ForegroundColor Cyan
Write-Host "Total:      $TotalCount" -ForegroundColor White
Write-Host "Successful: $SuccessCount" -ForegroundColor Green
Write-Host "Failed:     $FailureCount" -ForegroundColor Red
Write-Host ""

# Save CSV report
$Results | Export-Csv -Path $SummaryFile -NoTypeInformation
Write-Host "Report saved to: $SummaryFile" -ForegroundColor Yellow

# Show failed computers
if ($FailureCount -gt 0) {
    Write-Host "`nFailed Computers:" -ForegroundColor Red
    $Results | Where-Object Status -eq "Failed" | ForEach-Object {
        Write-Host "  - $($_.ComputerName): $($_.Details)" -ForegroundColor Red
    }
}

Write-Host ""
if ($FailureCount -eq 0) {
    Write-Host "✓ All deployments completed successfully!" -ForegroundColor Green
} else {
    Write-Host "⚠ $FailureCount deployment(s) failed. Check report for details." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "End time: $(Get-Date)" -ForegroundColor Gray
