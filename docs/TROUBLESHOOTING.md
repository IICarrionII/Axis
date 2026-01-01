# AXIS Troubleshooting Guide

This guide helps resolve common issues with AXIS.

## Table of Contents

1. [Installation Issues](#installation-issues)
2. [Connection Issues](#connection-issues)
3. [Authentication Issues](#authentication-issues)
4. [Data Collection Issues](#data-collection-issues)
5. [Performance Issues](#performance-issues)
6. [Platform-Specific Issues](#platform-specific-issues)

---

## Installation Issues

### plink.exe not found (Windows)

**Symptom:**
```
WARNING: plink.exe not found!
SSH scanning (Linux/Solaris) will not work.
```

**Solution:**
1. Download plink.exe from [PuTTY](https://www.chiark.greenend.org.uk/~sgtatham/putty/latest.html)
2. Place in same folder as Axis.ps1
3. Restart AXIS

**Verification:**
```powershell
# In the Axis folder
dir plink.exe
```

### sshpass not found (Linux)

**Symptom:**
```
WARNING: sshpass not found!
Password authentication may not work.
```

**Solution:**
```bash
# RHEL/CentOS
sudo dnf install -y sshpass

# Ubuntu/Debian
sudo apt install -y sshpass
```

### PowerShell not found (Linux)

**Symptom:**
```
pwsh: command not found
```

**Solution:**
```bash
# RHEL 8/9
curl https://packages.microsoft.com/config/rhel/8/prod.repo | sudo tee /etc/yum.repos.d/microsoft.repo
sudo dnf install -y powershell
```

---

## Connection Issues

### Port 22 Closed

**Symptom:**
```
[1/3] Checking SSH port (22)... CLOSED
```

**Causes & Solutions:**

1. **SSH not running on target:**
   ```bash
   # On target system
   sudo systemctl status sshd
   sudo systemctl start sshd
   sudo systemctl enable sshd
   ```

2. **Firewall blocking:**
   ```bash
   # RHEL/CentOS
   sudo firewall-cmd --add-service=ssh --permanent
   sudo firewall-cmd --reload
   ```

3. **Network issue:**
   ```powershell
   # Test connectivity
   Test-NetConnection -ComputerName 192.168.1.100 -Port 22
   ```

### Port 5985 Closed (Windows)

**Symptom:**
```
[2/3] Checking WinRM port (5985)... CLOSED
```

**Solution on Windows target:**
```powershell
# Run as Administrator
Enable-PSRemoting -Force
Set-Item WSMan:\localhost\Client\TrustedHosts -Value "*" -Force
```

### Connection Timeout

**Symptom:**
```
[3/3] Testing authentication... FAILED
Error: Timeout
```

**Solutions:**

1. **Increase timeout:**
   - Settings → Set Timeout → 90 or 120 seconds

2. **Check network latency:**
   ```powershell
   ping 192.168.1.100
   ```

3. **Check for slow DNS:**
   - Try using IP address instead of hostname

---

## Authentication Issues

### Permission Denied (SSH)

**Symptom:**
```
Error: Permission denied
```

**Solutions:**

1. **Verify credentials:**
   ```bash
   # Manual test
   ssh username@192.168.1.100
   ```

2. **Check SSH configuration:**
   ```bash
   # On target
   sudo grep PasswordAuthentication /etc/ssh/sshd_config
   # Should be: PasswordAuthentication yes
   
   # If not, edit and restart
   sudo vi /etc/ssh/sshd_config
   sudo systemctl restart sshd
   ```

3. **Check user exists:**
   ```bash
   # On target
   id username
   ```

### Access Denied (Windows)

**Symptom:**
```
Failed: Access is denied
```

**Solutions:**

1. **Try different username formats:**
   - `username`
   - `DOMAIN\username`
   - `username@domain.local`

2. **Check account permissions:**
   - User must be local admin or domain admin

3. **Check WinRM settings:**
   ```powershell
   # On target
   winrm get winrm/config/service/auth
   ```

4. **Add to TrustedHosts (on scanning system):**
   ```powershell
   Set-Item WSMan:\localhost\Client\TrustedHosts -Value "*" -Force
   ```

---

## Data Collection Issues

### Hardware Info Shows "Unknown"

**Symptom:**
```csv
"Manufacturer","Model Number","Serial Number"
"Unknown","Unknown","Unknown"
```

**Cause:** User lacks sudo access for dmidecode

**Solution (Linux):**
```bash
# On each target
echo "username ALL=(ALL) NOPASSWD: /usr/sbin/dmidecode" | sudo tee /etc/sudoers.d/axis
sudo chmod 440 /etc/sudoers.d/axis
```

**Solution (Solaris):**
```bash
echo "username ALL=(ALL) NOPASSWD: /usr/sbin/prtconf, /usr/sbin/prtdiag, /usr/sbin/sneep" | sudo tee /etc/sudoers.d/axis
```

### Virtual Asset Always "Unknown"

**Cause:** systemd-detect-virt not available

**For RHEL/CentOS:**
```bash
sudo dnf install -y systemd
```

**For Solaris:**
- Uses virtinfo command
- May show Unknown on physical systems without virtinfo

### Memory Type Unknown

**Cause:** dmidecode memory type not readable

**This is normal for:**
- Virtual machines
- Some older hardware
- Systems without SMBIOS support

---

## Performance Issues

### Scan is Very Slow

**Solutions:**

1. **Reduce timeout:**
   - Settings → Set Timeout → 30 seconds

2. **Increase threads (port scan only):**
   - Settings → Set Thread Count → 20

3. **Scan specific platforms:**
   - Option 2 (Linux only) or Option 3 (Windows only)

4. **Scan smaller subnets:**
   - Use /25 (126 hosts) instead of /24 (254 hosts)

### High Network Load

**Solutions:**

1. **Reduce threads:**
   - Settings → Set Thread Count → 5

2. **Scan during off-hours:**
   - Schedule for maintenance windows

3. **Scan in segments:**
   - Split /24 into multiple /26 scans

---

## Platform-Specific Issues

### Linux Issues

**CentOS/RHEL 6 (older):**
- May not have systemd-detect-virt
- Use `virt-what` package instead

**Ubuntu/Debian:**
- Same commands should work
- May need `apt` instead of `dnf` for packages

### Solaris Issues

**Solaris 10:**
- May lack some commands (virtinfo, sneep)
- Serial number falls back to hostid
- Some fields may show Unknown

**Solaris 11:**
- Most commands should work
- Ensure sudo is configured

**SPARC vs x86:**
- Same script works for both
- Hardware detection commands are compatible

### Windows Issues

**Windows Server Core:**
- Should work (uses CIM, not GUI)

**Windows 7/Server 2008:**
- Requires WMF 5.1 update
- WinRM may need manual configuration

**Domain vs Workgroup:**
- Domain: Use `DOMAIN\username`
- Workgroup: Use local `username`
- Both: Try `username@domain.local`

---

## Getting Help

### Collect Diagnostic Info

When reporting issues, include:

1. **AXIS version:**
   - Shown in About menu (option 9)

2. **Platform:**
   - Windows version or Linux distribution

3. **Error message:**
   - Exact text from console or CSV

4. **Test results:**
   - Output from option 7 (Test Connection)

### Debug Mode

For verbose output, run manually:
```powershell
# Windows
$VerbosePreference = "Continue"
.\Axis.ps1

# Linux
pwsh -Command '$VerbosePreference = "Continue"; ./Axis.ps1'
```

### Report Issues

Open an issue on GitHub:
https://github.com/IICarrionII/Axis/issues

Include:
- Description of problem
- Steps to reproduce
- Expected vs actual behavior
- Diagnostic info from above
