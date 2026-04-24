# Session Log: SSH Key Authentication Setup for Windows Machine

**Date:** 2026-04-23  
**Engineer:** Lalatenduswain  
**Server/Environment:** Windows Machine (100.77.197.39, Tailscale IP), OpenSSH Server  
**Duration:** ~30 minutes  
**Status:** RESOLVED

---

## Problem Statement

User attempted to SSH into a Windows machine (100.77.197.39) running OpenSSH Server as the `administrator` user, but faced repeated authentication failures with the error message "Too many authentication failures". The machine was accessible via AnyDesk, but SSH key-based authentication needed to be configured to allow direct SSH access.

The goal was to add the user's RSA public key to the `administrator` account to enable passwordless SSH key authentication.

---

## Environment

| Key | Value |
|-----|-------|
| Server IP (Tailscale) | 100.77.197.39 |
| Server OS | Windows (OS version from Bitdefender screenshot) |
| SSH Server | OpenSSH Server (Windows native) |
| Remote User | administrator |
| Access Method | AnyDesk for initial setup, SSH for final connection |
| Client Machine | Linux (Tailscale-enabled) |

---

## Timeline & Steps

### Step 1: Initial SSH Connection Attempt (Failed)

**Action:**
```bash
ssh administrator@100.77.197.39
```

**Output:**
```
Received disconnect from 100.77.197.39 port 22:2: Too many authentication failures
Disconnected from 100.77.197.39 port 22
```

**Result:** Failed — Server rejecting all authentication attempts. Root cause unknown at this stage.

---

### Step 2: Retrieve Local Public Key

**Action:**
```bash
cat ~/.ssh/id_rsa.pub
```

**Output:**
```
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC8IdDscm8+MRACm3dpE6796u2Y+vxi9bajA/y1YKE+l4ylGNzk43YGBpSXEjMlGe5t6S+PYg6xi0Wr0wO1mROwF1RSkEYee0Pszue+kDm1yuDEk3EjasdCgrxwnz5J1T6EN2ngBjcK7ZPDvhni1fcfG1VJNblzpQlzC8vkvU4aRABCkqV4jgio/+IfXO9Qqo/0NP3IEBUHFuTbSPpMwMWDoxwIQN/K6e7nCjuQ0t+YAuQLIRRYzBDS+j79/IL2TEbD0kbopnZqaiZ94HU5KlZ1G1EmZurhQaSP6UIF+YXMqwkLFrNUuisfWXZduo3XRS4fj5xQpZNfZwNzjf6IAaQwLcRfpMpVkoYUX00hklLf0OInSDjBcGoDqBFg7NyG2Kty9Ihm9Fl+NWpbMDb0mTZ9/l1dUOy8WMzEhPlFZuSGBfLc/9L+3FQDv48HuvYyajOtmgPdytHmVc+Lbj62kX30qPq297g628vBE0PrWj/2QJGPCNeoXGfbnzmGAW2a3yU= lalatendu@sys
```

**Result:** Success — Public key retrieved for use on remote server.

---

### Step 3: Create .ssh Directory on Remote Machine (Via AnyDesk)

**Action (PowerShell on Windows):**
```powershell
mkdir "C:\Users\administrator\.ssh" -Force
```

**Output:**
```
(directory created successfully)
```

**Result:** Success — .ssh directory created in administrator's home folder.

---

### Step 4: Add Public Key to authorized_keys (First Attempt)

**Action (PowerShell on Windows):**
```powershell
Add-Content -Path "C:\Users\administrator\.ssh\authorized_keys" -Value "YOUR_PUBLIC_KEY_HERE" -Encoding UTF8
```

**Output:**
```
(file created with key)
```

**Result:** Partial Success — File created, but key was split across multiple lines in the editor (line wrapping issue).

---

### Step 5: Set ACLs on authorized_keys File

**Action (PowerShell on Windows):**
```powershell
icacls "C:\Users\administrator\.ssh\authorized_keys" /inheritance:r /grant:r "NT AUTHORITY\SYSTEM:(F)" "BUILTIN\Administrators:(F)"
```

**Output:**
```
processed file: C:\Users\administrator\.ssh\authorized_keys
Successfully processed 1 files; Failed processing 0 files
```

