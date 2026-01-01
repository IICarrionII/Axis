# AXIS Usage Guide

This guide covers how to use AXIS effectively for network inventory scanning.

## Table of Contents

1. [Starting AXIS](#starting-axis)
2. [Quick Scan](#quick-scan)
3. [Platform-Specific Scans](#platform-specific-scans)
4. [Configuring Settings](#configuring-settings)
5. [Testing Connections](#testing-connections)
6. [Understanding Output](#understanding-output)
7. [Advanced Usage](#advanced-usage)

---

## Starting AXIS

### On Windows

```powershell
# Navigate to AXIS folder
cd C:\Tools\Axis

# Run AXIS
.\Axis.ps1
```

### On Linux

```bash
# Navigate to AXIS folder
cd ~/Axis

# Run AXIS
pwsh ./Axis.ps1
```

You'll see the main menu:

```
     ___   ___  __ ____  _____
    /   |  \  \/ //  _/ / ___/
   / /| |   \  /  / /   \__ \ 
  / ___ |   / / _/ /   ___/ / 
 /_/  |_|  /_/ /___/  /____/  

  ╔═══════════════════════════════════════════════════════════╗
  ║   AXIS - Asset eXploration & Inventory Scanner            ║
  ╚═══════════════════════════════════════════════════════════╝

  [1]  Quick Scan (All Platforms)
  [2]  Scan Linux/Solaris Only
  [3]  Scan Windows Only
  ...
```

---

## Quick Scan

The quickest way to scan your network:

1. Press `1` to select "Quick Scan (All Platforms)"
2. Enter your subnet in CIDR notation:
   ```
   Enter subnet (e.g., 192.168.1.0/24): 10.0.1.0/24
   ```
3. Enter username:
   ```
   Enter username: admin
   ```
4. Enter password:
   ```
   Enter password: yourpassword
   ```
5. Confirm to start:
   ```
   Proceed with scan? (Y/N): Y
   ```

AXIS will:
- Generate list of all IPs in the subnet
- Scan for SSH (port 22) and WinRM (port 5985) hosts
- Detect OS type for each host
- Collect hardware and software information
- Export results to CSV

---

## Platform-Specific Scans

### Linux/Solaris Only (Option 2)

Use when you only have Unix-like systems:
- Scans only SSH hosts (port 22)
- Auto-detects Linux vs Solaris
- Faster if you have no Windows servers

### Windows Only (Option 3)

Use when you only have Windows systems:
- Scans only WinRM hosts (port 5985)
- Uses PowerShell remoting
- Requires WinRM enabled on targets

### Custom Scan (Option 4)

Choose exactly what to scan:
```
Scan SSH hosts (Linux/Solaris)? (Y/N): Y
Scan WinRM hosts (Windows)? (Y/N): N
```

---

## Configuring Settings

Access settings with option `[5]`:

```
┌─────────────────────────────────────────────────────────────┐
│                   SETTINGS                                  │
├─────────────────────────────────────────────────────────────┤
│   [1]  Set Subnet                                           │
│   [2]  Set Username                                         │
│   [3]  Set Password                                         │
│   [4]  Set Output Path                                      │
│   [5]  Set Timeout                                          │
│   [6]  Set Thread Count                                     │
│   [0]  Back to Main Menu                                    │
└─────────────────────────────────────────────────────────────┘
```

### Settings Explained

| Setting | Description | Default |
|---------|-------------|---------|
| Subnet | Network range in CIDR notation | None (required) |
| Username | Account for authentication | None (required) |
| Password | Password for authentication | None (required) |
| Output Path | Where to save CSV file | `.\AXIS_Inventory_TIMESTAMP.csv` |
| Timeout | Seconds per command | 60 |
| Thread Count | Concurrent operations | 10 |

### Pre-Configuring Settings

Configure all settings before scanning:

1. Press `5` for Settings
2. Press `1` and enter subnet
3. Press `2` and enter username
4. Press `3` and enter password
5. Press `0` to return to main menu
6. Press `1` to start Quick Scan (won't ask again)

---

## Testing Connections

Before scanning 150+ hosts, test with one:

1. Press `7` for "Test Connection to Single Host"
2. Enter an IP address: `192.168.1.100`
3. Enter username and password (if not set)
4. Watch the results:

```
Testing connection to 192.168.1.100...

[1/3] Checking SSH port (22)... OPEN
[2/3] Checking WinRM port (5985)... CLOSED
[3/3] Testing authentication... SUCCESS

Output:
  webserver01
```

If test fails, check:
- Network connectivity
- Username/password
- SSH/WinRM configuration on target

---

## Understanding Output

### Console Output During Scan

```
Phase 1: Discovering hosts...
SSH hosts found: 45
WinRM hosts found: 12

Phase 2: Collecting system information...
[1/57] 192.168.1.10 [Linux] ✓ webserver01
[2/57] 192.168.1.11 [Linux] ✓ webserver02
[3/57] 192.168.1.20 [Solaris] ✓ dbserver01
[4/57] 192.168.1.30 [Windows] ✓ DC01
[5/57] 192.168.1.31 [Linux] ✗
```

- `✓` = Success (hostname shown)
- `✗` = Failed (check CSV for error details)

### CSV Output

Results are saved to CSV with these columns:

| Column | Description |
|--------|-------------|
| Component Type | Always "Server" |
| Hostname | System hostname |
| IP Address | Target IP |
| Virtual Asset | Yes/No |
| Manufacturer | Hardware vendor |
| Model Number | Hardware model |
| Serial Number | Hardware serial |
| OS/IOS | Operating system |
| FW Version | Firmware/BIOS |
| Memory Size | Total RAM |
| Memory Type | DDR4, etc. |
| Kernel Version | OS kernel |
| OS Type | Linux/Solaris/Windows |
| Scan Status | Success or failure reason |

### Results Summary

After scan completes:

```
═══════════════════════════════════════════════════════════
                       RESULTS
═══════════════════════════════════════════════════════════

✓ Saved: .\AXIS_Inventory_20241219_143022.csv

Total scanned:  57
Successful:     54
Failed:         3
Scan time:      12.5 minutes

By OS Type:
  Linux: 42
  Windows: 10
  Solaris: 2

Virtual:  38
Physical: 16
```

---

## Advanced Usage

### Scanning Multiple Subnets

Run AXIS multiple times with different subnets:

```powershell
# Scan first subnet
.\Axis.ps1
# Configure: 10.0.1.0/24, run scan

# Scan second subnet
.\Axis.ps1
# Configure: 10.0.2.0/24, run scan

# Combine CSVs in Excel
```

### Scanning Single IP

Use /32 CIDR notation:
```
Enter subnet: 192.168.1.100/32
```

### Adjusting for Slow Networks

Increase timeout for slow or congested networks:

1. Go to Settings (option 5)
2. Set Timeout (option 5): `120` seconds
3. Run scan

### Reducing Network Load

Decrease thread count:

1. Go to Settings (option 5)
2. Set Thread Count (option 6): `5` threads
3. Run scan

---

## Tips and Best Practices

1. **Always test first**: Use option 7 before full scans
2. **Start small**: Test with a /28 or /27 before scanning /24
3. **Off-peak scanning**: Run during maintenance windows
4. **Save settings**: Configure all settings before scanning
5. **Check failures**: Review CSV for failed hosts and errors
6. **Passwordless sudo**: Configure for complete hardware info
