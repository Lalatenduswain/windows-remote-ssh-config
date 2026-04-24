# SSH Deployment Checklist

Use this checklist to plan and track your SSH deployment across all company PCs.

---

## 📋 **Pre-Deployment Planning**

- [ ] **Inventory completed**
  - Total number of PCs to configure: _______
  - List saved in: computers-list.csv (or other)

- [ ] **Public key ready**
  - Key stored securely
  - Verified key format: `ssh-rsa AAAA...`

- [ ] **Private key accessible**
  - Private key backed up in secure location
  - Passphrase documented (password manager?)

- [ ] **Deployment method chosen**
  - [ ] Method 1: One-click (Install-SSH.bat)
  - [ ] Method 2: PowerShell (Setup-SSH-YourCompany.ps1)
  - [ ] Method 3: Batch (Deploy-SSH-YourCompany.ps1)
  - [ ] Method 4: CSV-based (Deploy-SSH-FromCSV.ps1)

- [ ] **Execution plan documented**
  - Deployment start date: _______________
  - Deployment end date: _______________
  - Owner/responsible person: _______________

---

## 🔧 **Setup & Preparation**

- [ ] **Scripts downloaded**
  - [ ] Setup-SSH-YourCompany.ps1
  - [ ] Deploy-SSH-YourCompany.ps1
  - [ ] Deploy-SSH-FromCSV.ps1
  - [ ] Install-SSH.bat
  - [ ] computers-list-TEMPLATE.csv

- [ ] **Files organized**
  - All scripts in same directory: _______
  - CSV file prepared (if using Method 4): _______
  - USB drive or network share ready: _______

- [ ] **Testing completed**
  - [ ] Tested on 1 test PC (locally)
  - [ ] SSH connection verified from client
  - [ ] Log file reviewed for any issues
  - Test PC: _______________

---

## 🚀 **Deployment Execution**

### **If using Method 1 (One-Click) or Method 2 (PowerShell):**

For each PC:
- [ ] PC Name: _______________
  - [ ] Script copied to PC
  - [ ] Run as Administrator
  - [ ] Wait for completion
  - [ ] Check log file (C:\Logs\SSH-Setup-*.log)
  - [ ] Test SSH connection
  - [ ] Status: ☐ Success  ☐ Failed

- [ ] PC Name: _______________
  - [ ] Script copied to PC
  - [ ] Run as Administrator
  - [ ] Wait for completion
  - [ ] Check log file (C:\Logs\SSH-Setup-*.log)
  - [ ] Test SSH connection
  - [ ] Status: ☐ Success  ☐ Failed

- [ ] PC Name: _______________
  - [ ] Script copied to PC
  - [ ] Run as Administrator
  - [ ] Wait for completion
  - [ ] Check log file (C:\Logs\SSH-Setup-*.log)
  - [ ] Test SSH connection
  - [ ] Status: ☐ Success  ☐ Failed

### **If using Method 3 (Batch) or Method 4 (CSV):**

- [ ] Computer list finalized
  - Total PCs in list: _______
  - CSV file validated

- [ ] Batch deployment started
  - [ ] PowerShell running as Administrator
  - [ ] Script executed: `.\Deploy-SSH-FromCSV.ps1 -CSVFile "computers-list.csv"`
  - [ ] Deployment started at: _______
  - [ ] Deployment completed at: _______

- [ ] Results reviewed
  - [ ] Successful deployments: _______
  - [ ] Failed deployments: _______
  - [ ] Summary report location: C:\Logs\Deploy-SSH-Summary-*.csv

- [ ] Failed PCs handled
  - [ ] List of failed PCs: _______________
  - [ ] Reason for each failure documented
  - [ ] Retry plan created

---

## ✅ **Post-Deployment Verification**

For each PC, verify SSH is working:

**PC #1: _______________**
- [ ] SSH connection successful
- [ ] Can log in with private key
- [ ] Can access PowerShell prompt
- [ ] Log file exists at C:\Logs\
- **Status:** ☐ Ready  ☐ Needs Fixing

**PC #2: _______________**
- [ ] SSH connection successful
- [ ] Can log in with private key
- [ ] Can access PowerShell prompt
- [ ] Log file exists at C:\Logs\
- **Status:** ☐ Ready  ☐ Needs Fixing

**PC #3: _______________**
- [ ] SSH connection successful
- [ ] Can log in with private key
- [ ] Can access PowerShell prompt
- [ ] Log file exists at C:\Logs\
- **Status:** ☐ Ready  ☐ Needs Fixing

---

## 🔧 **Troubleshooting (if needed)**

### Failed PC #1: _______________

**Error Message:**
```
[paste error from log]
```

**Attempted Fixes:**
- [ ] Restarted SSH service
- [ ] Checked Windows Firewall rules
- [ ] Verified authorized_keys permissions
- [ ] Checked log file for details
- [ ] Ran setup script manually again

**Resolution:**
- [ ] Issue resolved
- [ ] Still pending
- [ ] Escalated to: _______________

---

### Failed PC #2: _______________

**Error Message:**
```
[paste error from log]
```

**Attempted Fixes:**
- [ ] Restarted SSH service
- [ ] Checked Windows Firewall rules
- [ ] Verified authorized_keys permissions
- [ ] Checked log file for details
- [ ] Ran setup script manually again

**Resolution:**
- [ ] Issue resolved
- [ ] Still pending
- [ ] Escalated to: _______________

---

## 📊 **Summary Report**

- [ ] Total PCs targeted: _______
- [ ] Successfully configured: _______
- [ ] Failed/pending: _______
- [ ] Success rate: _______ %

**Deployment Date Range:** _____________ to _____________

**Overall Status:**
- [ ] ✓ Complete - All PCs configured
- [ ] ⚠ Partial - Some PCs still pending
- [ ] ✗ On Hold - Waiting for: _______________

**Documents/Logs Saved:**
- Deployment summary: _______________________
- Failed PC list: _______________________
- Configuration guide: _______________________

---

## 📝 **Sign-Off**

- **Deployed By:** _______________
- **Date Completed:** _______________
- **Verified By:** _______________
- **Date Verified:** _______________

**Notes:**
```
[Any additional notes, issues, or follow-ups]




```

---

## 🎯 **Post-Deployment Tasks**

- [ ] Document all SSH-enabled PCs in inventory
- [ ] Distribute SSH access guide to users
- [ ] Set up SSH key rotation schedule
- [ ] Monitor SSH logs for security issues
- [ ] Plan for backup/disaster recovery

---

## 📌 **Quick Command Reference**

**Test single PC:**
```powershell
.\Setup-SSH-YourCompany.ps1
```

**Deploy to multiple PCs:**
```powershell
$PCs = @("PC-001","PC-002","PC-003")
.\Deploy-SSH-YourCompany.ps1 -ComputerNames $PCs
```

**Deploy from CSV:**
```powershell
.\Deploy-SSH-FromCSV.ps1 -CSVFile "computers-list.csv"
```

**View deployment results:**
```powershell
Import-Csv C:\Logs\Deploy-SSH-Summary-*.csv | Format-Table -AutoSize
```

**SSH connection test:**
```bash
ssh -i your-private-key Administrator@COMPUTER-NAME
```

---

## 🆘 **Support Resources**

- **Log files:** C:\Logs\SSH-Setup-*.log
- **Deployment report:** C:\Logs\Deploy-SSH-Summary-*.csv
- **Script help:** See comments in .ps1 files
- **Documentation:** README.md, QUICK-START.txt

**Print this checklist and keep it handy during deployment!**
