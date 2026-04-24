# SSH Setup Guide for Company Windows PCs

## Quick Start

### Option 1: Single PC (Local)
```powershell
# Run as Administrator
.\Setup-SSH-AllComputers.ps1 -PublicKey "ssh-rsa AAAA..."
```

### Option 2: Multiple PCs (Batch Deployment)
```powershell
# Run as Administrator
$Computers = @("PC-001","PC-002","PC-003","PC-004")
$PublicKey = "ssh-rsa AAAA..."

.\Deploy-SSH-AllComputers.ps1 -ComputerNames $Computers -PublicKey $PublicKey
```

---

## Step-by-Step Usage

### **1. Get Your Public Key**

If you don't have one, generate it first:

```bash
# On your SSH client machine (Linux/Mac/Windows Git Bash)
ssh-keygen -t rsa -b 4096 -f ~/.ssh/company-key -N ""
cat ~/.ssh/company-key.pub
```

Copy the entire output (starts with `ssh-rsa`).

---

### **2. Prepare the Scripts**

1. Download both scripts to a folder (e.g., `C:\SSH-Setup\`)
   - `Setup-SSH-AllComputers.ps1` — Main setup script
   - `Deploy-SSH-AllComputers.ps1` — Batch deployment script

2. Place them on a USB drive or accessible network share for office deployment

---

### **3. Deploy to Single Computer**

**On that specific PC (as Administrator):**

```powershell
cd C:\SSH-Setup
.\Setup-SSH-AllComputers.ps1 -PublicKey "ssh-rsa AAAA... yourname@company"
```

---

### **4. Deploy to Multiple Computers**

**From your admin PC or server:**

```powershell
cd C:\SSH-Setup

# Define list of computers
$Computers = @(
    "PC-SALES-001",
    "PC-SALES-002",
    "PC-SALES-003",
    "PC-ADMIN-001",
    "PC-ADMIN-002"
)

# Deploy
.\Deploy-SSH-AllComputers.ps1 -ComputerNames $Computers -PublicKey "ssh-rsa AAAA..."
```

---

### **5. Verify SSH is Working**

**From your client machine:**

```bash
# Test connection
ssh -i ~/.ssh/company-key Administrator@PC-001

# You should see:
# Windows PowerShell
# Copyright (c) Microsoft Corporation. All rights reserved.
# ...
```

---

## Advanced Options

### **Custom SSH Port** (not 22)
```powershell
# Single PC
.\Setup-SSH-AllComputers.ps1 -PublicKey "ssh-rsa AAAA..." -SSHPort 2222

# Multiple PCs
.\Deploy-SSH-AllComputers.ps1 -ComputerNames $Computers -PublicKey "ssh-rsa AAAA..." -SSHPort 2222
```

### **Setup SSH for Regular User Account**
```powershell
# Instead of Administrator, use specific user
.\Setup-SSH-AllComputers.ps1 -PublicKey "ssh-rsa AAAA..." -Username "john.doe"

# Then SSH as that user
ssh -i ~/.ssh/company-key john.doe@PC-001
```

---

## What the Scripts Do

### `Setup-SSH-AllComputers.ps1`

✓ **Installs** OpenSSH Server (if missing)  
✓ **Creates** authorized_keys file with your public key  
✓ **Sets** NTFS permissions correctly (critical!)  
✓ **Starts** SSH service and enables auto-start  
✓ **Configures** Windows Firewall rules  
✓ **Validates** SSH setup  
✓ **Logs** everything to `C:\Logs\SSH-Setup-*.log`  

### `Deploy-SSH-AllComputers.ps1`

✓ **Deploys** setup script to multiple PCs (local or remote)  
✓ **Handles** offline/unreachable computers  
✓ **Creates** deployment summary report  
✓ **Tracks** success/failure per machine  

---

## Troubleshooting

### **"Access Denied" when running scripts**

Make sure you run PowerShell **as Administrator**:
1. Right-click PowerShell → Run as Administrator
2. Set execution policy if needed:
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
   ```

### **SSH connection fails**

Check the log file:
```powershell
Get-Content C:\Logs\SSH-Setup-*.log | Select-Object -Last 20
```

Common issues:
- **Wrong permissions:** Script tries to fix automatically, but manually correct with:
  ```powershell
  icacls C:\ProgramData\ssh\administrators_authorized_keys /inheritance:r /grant:r "NT AUTHORITY\SYSTEM:(F)" /grant:r "BUILTIN\Administrators:(F)"
  ```
- **Service not running:**
  ```powershell
  Start-Service sshd
  Get-Service sshd
  ```
- **Firewall blocking:** Check Windows Defender Firewall allows SSH (port 22)

### **Remote deployment fails**

If using `Deploy-SSH-AllComputers.ps1` for remote computers:
- Computers must be **online and reachable**
- PowerShell Remoting must be **enabled** on target machines (usually enabled in enterprise):
  ```powershell
  Enable-PSRemoting -Force
  ```

---

## Security Notes

⚠️ **Important:**
- These scripts run as **Administrator** — handle with care
- Public keys are stored in `C:\ProgramData\ssh\authorized_keys` (Admins only)
- Use SSH key authentication, **not passwords**
- Rotate keys periodically
- Keep private keys **secure and encrypted**

---

## Deployment Checklist

- [ ] Generate SSH key pair (if new)
- [ ] Copy public key to clipboard
- [ ] Copy scripts to USB/network share
- [ ] Get list of computer names to configure
- [ ] Run setup script(s)
- [ ] Check log files for errors
- [ ] Test SSH connection from client
- [ ] Document which machines are configured

---

## Example: Full Company Deployment

**Scenario:** 50 Windows PCs to configure, public key: `ssh-rsa AAAA...XYZ admin@company`

```powershell
# On admin PC, create list of all computers
$AllComputers = @(
    "PC-SALES-001", "PC-SALES-002", "PC-SALES-003", "PC-SALES-004", "PC-SALES-005",
    "PC-ADMIN-001", "PC-ADMIN-002", "PC-ADMIN-003",
    "PC-IT-01", "PC-IT-02",
    "SERVER-01", "SERVER-02", "SERVER-03"
    # ... add all 50
)

# Deploy
.\Deploy-SSH-AllComputers.ps1 -ComputerNames $AllComputers `
    -PublicKey "ssh-rsa AAAA...XYZ admin@company"

# Results saved to: C:\Logs\Deploy-SSH-Summary-*.log
```

---

## Questions?

Refer to the inline comments in the scripts for more details. Each section is documented.