**Result:** Success — ACLs set correctly, restricting access to SYSTEM and Administrators only.

---

### Step 6: Restart SSH Service

**Action (PowerShell on Windows):**
```powershell
Restart-Service sshd
```

**Output:**
```
(service restarted without error)
```

**Result:** Success — SSH service restarted.

---

### Step 7: Test SSH Connection with Specific Key

**Action:**
```bash
ssh -i ~/.ssh/id_rsa administrator@100.77.197.39
```

**Output:**
```
Received disconnect from 100.77.197.39 port 22:2: Too many authentication failures
Disconnected from 100.77.197.39 port 22
```

**Result:** Failed — Still getting "Too many authentication failures" error. Issue persisted despite the key setup.

---

### Step 8: Investigate sshd Configuration

**Action (PowerShell on Windows):**
```powershell
Get-Content "C:\ProgramData\ssh\sshd_config"
```

**Output:**
```
[... full sshd_config file contents ...]

Match Group administrators
       AuthorizedKeysFile __PROGRAMDATA__/ssh/administrators_authorized_keys
```

**Result:** Success — **Found the root cause!** The sshd_config file has a special rule for users in the `administrators` group. It redirects the AuthorizedKeysFile location to `C:\ProgramData\ssh\administrators_authorized_keys` instead of the default `~/.ssh/authorized_keys`.

---

### Step 9: Clear and Re-add Public Key to Correct Location

**Action (PowerShell on Windows):**
```powershell
Clear-Content "C:\Users\administrator\.ssh\authorized_keys"

Add-Content -Path "C:\ProgramData\ssh\administrators_authorized_keys" -Value "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC8IdDscm8+MRACm3dpE6796u2Y+vxi9bajA/y1YKE+l4ylGNzk43YGBpSXEjMlGe5t6S+PYg6xi0Wr0wO1mROwF1RSkEYee0Pszue+kDm1yuDEk3EjasdCgrxwnz5J1T6EN2ngBjcK7ZPDvhni1fcfG1VJNblzpQlzC8vkvU4aRABCkqV4jgio/+IfXO9Qqo/0NP3IEBUHFuTbSPpMwMWDoxwIQN/K6e7nCjuQ0t+YAuQLIRRYzBDS+j79/IL2TEbD0kbopnZqaiZ94HU5KlZ1G1EmZurhQaSP6UIF+YXMqwkLFrNUuisfWXZduo3XRS4fj5xQpZNfZwNzjf6IAaQwLcRfpMpVkoYUX00hklLf0OInSDjBcGoDqBFg7NyG2Kty9Ihm9Fl+NWpbMDb0mTZ9/l1dUOy8WMzEhPlFZuSGBfLc/9L+3FQDv48HuvYyajOtmgPdytHmVc+Lbj62kX30qPq297g628vBE0PrWj/2QJGPCNeoXGfbnzmGAW2a3yU= lalatendu@sys" -Encoding UTF8 -NoNewline

icacls "C:\ProgramData\ssh\administrators_authorized_keys" /inheritance:r /grant:r "NT AUTHORITY\SYSTEM:(F)" "BUILTIN\Administrators:(F)"

Restart-Service sshd
```

**Output:**
```
processed file: C:\ProgramData\ssh\administrators_authorized_keys
Successfully processed 1 files; Failed processing 0 files
```

**Result:** Success — Public key added to the correct location with proper permissions and SSH service restarted.

---

### Step 10: Final SSH Connection Test

**Action:**
```bash
ssh administrator@100.77.197.39
```

**Output:**
```
Windows PowerShell
Copyright (C) Microsoft Corporation. All rights reserved.

Install the latest PowerShell for new features and improvements! https://aka.ms/PSWindows

PS C:\Users\Administrator>
```

**Result:** ✅ **Success** — SSH connection established without password prompt. User now has full remote shell access to the Windows machine.

---

## Errors Encountered

| # | Error | Cause | Resolution |
|---|-------|-------|------------|
| 1 | "Too many authentication failures" (initial) | SSH public key not installed or in wrong location | Identified `Match Group administrators` rule in sshd_config that redirects admin keys to system-wide location |
| 2 | "The system cannot find the file specified" (icacls) | Attempted to set ACLs before authorized_keys file was created | Created the file first, then applied ACLs |
| 3 | Public key split across multiple lines | Used `Out-File` without `-NoNewline` flag initially, causing PowerShell to add line breaks to the editor display | Re-added key with `-NoNewline` flag and verified it's on a single line |

