# Changelog

All notable changes to AXIS will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2024-12-19

### Added
- Initial release of AXIS (Asset eXploration & Inventory Scanner)
- **Two versions:**
  - `Axis.ps1` - PowerShell version for Windows
  - `Axis.sh` - Pure Bash version for Linux/Solaris (ZERO dependencies)
- Cross-platform support (Windows, Linux, Solaris)
- Menu-driven user interface
- Linux scanning via SSH
- Solaris 10/11 SPARC support
- Windows scanning via WinRM (PowerShell version only)
- Auto-accept SSH host keys for air-gapped networks
- CSV export functionality
- Single host connection testing
- Configurable timeout settings
- Progress indicators during scanning

### Bash Version Features
- Zero dependencies - uses only built-in Linux/Solaris tools
- Works on RHEL 6/7/8/9, CentOS, Solaris 10/11
- No PowerShell or sshpass required
- Portable - just copy and run

### Supported Platforms (Run From)
- Windows 10/11
- Windows Server 2016+
- RHEL 8/9
- Solaris 10/11

### Supported Targets (Scan To)
- Linux (RHEL, CentOS, Fedora, Ubuntu, Debian, etc.)
- Solaris 10/11 SPARC
- Windows Server/Desktop

### Data Collected
- Hostname
- IP Address
- Virtual/Physical status
- Manufacturer
- Model Number
- Serial Number
- Operating System
- Kernel Version
- Firmware/BIOS Version
- Memory Size
- Memory Type

## [Unreleased]

### Planned
- Parallel scanning for faster performance
- HTML report generation
- Scheduled scan support
- Network device (Cisco, Juniper) support
- Custom field collection
- Scan profiles/templates
