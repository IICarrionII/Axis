# AXIS Installation Guide

## Prerequisites

### Windows Workstation (Required)
- Windows 10/11 or Windows Server 2016+
- PowerShell 5.1 or higher (built-in on Windows 10+)
- Administrator access (for initial setup)

### plink.exe (Required for Linux/Solaris scanning)
- Download from: https://www.chiark.greenend.org.uk/~sgtatham/putty/latest.html
- Direct link: Look for "plink.exe" under "Alternative binary files"

## Installation Steps

### Step 1: Download AXIS

**Option A: From GitHub**
```powershell
# Clone the repository (if git is available)
git clone https://github.com/IICarrionII/Axis.git

# Or download the ZIP from GitHub and extract
```

**Option B: From ZIP file**
1. Download Axis-main.zip
2. Extract to a folder (e.g., `C:\Tools\Axis\`)

### Step 2: Download plink.exe

1. Go to https://www.chiark.greenend.org.uk/~sgtatham/putty/latest.html
2. Scroll to "Alternative binary files"
3. Download `plink.exe` (64-bit or 32-bit based on your system)
4. Place `plink.exe` in the same folder as `Axis.ps1`

**For Air-Gapped Networks:**
1. Download plink.exe on an internet-connected computer
2. Transfer via approved method (USB, secure file transfer)
3. Place in the Axis folder

### Step 3: Rename Script (if needed)

If you received `Axis.ps1.txt` (for email compatibility):
```powershell
# In PowerShell
Rename-Item Axis.ps1.txt Axis.ps1

# Or right-click the file and rename manually
```

### Step 4: Verify Folder Structure

Your Axis folder should look like this:
```
C:\Tools\Axis\
├── Axis.ps1          ← Main script
├── plink.exe         ← Required for SSH
├── README.md
├── LICENSE
├── CHANGELOG.md
├── docs\
├── examples\
└── tools\
```

### Step 5: Set Execution Policy (if needed)

If PowerShell blocks script execution:

```powershell
# Option 1: Bypass for current session only (recommended)
powershell -ExecutionPolicy Bypass -File .\Axis.ps1

# Option 2: Set policy for current user
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Step 6: Run AXIS

```powershell
cd C:\Tools\Axis
.\Axis.ps1
```

## First-Time Setup

### 1. Add Credentials

When AXIS starts:
1. Select `[5] Manage Credentials`
2. Select `[1] Add Credential`
3. Enter a label (e.g., "Linux Admin")
4. Enter username
5. Enter password
6. Repeat for additional credential sets (Windows admin, etc.)

### 2. Test Connection

Before scanning a subnet:
1. Select `[2] Scan Single Host`
2. Enter an IP address you know works
3. Verify the scan completes successfully

### 3. Configure Settings (Optional)

Select `[6] Configure Settings` to:
- Set a default subnet
- Set output file location
- Adjust timeout (default: 60 seconds)

## Target System Requirements

### Linux Systems
- SSH server running (port 22)
- User account with sudo access (for dmidecode)
- No special software needed on targets

### Solaris Systems
- SSH server running (port 22)
- User account with access to:
  - `/usr/sbin/prtconf`
  - `/usr/bin/hostid`
  - `hostname`

### Windows Systems
- WMI enabled (default on Windows)
- Port 135 open (DCOM/RPC)
- Admin credentials
- Firewall may need to allow remote WMI:
  ```cmd
  netsh advfirewall firewall set rule group="Windows Management Instrumentation (WMI)" new enable=yes
  ```

## Troubleshooting Installation

### "plink.exe not found"
- Ensure plink.exe is in the same folder as Axis.ps1
- Verify it's named exactly `plink.exe` (not plink(1).exe, etc.)

### "Script cannot be loaded because running scripts is disabled"
- Use: `powershell -ExecutionPolicy Bypass -File .\Axis.ps1`
- Or: `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser`

### "Access Denied" when running
- Right-click PowerShell → "Run as Administrator"
- Or ensure your user has write access to the Axis folder

## Updating AXIS

To update to a new version:
1. Download the new Axis.ps1
2. Replace the old Axis.ps1 in your folder
3. Keep plink.exe (no need to re-download)
4. Your credentials will need to be re-entered (not saved between sessions)

## Uninstallation

Simply delete the Axis folder. AXIS does not install anything system-wide.
