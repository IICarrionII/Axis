# AXIS - Asset eXploration & Inventory Scanner

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue.svg)](https://docs.microsoft.com/en-us/powershell/)
[![Platform](https://img.shields.io/badge/Platform-Windows%20%7C%20Linux%20%7C%20Solaris-lightgrey.svg)]()

A cross-platform, menu-driven hardware and software inventory scanner designed for **air-gapped enterprise networks**. AXIS collects detailed system information from Linux, Solaris SPARC, and Windows systems without requiring internet connectivity.

## ✨ Features

- **Multi-Platform Scanning** - Scan Linux, Solaris SPARC, and Windows from a single tool
- **Multiple Credential Support** - Store multiple username/password pairs for different systems
- **Single Host or Subnet Scanning** - Scan one IP or an entire subnet range
- **Air-Gapped Ready** - No internet required, works in isolated networks
- **Auto Host Key Acceptance** - SSH host keys are handled automatically
- **CSV Export** - Results saved in CSV format for easy reporting
- **Menu-Driven Interface** - Easy to use, no command-line arguments needed

## 🚀 Quick Start

### 1. Download and Setup

```
Axis/
├── Axis.ps1          # Main scanner (rename from .txt if needed)
├── plink.exe         # Required - download from putty.org
└── (other files)
```

### 2. Get plink.exe

Download `plink.exe` from [PuTTY](https://www.chiark.greenend.org.uk/~sgtatham/putty/latest.html) and place it in the same folder as Axis.ps1.

### 3. Run AXIS

```powershell
# Open PowerShell and navigate to the Axis folder
cd C:\Tools\Axis

# Run the script
.\Axis.ps1
```

### 4. Add Credentials

1. Select `[5] Manage Credentials`
2. Select `[1] Add Credential`
3. Add your Linux admin account (e.g., "Linux Admin" / linuxadmin / password)
4. Add your Windows admin account (e.g., "Windows Admin" / winadmin / password)

### 5. Start Scanning

- **Single Host:** Select `[2] Scan Single Host` → Enter IP
- **Subnet:** Select `[1] Scan Subnet (All Platforms)` → Enter subnet (e.g., 192.168.1.0/24)

## 📋 Menu Options

```
┌─────────────────────────────────────────────────────────────┐
│                      MAIN MENU                              │
├─────────────────────────────────────────────────────────────┤
│   [1]  Scan Subnet (All Platforms)                          │
│   [2]  Scan Single Host                                     │
│   [3]  Scan Subnet - Linux/Solaris Only                     │
│   [4]  Scan Subnet - Windows Only                           │
│                                                             │
│   [5]  Manage Credentials                                   │
│   [6]  Configure Settings                                   │
│   [7]  View Current Settings                                │
│                                                             │
│   [8]  Help / Instructions                                  │
│   [9]  About                                                │
│                                                             │
│   [0]  Exit                                                 │
└─────────────────────────────────────────────────────────────┘
```

## 📦 Requirements

| Component | Requirement | Notes |
|-----------|-------------|-------|
| OS | Windows 10/11 or Server 2016+ | Run AXIS from here |
| PowerShell | 5.1 or higher | Built-in on Windows 10+ |
| plink.exe | Required for SSH | [Download from PuTTY](https://www.chiark.greenend.org.uk/~sgtatham/putty/latest.html) |

### Target System Requirements

| Target OS | Protocol | Port | Requirements |
|-----------|----------|------|--------------|
| Linux | SSH | 22 | SSH enabled, user with sudo access |
| Solaris | SSH | 22 | SSH enabled, user with access to prtconf |
| Windows | WMI/DCOM | 135 | Admin credentials, WMI enabled (default) |

## 📊 Data Collected

AXIS collects the following information from each system:

| Field | Description |
|-------|-------------|
| Hostname | System hostname |
| IP Address | Target IP address |
| OS Type | Linux, Solaris, or Windows |
| OS/IOS | Full OS name and version |
| Virtual Asset | Yes/No - Virtual machine detection |
| Manufacturer | Hardware manufacturer |
| Model Number | Hardware model |
| Serial Number | System serial number |
| Memory Size | Total RAM |
| Memory Type | RAM type (DDR4, etc.) |
| Kernel Version | OS kernel/build version |
| Firmware Version | BIOS/firmware version |
| Scan Status | Success or failure reason |

## 🔐 Multiple Credentials

AXIS supports multiple credential sets for environments with different admin accounts:

1. **Add credentials** via `[5] Manage Credentials`
2. **Label each credential** (e.g., "Linux Admin", "Windows Admin", "Solaris Root")
3. **During scanning**, AXIS tries each credential until one works
4. **Different hosts** can authenticate with different credentials automatically

Example setup:
```
Credential 1: "Linux Admin"    → linuxadmin / password1
Credential 2: "Windows Admin"  → DOMAIN\winadmin / password2
Credential 3: "Solaris Admin"  → root / password3
```

## 📁 Output

Results are saved as CSV files:

- **Subnet scan:** `AXIS_Inventory_YYYYMMDD_HHMMSS.csv`
- **Single host:** `AXIS_SingleHost_192_168_1_100_YYYYMMDD_HHMMSS.csv`

### Sample Output

```csv
"Component Type","Hostname","IP Address","Virtual Asset","Manufacturer","Model Number","Serial Number","OS/IOS","FW Version","Memory Size","Memory Type","Kernel Version","OS Type","Scan Status"
"Server","webserver01","192.168.1.10","Yes","VMware, Inc.","VMware Virtual Platform","VMware-42 1a...","Red Hat Enterprise Linux 8.9","6.00","7.6Gi","DDR4","4.18.0-513.el8.x86_64","Linux","Success"
"Server","dbserver01","192.168.1.20","No","Dell Inc.","PowerEdge R740","ABC1234","Windows Server 2019 10.0.17763","2.12.0","64 GB","Unknown","17763","Windows","Success"
```

## 🔧 Troubleshooting

### SSH Host Key Prompt

If plink asks to cache a host key, AXIS will open a window where you can type `y` to accept. This only happens once per host.

### Windows WMI Access Denied

Ensure the firewall allows WMI:
```cmd
netsh advfirewall firewall set rule group="Windows Management Instrumentation (WMI)" new enable=yes
```

### Solaris Commands Return Unknown

Make sure the scanning user has access to:
- `/usr/sbin/prtconf`
- `/usr/bin/hostid`
- `hostname`

### Credential Issues

If scans fail with authentication errors:
1. Verify credentials work manually (SSH/RDP to the target)
2. Check that you have the right username format (DOMAIN\user for Windows)
3. Add multiple credentials if different systems use different accounts

## 📂 Project Structure

```
Axis/
├── Axis.ps1              # Main PowerShell scanner
├── Axis.sh               # Bash version (Linux/Solaris only)
├── plink.exe             # Place here (download from putty.org)
├── README.md             # This file
├── LICENSE               # MIT License
├── CHANGELOG.md          # Version history
├── docs/
│   ├── INSTALL.md        # Detailed installation guide
│   ├── USAGE.md          # Usage examples
│   └── TROUBLESHOOTING.md
├── examples/
│   └── sample_output.csv
└── tools/
    └── README.txt        # Instructions for Bash version tools
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👤 Author

**Yan Carrion**

- GitHub: [@IICarrionII](https://github.com/IICarrionII)

## 🙏 Acknowledgments

- [PuTTY](https://www.chiark.greenend.org.uk/~sgtatham/putty/) for plink.exe
- Designed for enterprise IT teams managing air-gapped networks
