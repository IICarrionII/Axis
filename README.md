# AXIS - Asset eXploration & Inventory Scanner

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue.svg)](https://docs.microsoft.com/en-us/powershell/)
[![Bash](https://img.shields.io/badge/Bash-4.0%2B-green.svg)](https://www.gnu.org/software/bash/)
[![Platform](https://img.shields.io/badge/Platform-Windows%20%7C%20Linux%20%7C%20Solaris-lightgrey.svg)]()

A cross-platform, menu-driven hardware and software inventory scanner designed for air-gapped enterprise networks. AXIS collects detailed system information from Linux, Solaris SPARC, and Windows systems without requiring internet connectivity.

**Two versions available:**
- **`Axis.ps1`** - PowerShell version (Windows, or Linux/Solaris with PowerShell)
- **`Axis.sh`** - Pure Bash version (Linux/Solaris - **ZERO dependencies**)

```
     ___   ___  __ ____  _____
    /   |  \  \/ //  _/ / ___/
   / /| |   \  /  / /   \__ \ 
  / ___ |   / / _/ /   ___/ / 
 /_/  |_|  /_/ /___/  /____/  
```

## 🌟 Features

- **Cross-Platform Execution**: Run from Windows 10/11, RHEL 8/9, or Solaris 10/11
- **Multi-Target Scanning**: Scan Linux, Solaris SPARC, and Windows systems
- **Air-Gapped Ready**: No internet dependencies - perfect for isolated networks
- **Menu-Driven Interface**: No command-line flags to memorize
- **Auto-Accept SSH Keys**: Automatic host key acceptance for trusted networks
- **CSV Export**: Results exported in spreadsheet-compatible format

## 📋 Collected Information

| Field | Description |
|-------|-------------|
| Component Type | Server classification |
| Hostname | System hostname |
| IP Address | Network address |
| Virtual Asset | Yes/No - VM detection |
| Manufacturer | Hardware manufacturer |
| Model Number | Hardware model |
| Serial Number | Hardware serial |
| OS/IOS | Operating system version |
| FW Version | Firmware/BIOS version |
| Memory Size | Total RAM |
| Memory Type | Memory technology |
| Kernel Version | OS kernel version |

## 🚀 Quick Start

### On Windows (PowerShell version)

1. Download `Axis.ps1` and `plink.exe` to the same folder
2. Open PowerShell and navigate to the folder
3. Run: `.\Axis.ps1`
4. Select option `[1]` for Quick Scan
5. Enter subnet, username, and password when prompted

### On Linux/Solaris (Bash version - RECOMMENDED)

**No installation required!** The Bash version uses only built-in tools.

```bash
# Make executable
chmod +x Axis.sh

# Run AXIS
./Axis.sh
```

That's it! No PowerShell, no sshpass, no dependencies needed.

### On Linux (PowerShell version - alternative)

```bash
# Only if you prefer PowerShell and have it installed
pwsh ./Axis.ps1
```

## 📦 Requirements

### Bash Version (`Axis.sh`) - Linux/Solaris

| Requirement | Notes |
|-------------|-------|
| Bash 4.0+ | Pre-installed on all Linux/Solaris |
| SSH client | Pre-installed (`ssh`) |
| **That's it!** | No other dependencies! |

**Optional:** `sshpass` for automated password input. Without it, AXIS uses SSH key authentication.

### PowerShell Version (`Axis.ps1`) - Windows

| Requirement | Notes |
|-------------|-------|
| Windows 10/11 or Server 2016+ | Required |
| PowerShell 5.1+ | Built-in |
| plink.exe | For SSH scanning - [Download from PuTTY](https://www.chiark.greenend.org.uk/~sgtatham/putty/latest.html) |

### Target Systems

| Platform | Requirements |
|----------|--------------|
| Linux | SSH enabled (port 22), user with sudo access |
| Solaris | SSH enabled (port 22), user with sudo access |
| Windows | WinRM enabled (port 5985) - Run `Enable-PSRemoting -Force` |

## 📖 Menu Options

```
┌─────────────────────────────────────────────────────────────┐
│                      MAIN MENU                              │
├─────────────────────────────────────────────────────────────┤
│   [1]  Quick Scan (All Platforms)                           │
│   [2]  Scan Linux/Solaris Only                              │
│   [3]  Scan Windows Only                                    │
│   [4]  Custom Scan (Advanced Options)                       │
│   [5]  Configure Settings                                   │
│   [6]  View Current Settings                                │
│   [7]  Test Connection to Single Host                       │
│   [8]  Help / Instructions                                  │
│   [9]  About                                                │
│   [0]  Exit                                                 │
└─────────────────────────────────────────────────────────────┘
```

## 🔧 Configuration

### Passwordless Sudo (Recommended)

For complete hardware information collection, configure passwordless sudo for `dmidecode`:

**Linux (RHEL/CentOS):**
```bash
echo "username ALL=(ALL) NOPASSWD: /usr/sbin/dmidecode" | sudo tee /etc/sudoers.d/axis
```

**Solaris:**
```bash
echo "username ALL=(ALL) NOPASSWD: /usr/sbin/prtconf, /usr/sbin/prtdiag, /usr/sbin/sneep" | sudo tee /etc/sudoers.d/axis
```

### Enable WinRM on Windows Targets

Run as Administrator on each Windows target:
```powershell
Enable-PSRemoting -Force
```

## 📁 Project Structure

```
Axis/
├── Axis.ps1              # PowerShell version (Windows)
├── Axis.sh               # Bash version (Linux/Solaris) - NO DEPENDENCIES
├── README.md             # This file
├── LICENSE               # MIT License
├── CHANGELOG.md          # Version history
├── docs/
│   ├── INSTALL.md        # Detailed installation guide
│   ├── USAGE.md          # Usage examples
│   └── TROUBLESHOOTING.md # Common issues and solutions
└── examples/
    └── sample_output.csv # Example scan output
```

## 🔍 Example Output

```csv
"Component Type","Hostname","IP Address","Virtual Asset","Manufacturer","Model Number","Serial Number","OS/IOS","FW Version","Memory Size","Memory Type","Kernel Version","OS Type","Scan Status"
"Server","webserver01","192.168.1.10","Yes","VMware, Inc.","VMware Virtual Platform","VMware-42 1a...","Red Hat Enterprise Linux 8.9","6.00","16Gi","DDR4","4.18.0-513.el8.x86_64","Linux","Success"
"Server","dbserver01","192.168.1.20","No","Dell Inc.","PowerEdge R640","ABC1234","Red Hat Enterprise Linux 9.3","2.12.2","64Gi","DDR4","5.14.0-362.el9.x86_64","Linux","Success"
"Server","solaris01","192.168.1.30","No","Oracle Corporation","SPARC T5-2","1234567890","SunOS 5.11 Oracle Solaris 11.4","OBP 4.38.0","128 GB","Unknown","11.4","Solaris","Success"
```

## 🐛 Troubleshooting

### plink.exe not found (Windows)
Download `plink.exe` from [PuTTY downloads](https://www.chiark.greenend.org.uk/~sgtatham/putty/latest.html) and place it in the same folder as `Axis.ps1`.

### SSH Permission Denied
1. Verify username and password are correct
2. Check SSH configuration: `grep PasswordAuthentication /etc/ssh/sshd_config`
3. Ensure `PasswordAuthentication yes` is set

### Hardware Info Shows "Unknown"
Configure passwordless sudo for dmidecode (see Configuration section above).

### Windows Hosts Not Detected
Ensure WinRM is enabled on target: `Test-WSMan -ComputerName <ip>`

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👤 Author

**Yan Carrion**

- GitHub: [@IICarrionII](https://github.com/IICarrionII)

## 🤝 Contributing

Contributions, issues, and feature requests are welcome! Feel free to check the [issues page](https://github.com/IICarrionII/Axis/issues).

## ⭐ Show Your Support

Give a ⭐️ if this project helped you!

---

*Built for IT asset management and compliance reporting in enterprise environments.*
