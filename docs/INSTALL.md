# AXIS Installation Guide

This guide provides detailed installation instructions for AXIS on all supported platforms.

## Table of Contents

1. [Windows Installation](#windows-installation)
2. [Linux Installation (RHEL/CentOS)](#linux-installation-rhelcentos)
3. [Solaris Installation](#solaris-installation)
4. [Air-Gapped Network Installation](#air-gapped-network-installation)
5. [Verifying Installation](#verifying-installation)

---

## Windows Installation

### Requirements

- Windows 10/11 or Windows Server 2016+
- PowerShell 5.1 or higher (pre-installed)
- plink.exe (for SSH scanning)

### Step 1: Download AXIS

Download `Axis.ps1` from the [GitHub releases page](https://github.com/IICarrionII/Axis/releases) or clone the repository:

```powershell
git clone https://github.com/IICarrionII/Axis.git
cd Axis
```

### Step 2: Download plink.exe

plink.exe is required for SSH connections to Linux and Solaris systems.

1. Visit [PuTTY Download Page](https://www.chiark.greenend.org.uk/~sgtatham/putty/latest.html)
2. Download `plink.exe` (64-bit recommended)
3. Place `plink.exe` in the same folder as `Axis.ps1`

### Step 3: Set Execution Policy (if needed)

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Step 4: Run AXIS

```powershell
.\Axis.ps1
```

---

## Linux Installation (RHEL/CentOS)

### Requirements

- RHEL 8/9, CentOS Stream, Fedora, or compatible distribution
- PowerShell 7+
- sshpass (for password authentication)

### Step 1: Install PowerShell

**RHEL 8/9:**
```bash
# Register Microsoft repository
curl https://packages.microsoft.com/config/rhel/8/prod.repo | sudo tee /etc/yum.repos.d/microsoft.repo

# Install PowerShell
sudo dnf install -y powershell
```

**Fedora:**
```bash
sudo dnf install -y powershell
```

### Step 2: Install sshpass

```bash
sudo dnf install -y sshpass
```

### Step 3: Download AXIS

```bash
git clone https://github.com/IICarrionII/Axis.git
cd Axis
chmod +x Axis.ps1
```

### Step 4: Run AXIS

```bash
pwsh ./Axis.ps1
```

---

## Solaris Installation

### Requirements

- Solaris 10 or 11
- PowerShell 7+ (if available) OR run AXIS from Windows/Linux

### Option A: Run from Windows/Linux

The recommended approach is to run AXIS from a Windows or Linux management workstation and scan Solaris systems remotely.

### Option B: Install PowerShell on Solaris 11

PowerShell can be installed on Solaris 11 using pkg:

```bash
# Check if available in your Solaris version
pkg search powershell
```

Note: PowerShell availability on Solaris may be limited. Running from Windows or Linux is recommended.

---

## Air-Gapped Network Installation

For systems without internet access, follow these steps to transfer required files.

### Windows Air-Gapped Installation

**On internet-connected system:**

1. Download `Axis.ps1` from GitHub
2. Download `plink.exe` from PuTTY website
3. Copy both files to USB drive or approved transfer medium

**On air-gapped system:**

1. Copy `Axis.ps1` and `plink.exe` to desired folder (e.g., `C:\Tools\Axis\`)
2. Run PowerShell and navigate to folder
3. Execute: `.\Axis.ps1`

### Linux Air-Gapped Installation

**On internet-connected RHEL system:**

```bash
# Download PowerShell RPM
dnf download --resolve powershell

# Download sshpass RPM
dnf download --resolve sshpass

# Download AXIS
git clone https://github.com/IICarrionII/Axis.git
```

**Transfer all files to air-gapped system, then:**

```bash
# Install PowerShell
sudo rpm -ivh powershell*.rpm

# Install sshpass
sudo rpm -ivh sshpass*.rpm

# Copy AXIS files
chmod +x Axis.ps1
```

---

## Verifying Installation

### Windows Verification

```powershell
# Check PowerShell version
$PSVersionTable.PSVersion

# Check plink.exe is accessible
.\plink.exe -V

# Run AXIS
.\Axis.ps1
```

### Linux Verification

```bash
# Check PowerShell version
pwsh --version

# Check sshpass
which sshpass

# Check SSH
which ssh

# Run AXIS
pwsh ./Axis.ps1
```

### Test Single Host

1. Run AXIS
2. Select option `[7]` - Test Connection to Single Host
3. Enter a known working IP, username, and password
4. Verify connection succeeds

---

## Next Steps

- See [USAGE.md](USAGE.md) for detailed usage instructions
- See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for common issues
- Configure [passwordless sudo](../README.md#configuration) for complete hardware info collection
