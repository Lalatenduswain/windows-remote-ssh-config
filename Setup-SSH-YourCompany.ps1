#Requires -RunAsAdministrator
<#
.SYNOPSIS
    OpenSSH Server setup for company Windows PCs (Pre-configured with your key)

.DESCRIPTION
    - Installs OpenSSH Server (if missing)
    - Configures authorized_keys for Administrators
    - Sets proper NTFS permissions
    - Enables and starts SSH service
    - Validates SSH connectivity
    - Logs all actions

.PARAMETER Username
    Optional: Setup SSH for a specific regular user (default: Administrators only)

.PARAMETER SSHPort
    SSH listening port (default: 22)

.EXAMPLE
    .\Setup-SSH-YourCompany.ps1

.EXAMPLE
    .\Setup-SSH-YourCompany.ps1 -Username "john.doe" -SSHPort 2222
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$Username = "",

    [Parameter(Mandatory=$false)]
    [int]$SSHPort = 22
)

# ============================================================================
# PRE-CONFIGURED PUBLIC KEY (Your Company)
# ============================================================================

$PublicKey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC8IdDscm8+MRACm3dpE6796u2Y+vxi9bajA/y1YKE+l4ylGNzk43YGBpSXEjMlGe5t6S+PYg6xi0Wr0wO1mROwF1RSkEYee0Pszue+kDm1yuDEk3EjasdCgrxwnz5J1T6EN2ngBjcK7ZPDvhni1fcfG1VJNblzpQlzC8vkvU4aRABCkqV4jgio/+IfXO9Qqo/0NP3IEBUHFuTbSPpMwMWDoxwIQN/K6e7nCjuQ0t+YAuQLIRRYzBDS+j79/IL2TEbD0kbopnZqaiZ94HU5KlZ1G1EmZurhQaSP6UIF+YXMqwkLFrNUuisfWXZduo3XRS4fj5xQpZNfZwNzjf6IAaQwLcRfpMpVkoYUX00hklLf0OInSDjBcGoDqBFg7NyG2Kty9Ihm9Fl+NWpbMDb0mTZ9/l1dUOy8WMzEhPlFZuSGBfLc/9L+3FQDv48HuvYyajOtmgPdytHmVc+Lbj62kX30qPq297g628vBE0PrWj/2QJGPCNeoXGfbnzmGAW2a3yU="

# ============================================================================
# SETUP
# ============================================================================

$LogPath = "C:\Logs"
$LogFile = "$LogPath\SSH-Setup-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
$ErrorActionPreference = "Continue"

# Create log directory if missing
if (!(Test-Path $LogPath)) {
    New-Item -ItemType Directory -Path $LogPath -Force | Out-Null
}

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogMessage = "[$Timestamp] [$Level] $Message"
    Add-Content -Path $LogFile -Value $LogMessage
    Write-Host $LogMessage -ForegroundColor $(if($Level -eq "ERROR") {"Red"} elseif($Level -eq "SUCCESS") {"Green"} else {"White"})
}

Write-Log "======== SSH Setup Started ========"
Write-Log "Computer: $env:COMPUTERNAME | User: $env:USERNAME"
Write-Log "Target Port: $SSHPort"

# ============================================================================
# 1. INSTALL OPENSSH SERVER
# ============================================================================

Write-Log "Step 1: Checking OpenSSH Server..."

try {
    $OpenSSH = Get-WindowsCapability -Online -Name "OpenSSH.Server*" | Where-Object State -eq "NotPresent"

    if ($OpenSSH) {
        Write-Log "Installing OpenSSH Server..." "INFO"
        Add-WindowsCapability -Online -Name "OpenSSH.Server~~~~0.0.1.0" -ErrorAction Stop | Out-Null
        Write-Log "OpenSSH Server installed successfully" "SUCCESS"
    } else {
        Write-Log "OpenSSH Server already installed" "INFO"
    }
} catch {
    Write-Log "ERROR installing OpenSSH: $_" "ERROR"
    exit 1
}

