# AXIS Usage Guide

## Starting AXIS

```powershell
cd C:\Tools\Axis
.\Axis.ps1
```

## Main Menu Overview

```
[1]  Scan Subnet (All Platforms)      - Scan entire subnet for all OS types
[2]  Scan Single Host                 - Scan just one IP address
[3]  Scan Subnet - Linux/Solaris Only - Skip Windows hosts
[4]  Scan Subnet - Windows Only       - Skip Linux/Solaris hosts

[5]  Manage Credentials               - Add/view/remove login credentials
[6]  Configure Settings               - Set defaults (subnet, output, timeout)
[7]  View Current Settings            - See current configuration

[8]  Help / Instructions              - Built-in help
[9]  About                            - Version and author info

[0]  Exit                             - Quit AXIS
```

## Managing Credentials

AXIS supports multiple credentials for environments with different admin accounts.

### Adding Credentials

1. Select `[5] Manage Credentials`
2. Select `[1] Add Credential`
3. Enter:
   - **Label:** A name for this credential (e.g., "Linux Admin")
   - **Username:** The login username
   - **Password:** The login password

### Example Setup

For an environment with separate Linux and Windows admins:

```
Credential 1:
  Label:    Linux Admin
  Username: linuxadmin
  Password: ********

Credential 2:
  Label:    Windows Admin
  Username: DOMAIN\winadmin
  Password: ********
```

### How Multi-Credential Works

When scanning:
1. AXIS tries the first credential
2. If authentication fails, tries the second credential
3. Continues until one works or all fail
4. Each host uses whichever credential succeeds

## Scanning a Single Host

Perfect for:
- Testing connectivity before a full scan
- Adding a new host to your inventory
- Troubleshooting a specific system

### Steps

1. Select `[2] Scan Single Host`
2. Enter the IP address
3. AXIS will:
   - Check which ports are open (SSH/WMI)
   - Detect the OS type
   - Collect system information
   - Display results on screen
4. Optionally save to CSV

### Example Output

```
Scanning 192.168.1.100...

Checking ports... SSH(22) WMI(135)
Detecting OS via SSH... Linux
Collecting system info...

═══════════════════════════════════════════════════════════
                       RESULTS
═══════════════════════════════════════════════════════════

Hostname:       webserver01
IP Address:     192.168.1.100
OS Type:        Linux
OS/IOS:         Red Hat Enterprise Linux 8.9
Manufacturer:   Dell Inc.
Model:          PowerEdge R640
Serial:         ABC1234XYZ
Memory:         64Gi
Virtual:        No
Kernel:         4.18.0-513.el8.x86_64
Firmware:       2.12.0
Status:         Success

Save to CSV? (Y/N):
```

## Scanning a Subnet

### Steps

1. Select `[1] Scan Subnet (All Platforms)`
2. Enter subnet in CIDR notation (e.g., `192.168.1.0/24`)
3. Confirm the scan
4. Wait for completion
5. Results saved to CSV automatically

### Subnet Notation Examples

| Notation | Range | Host Count |
|----------|-------|------------|
| 192.168.1.0/24 | 192.168.1.1 - 192.168.1.254 | 254 |
| 192.168.1.0/25 | 192.168.1.1 - 192.168.1.126 | 126 |
| 192.168.1.0/26 | 192.168.1.1 - 192.168.1.62 | 62 |
| 10.0.0.0/16 | 10.0.0.1 - 10.0.255.254 | 65,534 |

### Scan Process

1. **Phase 1: Discovery**
   - Checks port 22 (SSH) on each IP
   - Checks port 135 (WMI) on each IP
   - Builds list of reachable hosts

2. **Phase 2: Collection**
   - Detects OS type for each host
   - Runs appropriate commands (Linux/Solaris/Windows)
   - Collects hardware and software info
   - Shows progress: `[15/50] 192.168.1.25 [Linux] OK webserver01`

3. **Results**
   - Saves CSV file
   - Shows summary (success/fail counts)
   - Option to open CSV

### Example Scan Output

```
Phase 1: Discovering hosts...
SSH hosts found: 45
Windows hosts found: 12

Phase 2: Collecting system information...

[1/57] 192.168.1.10 [Linux] OK webserver01
[2/57] 192.168.1.11 [Linux] OK webserver02
[3/57] 192.168.1.20 [Solaris] OK dbserver01
[4/57] 192.168.1.21 [Windows] OK fileserver01
...
[57/57] 192.168.1.250 [Windows] OK dc02

═══════════════════════════════════════════════════════════
                       RESULTS
═══════════════════════════════════════════════════════════

Saved: .\AXIS_Inventory_20250107_143022.csv

Total scanned:  57
Successful:     54
Failed:         3
Scan time:      12.3 minutes

By OS Type:
  Linux: 35
  Windows: 15
  Solaris: 4
```

## Configuring Settings

Select `[6] Configure Settings` to set:

| Setting | Description |
|---------|-------------|
| Default Subnet | Pre-fill subnet for scans |
| Output Path | Where to save CSV files |
| Timeout | Seconds to wait per host (default: 60) |

## Viewing Settings

Select `[7] View Current Settings` to see:
- Current subnet
- Output path
- Timeout value
- Number of stored credentials
- plink.exe location

## Platform-Specific Scanning

### Linux/Solaris Only (Option 3)

Use when:
- Your subnet has no Windows hosts
- Windows WMI is blocked by firewall
- You only need Unix/Linux data

### Windows Only (Option 4)

Use when:
- Your subnet has no Linux/Solaris hosts
- SSH is not available
- You only need Windows data

## Tips for Large Environments

### For 100+ Hosts

1. **Set a longer timeout:** Default 60 seconds may not be enough for slow hosts
2. **Scan in segments:** Break large subnets into /25 or /26 chunks
3. **Run during off-hours:** Network traffic affects scan speed
4. **Check credentials first:** Test on a few hosts before full scan

### For Air-Gapped Networks

1. **Pre-cache host keys:** First scan will prompt for each new host
2. **Multiple credentials:** Add all admin accounts before scanning
3. **Save output locally:** Ensure output path is accessible

## Output Files

### File Naming

- Subnet scans: `AXIS_Inventory_YYYYMMDD_HHMMSS.csv`
- Single host: `AXIS_SingleHost_IP_ADDRESS_YYYYMMDD_HHMMSS.csv`

### CSV Columns

| Column | Description |
|--------|-------------|
| Component Type | Always "Server" |
| Hostname | System hostname |
| IP Address | Target IP |
| Virtual Asset | Yes/No |
| Manufacturer | Hardware vendor |
| Model Number | Hardware model |
| Serial Number | System serial |
| OS/IOS | Operating system |
| FW Version | BIOS/Firmware |
| Memory Size | Total RAM |
| Memory Type | RAM type |
| Kernel Version | OS kernel/build |
| OS Type | Linux/Solaris/Windows |
| Scan Status | Success or error message |

## Common Workflows

### Weekly Inventory Update

1. Run AXIS
2. Select `[1] Scan Subnet (All Platforms)`
3. Enter your subnet
4. Wait for completion
5. Open CSV and compare with previous week

### Adding a New Host

1. Run AXIS
2. Select `[2] Scan Single Host`
3. Enter the new host's IP
4. Save to CSV
5. Append to master inventory

### Troubleshooting a Host

1. Run AXIS
2. Select `[2] Scan Single Host`
3. Enter the problem host's IP
4. Review on-screen results
5. Check "Scan Status" for errors