---

## Root Cause Analysis

**Primary Issue:** The Windows OpenSSH Server configuration (`sshd_config`) contains a special rule for users in the `administrators` group:

```
Match Group administrators
       AuthorizedKeysFile __PROGRAMDATA__/ssh/administrators_authorized_keys
```

This rule overrides the default `AuthorizedKeysFile` location for admin accounts, redirecting it to a **system-wide file** at `C:\ProgramData\ssh\administrators_authorized_keys` instead of the user's home directory `.ssh/authorized_keys`.

**Why it Failed Initially:**
1. User's public key was added to `C:\Users\administrator\.ssh\authorized_keys`
2. SSH server looked for the key in `C:\ProgramData\ssh\administrators_authorized_keys` (due to the Match rule)
3. Server couldn't find the key and rejected the connection
4. Multiple failed attempts triggered the "Too many authentication failures" error

**Secondary Issue:** Initial attempt to add the key without the `-NoNewline` flag caused line wrapping in the file, which further corrupted the key format (SSH keys must be on a single line).

---

## Solution Summary

1. **Identified the sshd_config rule** that redirects administrator authorized_keys to a system-wide location
2. **Placed the public key in the correct location:** `C:\ProgramData\ssh\administrators_authorized_keys`
3. **Ensured single-line format** for the SSH public key (no line breaks in the middle)
4. **Set proper ACLs** restricting access to SYSTEM and Administrators only
5. **Restarted the SSH service** to apply configuration changes
6. **Verified successful connection** with passwordless key-based authentication

---

## Final Working Configuration

**Windows OpenSSH Server:**
```
Location: C:\ProgramData\ssh\
Config file: C:\ProgramData\ssh\sshd_config
sshd_config Rule:
  Match Group administrators
    AuthorizedKeysFile __PROGRAMDATA__/ssh/administrators_authorized_keys
```

**Public Key Location (for admin users):**
```
Path: C:\ProgramData\ssh\administrators_authorized_keys
Format: ssh-rsa <base64-key-data> <comment>
Permissions: Read-only for SYSTEM and Administrators
Line format: Single line (no wraps or breaks)
```

**SSH Connection (from client):**
```bash
ssh administrator@100.77.197.39
# Uses key: ~/.ssh/id_rsa (automatically selected)
# No password required
```

---

## Files Modified

| File | Change |
|------|--------|
| `C:\Users\administrator\.ssh\` | Created directory |
| `C:\Users\administrator\.ssh\authorized_keys` | Created but left empty (wrong location for admins) |
| `C:\ProgramData\ssh\administrators_authorized_keys` | **Added SSH public key (single line, correct format)** |

---

## Lessons Learned

- **Always check the sshd_config for Match rules:** Special rules can override default file locations for specific user groups. This is a common source of SSH authentication issues on Windows.
- **SSH keys must be on a single line:** Tools like PowerShell can accidentally wrap keys across multiple lines. Always use `-NoNewline` when adding keys via `Add-Content`.
- **Administrator accounts have special handling:** Windows OpenSSH treats admin users differently. Admin keys go to a system-wide location, not the user's .ssh folder.
- **Verify the actual file location:** When troubleshooting SSH issues, always check the sshd_config to see if the AuthorizedKeysFile path matches where you're placing the key.
- **ACLs matter on Windows:** Proper permissions (SYSTEM and Administrators only) are required for SSH to read the authorized_keys file.

---

## Follow-up Actions

- [x] SSH key authentication successfully established
- [ ] Consider documenting this Windows SSH setup for future reference
- [ ] Optional: Set up an SSH config entry for easier connection (`Host yeswanth`)
- [ ] Optional: Test SCP file transfers to verify full SSH functionality

**No critical follow-up actions required.** The system is now fully operational.

---

## Additional Notes

**Optional SSH Config Enhancement (for convenience):**

Add to `~/.ssh/config`:
```
Host yeswanth
    HostName 100.77.197.39
    User administrator
    IdentityFile ~/.ssh/id_rsa
```

Then connect simply with: `ssh yeswanth`

