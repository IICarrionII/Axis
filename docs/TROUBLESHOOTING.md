# AXIS Troubleshooting Guide

## Installation Issues

### "plink.exe not found"

**Cause:** plink.exe is not in the same folder as Axis.ps1

**Solution:**
1. Download plink.exe from https://www.chiark.greenend.org.uk/~sgtatham/putty/latest.html
2. Place it in the same folder as Axis.ps1
3. Verify the filename is exactly `plink.exe`

### "Running scripts is disabled on this system"

**Cause:** PowerShell execution policy is restricted

**Solutions:**

```powershell
# Option 1: Run with bypass (recommended for one-time use)
powershell -ExecutionPolicy Bypass -File .\Axis.ps1

# Option 2: Change policy for current user
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Option 3: Change policy for current session
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
```

### Script opens and immediately closes

**Cause:** Usually an error before the menu loads

**Solution:**
1. Open PowerShell manually (don't double-click the script)
2. Navigate to the Axis folder: `cd C:\Tools\Axis`
3. Run: `.\Axis.ps1`
4. Read any error messages

## SSH/Linux/Solaris Issues

### "Host key not cached" prompt keeps appearing

**Cause:** Each new host requires accepting its SSH key

**Solution:**
- Type `y` and press Enter when prompted
- This only happens once per host
- Keys are cached in PuTTY's registry

### SSH connection times out

**Causes:**
- Host is unreachable
- SSH service not running
- Firewall blocking port 22
- Slow network

**Solutions:**
1. Verify SSH is running on target: `systemctl status sshd`
2. Check firewall: `firewall-cmd --list-ports`
3. Test connectivity: `ping <ip-address>`
4. Increase timeout in Settings (default 60 seconds)

### Authentication failure on Linux

**Causes:**
- Wrong username or password
- User not allowed to SSH
- SSH config restricts access

**Solutions:**
1. Test credentials manually: `ssh user@ip-address`
2. Check /etc/ssh/sshd_config for AllowUsers/DenyUsers
3. Verify the user exists on the target system
4. Add the correct credential in AXIS

### Linux scan returns "Unknown" for most fields

**Causes:**
- User doesn't have sudo access
- dmidecode not installed
- Running on a container (no hardware access)

**Solutions:**
1. Ensure user has passwordless sudo for dmidecode
2. Install dmidecode: `yum install dmidecode`
3. For containers, hardware info won't be available

### Solaris scan returns "Unknown" for most fields

**Causes:**
- User doesn't have access to system commands
- Commands have different paths on this Solaris version

**Solutions:**
1. Verify user can run: `hostname`, `/usr/sbin/prtconf`, `/usr/bin/hostid`
2. Check if sudo is needed for prtconf
3. Test commands manually on the Solaris box

## Windows Issues

### "Access is denied" or WMI connection failed

**Causes:**
- Wrong credentials
- WMI not enabled
- Firewall blocking port 135
- User not admin on target

**Solutions:**

1. **Verify credentials** - Test with:
   ```powershell
   $cred = Get-Credential
   Get-WmiObject -Class Win32_ComputerSystem -ComputerName TARGET_IP -Credential $cred
   ```

2. **Enable WMI through firewall:**
   ```cmd
   netsh advfirewall firewall set rule group="Windows Management Instrumentation (WMI)" new enable=yes
   ```

3. **Check remote WMI service:**
   ```cmd
   sc \\TARGET_IP query winmgmt
   ```

4. **Use domain admin** for domain-joined systems:
   ```
   Username: DOMAIN\administrator
   ```

### "RPC server is unavailable"

**Causes:**
- Target is offline
- Port 135 blocked
- RPC service not running

**Solutions:**
1. Ping the target to verify connectivity
2. Check port: `Test-NetConnection -ComputerName TARGET_IP -Port 135`
3. On target, verify RPC service: `services.msc` → "Remote Procedure Call (RPC)"

### Windows scan shows wrong data

**Cause:** WMI query returned unexpected results

**Solution:**
1. Test WMI directly on target:
   ```powershell
   Get-WmiObject -Class Win32_ComputerSystem
   Get-WmiObject -Class Win32_OperatingSystem
   Get-WmiObject -Class Win32_BIOS
   ```
2. Report issue if data differs from AXIS output

## Credential Issues

### "All credentials failed"

**Causes:**
- No credentials stored
- All stored credentials are wrong
- Different credentials needed for different hosts

**Solutions:**
1. Go to `[5] Manage Credentials`
2. Verify credentials are correct
3. Add additional credentials for different systems
4. Test with single host scan first

### How to handle multiple credential sets

1. Add all credential sets you use:
   - Linux admin account
   - Windows admin account
   - Solaris root account
   - Domain admin account

2. AXIS will try each one automatically

3. Label them clearly:
   ```
   [1] Linux Admin - linuxadmin
   [2] Windows Admin - DOMAIN\winadmin
   [3] Solaris Root - root
   ```

## Network Issues

### Scan is very slow

**Causes:**
- Large subnet
- Many unreachable IPs (timeout on each)
- Slow network

**Solutions:**
1. Scan smaller subnets (/25, /26)
2. Reduce timeout if hosts respond quickly
3. Scan during off-hours
4. Use platform-specific scans (Linux-only or Windows-only)

### Some hosts not discovered

**Causes:**
- Hosts are offline
- SSH/WMI ports are closed
- Firewall blocking discovery

**Solutions:**
1. Verify hosts are online: `ping <ip>`
2. Check ports: `Test-NetConnection -ComputerName IP -Port 22`
3. Review firewall rules on targets

## Output Issues

### CSV file not created

**Causes:**
- No write permission to output folder
- Scan was cancelled before completion
- Path doesn't exist

**Solutions:**
1. Check you have write access to the Axis folder
2. Set a specific output path in Settings
3. Let the scan complete fully

### CSV contains "Unknown" for all fields

**Cause:** All scans failed

**Solution:**
1. Check error messages in Scan Status column
2. Review credential configuration
3. Test single hosts to identify issues

### CSV opens incorrectly in Excel

**Cause:** Encoding or delimiter issues

**Solution:**
1. Open Excel
2. Use Data → From Text/CSV
3. Select UTF-8 encoding
4. Verify comma delimiter

## General Tips

### Before Scanning

1. Test credentials on 1-2 hosts manually
2. Verify plink.exe is present
3. Add all credential sets you'll need
4. Check network connectivity to target subnet

### During Scanning

1. Watch for patterns in failures
2. Note which credential works for which hosts
3. Let the scan complete even if some hosts fail

### After Scanning

1. Review the Scan Status column for failures
2. Check OS Type column for misdetections
3. Investigate "Unknown" values
4. Re-scan failed hosts individually

## Getting Help

If issues persist:

1. Note the exact error message
2. Note which host/OS type fails
3. Test the same credentials manually
4. Check GitHub issues: https://github.com/IICarrionII/Axis/issues
