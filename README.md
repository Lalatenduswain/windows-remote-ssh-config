# SSH Setup for Your Company Windows PCs

Your public SSH key is **pre-configured** in all scripts. Just run them!

---

## 📦 Files Included

| File | Purpose | When to Use |
|------|---------|-------------|
| **Setup-SSH-YourCompany.ps1** | Single PC setup (PowerShell) | Manually configure one PC at a time |
| **Deploy-SSH-YourCompany.ps1** | Deploy to multiple PCs (PSRemoting) | Batch deploy to 5-50 PCs |
| **Deploy-SSH-FromCSV.ps1** | Deploy using CSV file | Large deployments (50+ PCs) with tracking |
| **Install-SSH.bat** | One-click installer | Easiest - just double-click & run as admin |
| **computers-list-TEMPLATE.csv** | Computer inventory | Create your own list for CSV deployment |
| **QUICK-START.txt** | Quick reference guide | Read this first! |

---

## 🚀 Choose Your Deployment Method

### **Method 1: One-Click (Single PC) — EASIEST**
```
1. Copy Install-SSH.bat to the PC
2. Right-click → "Run as administrator"
3. Done!
```
**Best for:** Non-technical users, single machines

---

### **Method 2: PowerShell (Single PC) — Full Control**
```powershell
# Open PowerShell as Administrator
.\Setup-SSH-YourCompany.ps1
```
**Options:**
```powershell
# Custom port
.\Setup-SSH-YourCompany.ps1 -SSHPort 2222

# Specific user instead of admin
.\Setup-SSH-YourCompany.ps1 -Username "john.doe"
```
**Best for:** IT techs, custom configurations

---

### **Method 3: Batch Deployment (Multiple PCs) — Fast**
```powershell
# Open PowerShell as Administrator
$Computers = @("PC-001","PC-002","PC-003")
.\Deploy-SSH-YourCompany.ps1 -ComputerNames $Computers
```
**Best for:** 5-50 PCs on the same network

---

### **Method 4: CSV-Based Deployment (Large Scale) — RECOMMENDED**
```powershell
# 1. Create computers-list.csv with your PC names
# 2. Run:
.\Deploy-SSH-FromCSV.ps1 -CSVFile "computers-list.csv"
```
**Best for:** 50+ PCs, tracking, reporting

---

## 📋 How to Create Your CSV File

1. Open `computers-list-TEMPLATE.csv` in Excel
2. Replace with your computer names:
   ```
   ComputerName,Location,Department,SSHPort,Status,Notes
   PC-SALES-001,Office Floor 1,Sales,22,Pending,
   PC-SALES-002,Office Floor 1,Sales,22,Pending,
   PC-ADMIN-001,Office Admin,Admin,22,Pending,
   ```
3. Save as `computers-list.csv`
4. Run: `.\Deploy-SSH-FromCSV.ps1 -CSVFile "computers-list.csv"`

---

## ✅ Verify SSH is Working

From your client machine:
```bash
ssh -i your-private-key Administrator@COMPUTER-NAME
```

You should see:
```
Windows PowerShell
Copyright (c) Microsoft Corporation. All rights reserved.

PS C:\Users\Administrator>
```

---

## 🔍 What Gets Installed

✓ OpenSSH Server (Windows built-in)  
✓ Your public key added to `authorized_keys`  
✓ Proper NTFS permissions configured  
✓ Windows Firewall rules added  
✓ SSH service started & set to auto-start  
✓ Everything logged for troubleshooting  

---

## 📝 Pre-Configured Details

**Your Public Key:**
Replace with your own public key. Do not commit SSH keys to version control.
```
ssh-rsa AAAA... your-name@company
```

---

## 🛠️ Troubleshooting

### "File cannot be loaded because running scripts is disabled"
This is a PowerShell execution policy error. The script isn't digitally signed, so PowerShell is blocking it.

**Option 1: Quick Fix (One-time, No Policy Change)**
```powershell
powershell -ExecutionPolicy Bypass -File .\Setup-SSH-YourCompany.ps1
```

**Option 2: Permanent Fix (Recommended)**
First, change the execution policy:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

Then unblock the downloaded scripts:
```powershell
Get-ChildItem -Filter "*.ps1" | Unblock-File
```

Now run your script:
```powershell
.\Setup-SSH-YourCompany.ps1
```

**Option 3: Unblock Individual File**
```powershell
Unblock-File -Path .\Setup-SSH-YourCompany.ps1
.\Setup-SSH-YourCompany.ps1
```

> **Note:** `RemoteSigned` allows unsigned scripts only if they're unblocked (marked as safe). Downloaded files are automatically marked as blocked, so you must use `Unblock-File` for them to run.

### "Access Denied"
→ Run PowerShell as **Administrator** (right-click → "Run as administrator")

### "Setup script not found"
→ Make sure both `Setup-SSH-YourCompany.ps1` and deployment script are in the **same folder**

### SSH connection fails
→ Check log: `C:\Logs\SSH-Setup-*.log`
→ Verify Windows Firewall allows port 22
→ Test: `ssh -v -i key.pem Administrator@PC-NAME` (verbose mode)

### CSV deployment fails
→ Make sure CSV has `ComputerName` column
→ Check all computer names are correct and online
→ Review `C:\Logs\Deploy-SSH-Summary-*.csv`

---

## 📊 Tracking Large Deployments

After running CSV deployment:
```powershell
# View results
Import-Csv "C:\Logs\Deploy-SSH-Summary-YYYYMMDD-HHMMSS.csv" | Format-Table -AutoSize

# Export to Excel (if needed)
Import-Csv "C:\Logs\Deploy-SSH-Summary-*.csv" | Export-Csv -Path "report.csv"
```

---

## 🔒 Security Notes

- Scripts use **public key authentication** (no passwords)
- Each PC's `authorized_keys` is restricted to Admins/SYSTEM only
- Logs are saved locally on each PC
- Private keys should be kept secure (encrypted, not shared)
- Consider rotating keys periodically

---

## 📞 Support

1. **Check the log file:** `C:\Logs\SSH-Setup-*.log`
2. **Read script comments:** All scripts have detailed inline documentation
3. **Test connection:** `ssh -v -i key.pem Administrator@COMPUTER-NAME` (verbose)

---

## 💡 Examples

### Single PC, Custom Port
```powershell
.\Setup-SSH-YourCompany.ps1 -SSHPort 2222
```

### Deploy to 3 Specific PCs
```powershell
$PCs = @("DESKTOP-ABC123", "LAPTOP-XYZ789", "SERVER-001")
.\Deploy-SSH-YourCompany.ps1 -ComputerNames $PCs
```

### Large Deployment with Excel Tracking
```powershell
# 1. Create/edit computers-list.csv
# 2. Run:
.\Deploy-SSH-FromCSV.ps1 -CSVFile "computers-list.csv"
# 3. Review results:
Import-Csv C:\Logs\Deploy-SSH-Summary-*.csv | Format-Table
```

---

**Ready to start? Choose a method above and run the appropriate script!**
