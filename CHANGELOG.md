# Changelog

All notable changes to AXIS will be documented in this file.

## [1.1.0] - 2025-01-07

### Added
- **Multiple Credential Support** - Store and use multiple username/password pairs
  - Add, view, and remove credentials via menu
  - AXIS automatically tries each credential until one works
  - Perfect for environments with different admin accounts for Linux/Windows
- **Single Host Scan** - New option to scan just one IP address
  - Great for adding new hosts to your environment
  - Shows detailed results on screen
  - Option to save to CSV
- **Credential Labels** - Name each credential (e.g., "Linux Admin", "Windows Admin")

### Changed
- **Improved Solaris Scanning** - Simplified commands for better remote execution
  - Removed complex sudo pipes that failed remotely
  - Better compatibility with Solaris 10 and 11
- **Menu Reorganization** - Clearer menu structure
  - Scan options grouped together
  - Credential management has its own submenu
- **Version bumped to 1.1.0**

### Fixed
- Solaris prtconf commands now work reliably over SSH
- Host key caching prompts handled properly
- Windows WMI fallback improved for older systems

## [1.0.0] - 2025-01-06

### Added
- Initial release of AXIS
- **Multi-Platform Scanning**
  - Linux (RHEL, CentOS, Ubuntu, etc.) via SSH/plink
  - Solaris SPARC via SSH/plink
  - Windows via WMI/DCOM
- **Menu-Driven Interface** - Easy to use without command-line arguments
- **Air-Gapped Network Support** - No internet connectivity required
- **CSV Export** - Results saved in standard CSV format
- **Auto Host Key Handling** - SSH host keys managed automatically
- **Port Detection** - Automatic discovery of SSH (22) and WMI (135) hosts

### Features
- Subnet scanning with CIDR notation
- Connection testing for single hosts
- Configurable timeout settings
- Progress indicators during scans
- OS type auto-detection
- Virtual machine detection
- Hardware inventory (manufacturer, model, serial)
- Software inventory (OS, kernel, firmware)

## [0.9.0] - 2025-01-05 (Pre-release)

### Added
- Project renamed from PNIS to AXIS
- PowerShell version created (Axis.ps1)
- Bash version created (Axis.sh)
- Basic scanning functionality
- ASCII banner and menu system

---

## Version Numbering

AXIS uses [Semantic Versioning](https://semver.org/):

- **MAJOR** version for incompatible changes
- **MINOR** version for new functionality (backwards compatible)
- **PATCH** version for bug fixes (backwards compatible)