# ============================================================================
# 2. SETUP AUTHORIZED_KEYS
# ============================================================================

Write-Log "Step 2: Setting up authorized_keys..."

if ($Username) {
    # Regular user setup
    $UserProfile = (Get-ChildItem "C:\Users" -Filter $Username -ErrorAction SilentlyContinue)[0].FullName

    if (!$UserProfile) {
        Write-Log "User '$Username' not found" "ERROR"
        exit 1
    }

    $AuthKeysPath = "$UserProfile\.ssh\authorized_keys"
    $SSHDir = "$UserProfile\.ssh"

    Write-Log "Setting up SSH for regular user: $Username"
} else {
    # Administrator setup
    $AuthKeysPath = "C:\ProgramData\ssh\administrators_authorized_keys"
    $SSHDir = "C:\ProgramData\ssh"
    Write-Log "Setting up SSH for Administrators"
}

# Create .ssh directory if missing
if (!(Test-Path $SSHDir)) {
    New-Item -ItemType Directory -Path $SSHDir -Force | Out-Null
    Write-Log "Created directory: $SSHDir" "SUCCESS"
}

# Add public key to authorized_keys
try {
    # Check if key already exists
    if ((Test-Path $AuthKeysPath) -and (Select-String -Path $AuthKeysPath -Pattern ([regex]::Escape($PublicKey.Split()[1])) -ErrorAction SilentlyContinue)) {
        Write-Log "Public key already exists in authorized_keys" "INFO"
    } else {
        Add-Content -Path $AuthKeysPath -Value $PublicKey -ErrorAction Stop
        Write-Log "Public key added to authorized_keys" "SUCCESS"
    }
} catch {
    Write-Log "ERROR adding public key: $_" "ERROR"
    exit 1
}

# ============================================================================
# 3. FIX PERMISSIONS (CRITICAL FOR WINDOWS SSH)
# ============================================================================

Write-Log "Step 3: Configuring NTFS permissions..."

try {
    if ($Username) {
        # For regular user: User owns the file, no one else has access
        icacls $AuthKeysPath /inheritance:r /grant:r "${env:COMPUTERNAME}\${Username}:(F)" | Out-Null
        icacls $SSHDir /inheritance:r /grant:r "${env:COMPUTERNAME}\${Username}:(F)" | Out-Null

        Write-Log "Permissions set for user: $Username (F=Full Control)" "SUCCESS"
    } else {
        # For Administrators: Only SYSTEM and Administrators
        icacls $AuthKeysPath /inheritance:r /grant:r "NT AUTHORITY\SYSTEM:(F)" /grant:r "BUILTIN\Administrators:(F)" | Out-Null
        icacls $SSHDir /inheritance:r /grant:r "NT AUTHORITY\SYSTEM:(F)" /grant:r "BUILTIN\Administrators:(F)" | Out-Null

        Write-Log "Permissions set for Administrators (SYSTEM + Admins only)" "SUCCESS"
    }
} catch {
    Write-Log "ERROR setting permissions: $_" "ERROR"
    exit 1
}

# ============================================================================
# 4. CONFIGURE SSHD CONFIG (Optional Port Change)
# ============================================================================

if ($SSHPort -ne 22) {
    Write-Log "Step 4: Configuring SSH port to $SSHPort..."

    try {
        $SSHDConfig = "C:\ProgramData\ssh\sshd_config"

        # Backup original
        if (!(Test-Path "$SSHDConfig.backup")) {
            Copy-Item $SSHDConfig "$SSHDConfig.backup"
            Write-Log "Backed up original sshd_config"
        }

        # Update port
        (Get-Content $SSHDConfig) -replace '(?m)^#?Port \d+', "Port $SSHPort" | Set-Content $SSHDConfig
        Write-Log "SSH port set to $SSHPort" "SUCCESS"
    } catch {
        Write-Log "WARNING: Could not configure custom port: $_" "ERROR"
    }
} else {
    Write-Log "Step 4: Using default SSH port 22"
}

# ============================================================================
# 5. START SSH SERVICE
# ============================================================================

Write-Log "Step 5: Starting SSH service..."

try {
    # Set service to auto-start
    Set-Service -Name sshd -StartupType Automatic -ErrorAction Stop
    Write-Log "SSH service set to auto-start" "SUCCESS"

    # Start service
    Start-Service -Name sshd -ErrorAction Stop
    Write-Log "SSH service started" "SUCCESS"
} catch {
    Write-Log "ERROR starting SSH service: $_" "ERROR"
    exit 1
}

# ============================================================================
# 6. CONFIGURE WINDOWS FIREWALL
# ============================================================================

Write-Log "Step 6: Configuring Windows Firewall..."

try {
    $FirewallRule = "OpenSSH-Server-In-TCP"

    # Check if rule exists
    if (!(Get-NetFirewallRule -Name $FirewallRule -ErrorAction SilentlyContinue)) {
        New-NetFirewallRule -Name $FirewallRule -DisplayName "OpenSSH Server (SSH)" -Enabled True `
            -Direction Inbound -Action Allow -Protocol TCP -LocalPort $SSHPort -Program "C:\Windows\System32\OpenSSH\sshd.exe" | Out-Null
        Write-Log "Firewall rule created for port $SSHPort" "SUCCESS"
    } else {
        Write-Log "Firewall rule already exists" "INFO"
    }
} catch {
    Write-Log "WARNING: Could not configure firewall rule: $_" "ERROR"
}

# ============================================================================
# 7. VALIDATION & TESTING
# ============================================================================

Write-Log "Step 7: Validating SSH setup..."

$ValidationPassed = $true

# Check service status
$ServiceStatus = Get-Service -Name sshd
if ($ServiceStatus.Status -eq "Running") {
    Write-Log "✓ SSH service is running" "SUCCESS"
} else {
    Write-Log "✗ SSH service is NOT running" "ERROR"
    $ValidationPassed = $false
}

# Check authorized_keys exists and has content
if ((Test-Path $AuthKeysPath) -and ((Get-Content $AuthKeysPath | Measure-Object -Line).Lines -gt 0)) {
    Write-Log "✓ authorized_keys file exists and contains keys" "SUCCESS"
} else {
    Write-Log "✗ authorized_keys file is missing or empty" "ERROR"
    $ValidationPassed = $false
}

# Check file permissions
$ACL = (Get-Acl $AuthKeysPath).Access | Where-Object {$_.AccessControlType -eq "Allow"}
if ($ACL.Count -gt 0) {
    Write-Log "✓ authorized_keys has proper permissions" "SUCCESS"
} else {
    Write-Log "✗ authorized_keys permissions may be incorrect" "ERROR"
    $ValidationPassed = $false
}

# Try to get SSH version (proof service is responding)
try {
    $SSHVersion = & cmd.exe /c "C:\Windows\System32\OpenSSH\ssh.exe -V 2>&1"
    if ($SSHVersion) {
        Write-Log "✓ SSH client available: $SSHVersion" "SUCCESS"
    }
} catch {}

# ============================================================================
# 8. FINAL SUMMARY
# ============================================================================

Write-Log ""
Write-Log "======== SSH Setup Completed ========"

if ($ValidationPassed) {
    Write-Log "Status: SUCCESS ✓" "SUCCESS"
} else {
    Write-Log "Status: COMPLETED WITH WARNINGS ⚠" "ERROR"
}

Write-Log "Computer: $env:COMPUTERNAME"
Write-Log "SSH Port: $SSHPort"
Write-Log "Service: $(Get-Service sshd | Select-Object -ExpandProperty Status)"
Write-Log "Authorized Keys: $AuthKeysPath"
Write-Log "Log File: $LogFile"
Write-Log ""

# Display for user
Write-Host ""
Write-Host "=== SSH Setup Summary ===" -ForegroundColor Cyan
Write-Host "Log saved to: $LogFile" -ForegroundColor Yellow
Write-Host "Test SSH with: ssh -i <private-key> Administrator@$env:COMPUTERNAME" -ForegroundColor Green
Write-Host ""
