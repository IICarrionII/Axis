#!/usr/bin/env pwsh
#requires -Version 5.1
<#
================================================================================
    AXIS - Asset eXploration & Inventory Scanner
    Cross-Platform Hardware & Software Inventory Tool
    
    Created by: Yan Carrion
    GitHub: https://github.com/IICarrionII/Axis
    
    Supports:
      - Running FROM: Windows 10/11, RHEL 8/9, Solaris 10/11
      - Scanning TO:  Linux, Solaris SPARC, Windows
    
    No internet dependencies - works in air-gapped networks
================================================================================
#>

# Version
$script:Version = "1.0.0"

# Detect the OS we're running on
$script:RunningOnWindows = $true
$script:RunningOnLinux = $false
$script:RunningOnSolaris = $false

if ($PSVersionTable.PSVersion.Major -ge 6) {
    $script:RunningOnWindows = $IsWindows
    $script:RunningOnLinux = $IsLinux
    if (-not $IsWindows -and -not $IsLinux) {
        # Could be Solaris with PowerShell
        $unameOutput = uname -s 2>$null
        if ($unameOutput -match "SunOS") {
            $script:RunningOnSolaris = $true
            $script:RunningOnLinux = $false
        }
    }
}
elseif ($env:OS -notmatch "Windows") {
    $script:RunningOnWindows = $false
    $unameOutput = uname -s 2>$null
    if ($unameOutput -match "Linux") {
        $script:RunningOnLinux = $true
    }
    elseif ($unameOutput -match "SunOS") {
        $script:RunningOnSolaris = $true
    }
}

#region Global Variables
$script:Subnet = ""
$script:Username = ""
$script:Password = ""
$script:OutputPath = ""
$script:ScanSSH = $true
$script:ScanWinRM = $true
$script:CommandTimeout = 60
$script:Threads = 10
$script:PlinkPath = ""
$script:SSHPath = ""
#endregion

#region Helper Functions

function Show-Banner {
    Clear-Host
    
    Write-Host ""
    Write-Host "     █████╗ ██╗  ██╗██╗███████╗" -ForegroundColor Cyan
    Write-Host "    ██╔══██╗╚██╗██╔╝██║██╔════╝" -ForegroundColor Cyan
    Write-Host "    ███████║ ╚███╔╝ ██║███████╗" -ForegroundColor Cyan
    Write-Host "    ██╔══██║ ██╔██╗ ██║╚════██║" -ForegroundColor Cyan
    Write-Host "    ██║  ██║██╔╝ ██╗██║███████║" -ForegroundColor Cyan
    Write-Host "    ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝╚══════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  ╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Yellow
    Write-Host "  ║   AXIS - Asset eXploration & Inventory Scanner            ║" -ForegroundColor Yellow
    Write-Host "  ║   Cross-Platform Hardware & Software Inventory Tool       ║" -ForegroundColor Yellow
    Write-Host "  ╠═══════════════════════════════════════════════════════════╣" -ForegroundColor Yellow
    Write-Host "  ║   Supports: Linux (RHEL) | Solaris SPARC | Windows        ║" -ForegroundColor Yellow
    Write-Host "  ║   Air-Gapped Network Ready - No Internet Required         ║" -ForegroundColor Yellow
    Write-Host "  ╠═══════════════════════════════════════════════════════════╣" -ForegroundColor Yellow
    Write-Host "  ║   Created by: Yan Carrion                                 ║" -ForegroundColor Gray
    Write-Host "  ║   GitHub: github.com/IICarrionII/Axis                     ║" -ForegroundColor Gray
    Write-Host "  ╚═══════════════════════════════════════════════════════════╝" -ForegroundColor Yellow
    Write-Host ""
    
    # Show current platform
    $platform = "Unknown"
    if ($script:RunningOnWindows) { $platform = "Windows" }
    elseif ($script:RunningOnLinux) { $platform = "Linux" }
    elseif ($script:RunningOnSolaris) { $platform = "Solaris" }
    
    Write-Host "  Running on: $platform | Version: $($script:Version)" -ForegroundColor DarkGray
    Write-Host ""
}

function Show-MainMenu {
    Show-Banner
    
    Write-Host "  ┌─────────────────────────────────────────────────────────────┐" -ForegroundColor White
    Write-Host "  │                      MAIN MENU                              │" -ForegroundColor White
    Write-Host "  ├─────────────────────────────────────────────────────────────┤" -ForegroundColor White
    Write-Host "  │                                                             │" -ForegroundColor White
    Write-Host "  │   [1]  Quick Scan (All Platforms)                           │" -ForegroundColor Green
    Write-Host "  │   [2]  Scan Linux/Solaris Only                              │" -ForegroundColor Green
    Write-Host "  │   [3]  Scan Windows Only                                    │" -ForegroundColor Green
    Write-Host "  │   [4]  Custom Scan (Advanced Options)                       │" -ForegroundColor Green
    Write-Host "  │                                                             │" -ForegroundColor White
    Write-Host "  │   [5]  Configure Settings                                   │" -ForegroundColor Cyan
    Write-Host "  │   [6]  View Current Settings                                │" -ForegroundColor Cyan
    Write-Host "  │   [7]  Test Connection to Single Host                       │" -ForegroundColor Cyan
    Write-Host "  │                                                             │" -ForegroundColor White
    Write-Host "  │   [8]  Help / Instructions                                  │" -ForegroundColor Yellow
    Write-Host "  │   [9]  About                                                │" -ForegroundColor Yellow
    Write-Host "  │                                                             │" -ForegroundColor White
    Write-Host "  │   [0]  Exit                                                 │" -ForegroundColor Red
    Write-Host "  │                                                             │" -ForegroundColor White
    Write-Host "  └─────────────────────────────────────────────────────────────┘" -ForegroundColor White
    Write-Host ""
    
    $choice = Read-Host "  Enter your choice"
    return $choice
}

function Show-SettingsMenu {
    Show-Banner
    
    Write-Host "  ┌─────────────────────────────────────────────────────────────┐" -ForegroundColor White
    Write-Host "  │                   SETTINGS                                  │" -ForegroundColor White
    Write-Host "  ├─────────────────────────────────────────────────────────────┤" -ForegroundColor White
    Write-Host "  │                                                             │" -ForegroundColor White
    Write-Host "  │   [1]  Set Subnet (Current: $(if($script:Subnet){"$($script:Subnet.PadRight(25))"}else{"Not Set".PadRight(25)}))│" -ForegroundColor White
    Write-Host "  │   [2]  Set Username (Current: $(if($script:Username){"$($script:Username.PadRight(22))"}else{"Not Set".PadRight(22)}))│" -ForegroundColor White
    Write-Host "  │   [3]  Set Password (Current: $(if($script:Password){"********".PadRight(22)}else{"Not Set".PadRight(22)}))│" -ForegroundColor White
    Write-Host "  │   [4]  Set Output Path                                      │" -ForegroundColor White
    Write-Host "  │   [5]  Set Timeout (Current: $($script:CommandTimeout.ToString().PadRight(3)) seconds)                  │" -ForegroundColor White
    Write-Host "  │   [6]  Set Thread Count (Current: $($script:Threads.ToString().PadRight(3)))                      │" -ForegroundColor White
    Write-Host "  │                                                             │" -ForegroundColor White
    Write-Host "  │   [0]  Back to Main Menu                                    │" -ForegroundColor Yellow
    Write-Host "  │                                                             │" -ForegroundColor White
    Write-Host "  └─────────────────────────────────────────────────────────────┘" -ForegroundColor White
    Write-Host ""
    
    $choice = Read-Host "  Enter your choice"
    return $choice
}

function Get-RequiredSettings {
    $needInput = $false
    
    if (-not $script:Subnet) {
        Write-Host ""
        Write-Host "  Subnet is required." -ForegroundColor Yellow
        $script:Subnet = Read-Host "  Enter subnet (e.g., 192.168.1.0/24)"
        $needInput = $true
    }
    
    if (-not $script:Username) {
        Write-Host ""
        Write-Host "  Username is required." -ForegroundColor Yellow
        $script:Username = Read-Host "  Enter username"
        $needInput = $true
    }
    
    if (-not $script:Password) {
        Write-Host ""
        Write-Host "  Password is required." -ForegroundColor Yellow
        $script:Password = Read-Host "  Enter password"
        $needInput = $true
    }
    
    if (-not $script:OutputPath) {
        $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
        $script:OutputPath = ".\AXIS_Inventory_$timestamp.csv"
    }
    
    return (-not [string]::IsNullOrEmpty($script:Subnet) -and 
            -not [string]::IsNullOrEmpty($script:Username) -and 
            -not [string]::IsNullOrEmpty($script:Password))
}

function Show-CurrentSettings {
    Show-Banner
    
    Write-Host "  ┌─────────────────────────────────────────────────────────────┐" -ForegroundColor White
    Write-Host "  │                 CURRENT SETTINGS                            │" -ForegroundColor White
    Write-Host "  ├─────────────────────────────────────────────────────────────┤" -ForegroundColor White
    Write-Host "  │                                                             │" -ForegroundColor White
    Write-Host "  │  Subnet:        $(if($script:Subnet){$script:Subnet.PadRight(40)}else{"Not Set".PadRight(40)})│" -ForegroundColor White
    Write-Host "  │  Username:      $(if($script:Username){$script:Username.PadRight(40)}else{"Not Set".PadRight(40)})│" -ForegroundColor White
    Write-Host "  │  Password:      $(if($script:Password){"********".PadRight(40)}else{"Not Set".PadRight(40)})│" -ForegroundColor White
    Write-Host "  │  Output Path:   $(if($script:OutputPath){$script:OutputPath.Substring(0,[Math]::Min(40,$script:OutputPath.Length)).PadRight(40)}else{"Auto-generate".PadRight(40)})│" -ForegroundColor White
    Write-Host "  │  Timeout:       $("$($script:CommandTimeout) seconds".PadRight(40))│" -ForegroundColor White
    Write-Host "  │  Threads:       $($script:Threads.ToString().PadRight(40))│" -ForegroundColor White
    Write-Host "  │  Scan SSH:      $($script:ScanSSH.ToString().PadRight(40))│" -ForegroundColor White
    Write-Host "  │  Scan WinRM:    $($script:ScanWinRM.ToString().PadRight(40))│" -ForegroundColor White
    Write-Host "  │                                                             │" -ForegroundColor White
    
    # Show detected tools
    $sshTool = "Not Found"
    if ($script:RunningOnWindows) {
        if ($script:PlinkPath) { $sshTool = "plink.exe" }
    }
    else {
        if (Get-Command ssh -ErrorAction SilentlyContinue) { $sshTool = "ssh (native)" }
    }
    
    Write-Host "  │  SSH Tool:      $($sshTool.PadRight(40))│" -ForegroundColor White
    Write-Host "  │                                                             │" -ForegroundColor White
    Write-Host "  └─────────────────────────────────────────────────────────────┘" -ForegroundColor White
    Write-Host ""
    
    Read-Host "  Press Enter to continue"
}

function Show-Help {
    Show-Banner
    
    Write-Host "  ┌─────────────────────────────────────────────────────────────┐" -ForegroundColor White
    Write-Host "  │                     HELP / INSTRUCTIONS                     │" -ForegroundColor White
    Write-Host "  └─────────────────────────────────────────────────────────────┘" -ForegroundColor White
    Write-Host ""
    Write-Host "  QUICK START:" -ForegroundColor Cyan
    Write-Host "  1. Select option [1] Quick Scan from main menu"
    Write-Host "  2. Enter subnet when prompted (e.g., 192.168.1.0/24)"
    Write-Host "  3. Enter username and password"
    Write-Host "  4. Wait for scan to complete"
    Write-Host "  5. CSV file will be saved automatically"
    Write-Host ""
    Write-Host "  SUPPORTED PLATFORMS:" -ForegroundColor Cyan
    Write-Host "  - Linux (RHEL, CentOS, Fedora, Ubuntu, etc.)"
    Write-Host "  - Solaris 10/11 SPARC"
    Write-Host "  - Windows Server/Desktop (via WinRM)"
    Write-Host ""
    Write-Host "  REQUIREMENTS:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  If running on WINDOWS:" -ForegroundColor Yellow
    Write-Host "    - plink.exe required for SSH scanning"
    Write-Host "    - Place plink.exe in same folder as this script"
    Write-Host "    - Download from: putty.org (on internet-connected PC)"
    Write-Host ""
    Write-Host "  If running on LINUX:" -ForegroundColor Yellow
    Write-Host "    - Native SSH client (usually pre-installed)"
    Write-Host "    - sshpass package for password automation"
    Write-Host "    - Install: sudo yum install sshpass (RHEL)"
    Write-Host ""
    Write-Host "  TARGET SYSTEMS NEED:" -ForegroundColor Cyan
    Write-Host "  - Linux/Solaris: SSH enabled, user with sudo access"
    Write-Host "  - Windows: WinRM enabled (Enable-PSRemoting -Force)"
    Write-Host ""
    Write-Host "  GITHUB:" -ForegroundColor Cyan
    Write-Host "  https://github.com/IICarrionII/Axis"
    Write-Host ""
    
    Read-Host "  Press Enter to continue"
}

function Show-About {
    Show-Banner
    
    Write-Host "  ┌─────────────────────────────────────────────────────────────┐" -ForegroundColor White
    Write-Host "  │                        ABOUT                                │" -ForegroundColor White
    Write-Host "  └─────────────────────────────────────────────────────────────┘" -ForegroundColor White
    Write-Host ""
    Write-Host "  AXIS - Asset eXploration & Inventory Scanner" -ForegroundColor Cyan
    Write-Host "  Version: $($script:Version)" -ForegroundColor White
    Write-Host ""
    Write-Host "  Created by: Yan Carrion" -ForegroundColor Yellow
    Write-Host "  GitHub: https://github.com/IICarrionII/Axis" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  A cross-platform hardware and software inventory tool" -ForegroundColor White
    Write-Host "  designed for air-gapped enterprise networks." -ForegroundColor White
    Write-Host ""
    Write-Host "  Features:" -ForegroundColor Cyan
    Write-Host "  - Runs on Windows, Linux, and Solaris"
    Write-Host "  - Scans Linux, Solaris SPARC, and Windows targets"
    Write-Host "  - No internet dependencies"
    Write-Host "  - Auto-accepts SSH host keys (air-gapped safe)"
    Write-Host "  - Menu-driven interface (no flags to memorize)"
    Write-Host "  - Exports to CSV format"
    Write-Host ""
    Write-Host "  For IT asset management and compliance reporting" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  ─────────────────────────────────────────────────────────────" -ForegroundColor DarkGray
    Write-Host "  Licensed under MIT License" -ForegroundColor DarkGray
    Write-Host "  ─────────────────────────────────────────────────────────────" -ForegroundColor DarkGray
    Write-Host ""
    
    Read-Host "  Press Enter to continue"
}

function Get-IPRange {
    param([string]$CIDR)
    
    $networkAddr, $prefixLength = $CIDR -split '/'
    $prefixLength = [int]$prefixLength
    
    $ipBytes = [System.Net.IPAddress]::Parse($networkAddr).GetAddressBytes()
    [Array]::Reverse($ipBytes)
    $ipInt = [System.BitConverter]::ToUInt32($ipBytes, 0)
    
    $hostBits = 32 - $prefixLength
    $networkMask = [UInt32]([Math]::Pow(2, 32) - [Math]::Pow(2, $hostBits))
    $networkInt = $ipInt -band $networkMask
    $broadcastInt = $networkInt -bor (-bnot $networkMask)
    
    $ips = @()
    for ($i = $networkInt + 1; $i -lt $broadcastInt; $i++) {
        $bytes = [System.BitConverter]::GetBytes($i)
        [Array]::Reverse($bytes)
        $ips += [System.Net.IPAddress]::new($bytes).ToString()
    }
    
    return $ips
}

function Test-Port {
    param([string]$IPAddress, [int]$Port, [int]$Timeout = 1000)
    
    try {
        $tcpClient = New-Object System.Net.Sockets.TcpClient
        $connect = $tcpClient.BeginConnect($IPAddress, $Port, $null, $null)
        $wait = $connect.AsyncWaitHandle.WaitOne($Timeout, $false)
        
        if ($wait) {
            try { $tcpClient.EndConnect($connect); $tcpClient.Close(); return $true }
            catch { return $false }
        }
        else { $tcpClient.Close(); return $false }
    }
    catch { return $false }
}

function Initialize-SSHTool {
    if ($script:RunningOnWindows) {
        # Look for plink.exe
        $searchPaths = @(
            "$PSScriptRoot\plink.exe",
            ".\plink.exe",
            "$env:ProgramFiles\PuTTY\plink.exe",
            "${env:ProgramFiles(x86)}\PuTTY\plink.exe",
            "C:\PuTTY\plink.exe",
            "C:\Tools\plink.exe"
        )
        
        foreach ($path in $searchPaths) {
            if (Test-Path $path -ErrorAction SilentlyContinue) {
                $script:PlinkPath = $path
                return $true
            }
        }
        
        Write-Host ""
        Write-Host "  WARNING: plink.exe not found!" -ForegroundColor Red
        Write-Host "  SSH scanning (Linux/Solaris) will not work." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "  To fix: Download plink.exe from putty.org and place" -ForegroundColor Yellow
        Write-Host "  it in the same folder as this script." -ForegroundColor Yellow
        Write-Host ""
        return $false
    }
    else {
        # Linux/Solaris - check for ssh and sshpass
        $sshExists = Get-Command ssh -ErrorAction SilentlyContinue
        $sshpassExists = Get-Command sshpass -ErrorAction SilentlyContinue
        
        if (-not $sshExists) {
            Write-Host ""
            Write-Host "  WARNING: ssh command not found!" -ForegroundColor Red
            return $false
        }
        
        if (-not $sshpassExists) {
            Write-Host ""
            Write-Host "  WARNING: sshpass not found!" -ForegroundColor Yellow
            Write-Host "  Password authentication may not work." -ForegroundColor Yellow
            Write-Host "  Install with: sudo yum install sshpass" -ForegroundColor Yellow
            Write-Host ""
        }
        
        $script:SSHPath = (Get-Command ssh).Source
        return $true
    }
}

# SSH Command Execution - Windows (plink)
function Invoke-PlinkCommand {
    param(
        [string]$IPAddress,
        [string]$Username,
        [string]$Password,
        [string]$Command,
        [int]$Timeout
    )
    
    try {
        # -hostkey * : Auto-accept any host key (air-gapped network safe)
        $plinkArgs = "-ssh -batch -hostkey * -pw `"$Password`" $Username@$IPAddress `"$Command`""
        
        $processInfo = New-Object System.Diagnostics.ProcessStartInfo
        $processInfo.FileName = $script:PlinkPath
        $processInfo.Arguments = $plinkArgs
        $processInfo.UseShellExecute = $false
        $processInfo.CreateNoWindow = $true
        $processInfo.RedirectStandardOutput = $true
        $processInfo.RedirectStandardError = $true
        
        $process = New-Object System.Diagnostics.Process
        $process.StartInfo = $processInfo
        
        $outputBuilder = New-Object System.Text.StringBuilder
        $errorBuilder = New-Object System.Text.StringBuilder
        
        $outputEvent = Register-ObjectEvent -InputObject $process -EventName OutputDataReceived -Action {
            if ($EventArgs.Data) { [void]$Event.MessageData.AppendLine($EventArgs.Data) }
        } -MessageData $outputBuilder
        
        $errorEvent = Register-ObjectEvent -InputObject $process -EventName ErrorDataReceived -Action {
            if ($EventArgs.Data) { [void]$Event.MessageData.AppendLine($EventArgs.Data) }
        } -MessageData $errorBuilder
        
        [void]$process.Start()
        $process.BeginOutputReadLine()
        $process.BeginErrorReadLine()
        
        $completed = $process.WaitForExit($Timeout * 1000)
        
        if (-not $completed) {
            $process.Kill()
            Unregister-Event -SourceIdentifier $outputEvent.Name -Force -ErrorAction SilentlyContinue
            Unregister-Event -SourceIdentifier $errorEvent.Name -Force -ErrorAction SilentlyContinue
            throw "Timeout"
        }
        
        Start-Sleep -Milliseconds 200
        
        Unregister-Event -SourceIdentifier $outputEvent.Name -Force -ErrorAction SilentlyContinue
        Unregister-Event -SourceIdentifier $errorEvent.Name -Force -ErrorAction SilentlyContinue
        
        $output = $outputBuilder.ToString()
        $errorOutput = $errorBuilder.ToString()
        
        if ($process.ExitCode -eq 0 -or ($output -and $output.Trim())) {
            return @{ Success = $true; Output = $output; Error = $errorOutput }
        }
        else {
            return @{ Success = $false; Output = $output; Error = $errorOutput }
        }
    }
    catch {
        return @{ Success = $false; Output = ""; Error = $_.Exception.Message }
    }
}

# SSH Command Execution - Linux (native ssh + sshpass)
function Invoke-NativeSSHCommand {
    param(
        [string]$IPAddress,
        [string]$Username,
        [string]$Password,
        [string]$Command,
        [int]$Timeout
    )
    
    try {
        $outputFile = "/tmp/axis_ssh_out_$([guid]::NewGuid().ToString('N'))"
        $errorFile = "/tmp/axis_ssh_err_$([guid]::NewGuid().ToString('N'))"
        
        # Check if sshpass is available
        $useSshpass = Get-Command sshpass -ErrorAction SilentlyContinue
        
        if ($useSshpass) {
            # Use sshpass for password authentication
            $sshCmd = "sshpass -p '$Password' ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=$Timeout $Username@$IPAddress '$Command' > '$outputFile' 2> '$errorFile'"
        }
        else {
            # Try without sshpass (may fail or prompt)
            $sshCmd = "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=$Timeout -o BatchMode=yes $Username@$IPAddress '$Command' > '$outputFile' 2> '$errorFile'"
        }
        
        $result = bash -c $sshCmd
        $exitCode = $LASTEXITCODE
        
        $output = ""
        $errorOutput = ""
        
        if (Test-Path $outputFile) {
            $output = Get-Content $outputFile -Raw -ErrorAction SilentlyContinue
            Remove-Item $outputFile -Force -ErrorAction SilentlyContinue
        }
        
        if (Test-Path $errorFile) {
            $errorOutput = Get-Content $errorFile -Raw -ErrorAction SilentlyContinue
            Remove-Item $errorFile -Force -ErrorAction SilentlyContinue
        }
        
        if ($exitCode -eq 0 -or ($output -and $output.Trim())) {
            return @{ Success = $true; Output = $output; Error = $errorOutput }
        }
        else {
            return @{ Success = $false; Output = $output; Error = $errorOutput }
        }
    }
    catch {
        return @{ Success = $false; Output = ""; Error = $_.Exception.Message }
    }
}

# Unified SSH command function
function Invoke-SSHCommand {
    param(
        [string]$IPAddress,
        [string]$Username,
        [string]$Password,
        [string]$Command,
        [int]$Timeout
    )
    
    if ($script:RunningOnWindows) {
        return Invoke-PlinkCommand -IPAddress $IPAddress -Username $Username -Password $Password -Command $Command -Timeout $Timeout
    }
    else {
        return Invoke-NativeSSHCommand -IPAddress $IPAddress -Username $Username -Password $Password -Command $Command -Timeout $Timeout
    }
}

# Detect remote OS type
function Get-RemoteOSType {
    param([string]$IPAddress, [string]$Username, [string]$Password)
    
    $result = Invoke-SSHCommand -IPAddress $IPAddress -Username $Username -Password $Password -Command "uname -s" -Timeout 15
    
    if ($result.Success) {
        $output = $result.Output.ToLower().Trim()
        if ($output -match "sunos") { return "Solaris" }
        elseif ($output -match "linux") { return "Linux" }
    }
    return "Unknown"
}

#endregion

#region OS-Specific Info Collection

function Get-LinuxSystemInfo {
    param([string]$IPAddress, [string]$Username, [string]$Password, [int]$Timeout)
    
    try {
        $command = 'hostname && ' +
                   'echo VIRTUAL:$(systemd-detect-virt 2>/dev/null | grep -qv none && echo Yes || echo No) && ' +
                   'echo MANUFACTURER:$(sudo dmidecode -s system-manufacturer 2>/dev/null || echo Unknown) && ' +
                   'echo MODEL:$(sudo dmidecode -s system-product-name 2>/dev/null || echo Unknown) && ' +
                   'echo SERIAL:$(sudo dmidecode -s system-serial-number 2>/dev/null || echo Unknown) && ' +
                   'echo OS:$(. /etc/os-release 2>/dev/null && echo $PRETTY_NAME || uname -sr) && ' +
                   'echo KERNEL:$(uname -r) && ' +
                   'echo MEMORY:$(free -h 2>/dev/null | awk ''/^Mem:/ {print $2}'' || echo Unknown) && ' +
                   'echo MEMTYPE:$(sudo dmidecode -t memory 2>/dev/null | grep Type: | grep -v Error | head -1 | awk ''{print $2}'' || echo Unknown) && ' +
                   'echo FIRMWARE:$(sudo dmidecode -s bios-version 2>/dev/null || echo Unknown)'
        
        $result = Invoke-SSHCommand -IPAddress $IPAddress -Username $Username -Password $Password -Command $command -Timeout $Timeout
        
        if (-not $result.Success) { throw $result.Error }
        
        return Parse-UnixOutput -Output $result.Output -IPAddress $IPAddress -OSType "Linux"
    }
    catch {
        return New-FailedResult -IPAddress $IPAddress -OSType "Linux" -Error $_.Exception.Message
    }
}

function Get-SolarisSystemInfo {
    param([string]$IPAddress, [string]$Username, [string]$Password, [int]$Timeout)
    
    try {
        $command = 'hostname && ' +
                   'echo VIRTUAL:$(if /usr/sbin/virtinfo 2>/dev/null | grep -q "virtual"; then echo Yes; else echo No; fi) && ' +
                   'echo MANUFACTURER:$(sudo /usr/sbin/prtconf -pv 2>/dev/null | grep "banner-name" | head -1 | cut -d"'+"'"+'" -f2 || echo Unknown) && ' +
                   'echo MODEL:$(sudo /usr/sbin/prtdiag 2>/dev/null | head -1 | sed "s/System Configuration: //" || /usr/sbin/prtconf -b 2>/dev/null | head -1 || echo Unknown) && ' +
                   'echo SERIAL:$(sudo /usr/sbin/sneep 2>/dev/null || /usr/bin/hostid 2>/dev/null || echo Unknown) && ' +
                   'echo OS:SunOS $(uname -r) $(cat /etc/release 2>/dev/null | head -1 | xargs) && ' +
                   'echo KERNEL:$(uname -v) && ' +
                   'echo MEMORY:$(sudo /usr/sbin/prtconf 2>/dev/null | grep "Memory size" | awk "{print \$3, \$4}" || echo Unknown) && ' +
                   'echo MEMTYPE:Unknown && ' +
                   'echo FIRMWARE:$(sudo /usr/sbin/prtdiag -v 2>/dev/null | grep "OBP" | head -1 | awk "{print \$2}" || echo Unknown)'
        
        $result = Invoke-SSHCommand -IPAddress $IPAddress -Username $Username -Password $Password -Command $command -Timeout $Timeout
        
        if (-not $result.Success) { throw $result.Error }
        
        return Parse-UnixOutput -Output $result.Output -IPAddress $IPAddress -OSType "Solaris"
    }
    catch {
        return New-FailedResult -IPAddress $IPAddress -OSType "Solaris" -Error $_.Exception.Message
    }
}

function Get-WindowsSystemInfo {
    param([string]$IPAddress, [string]$Username, [string]$Password, [int]$Timeout)
    
    try {
        $secPassword = ConvertTo-SecureString $Password -AsPlainText -Force
        $credential = New-Object System.Management.Automation.PSCredential($Username, $secPassword)
        
        $sessionOption = New-PSSessionOption -OperationTimeout ($Timeout * 1000) -OpenTimeout ($Timeout * 1000)
        
        $scriptBlock = {
            $cs = Get-CimInstance Win32_ComputerSystem
            $os = Get-CimInstance Win32_OperatingSystem
            $bios = Get-CimInstance Win32_BIOS
            $mem = Get-CimInstance Win32_PhysicalMemory | Select-Object -First 1
            
            @{
                Hostname = $env:COMPUTERNAME
                Virtual = if ($cs.Model -match "Virtual|VMware|Hyper-V|KVM|Xen") { "Yes" } else { "No" }
                Manufacturer = $cs.Manufacturer
                Model = $cs.Model
                Serial = $bios.SerialNumber
                OS = $os.Caption + " " + $os.Version
                Kernel = $os.BuildNumber
                Memory = [math]::Round($cs.TotalPhysicalMemory / 1GB, 1).ToString() + " GB"
                MemType = if ($mem.MemoryType) { $mem.MemoryType } else { "Unknown" }
                Firmware = $bios.SMBIOSBIOSVersion
            }
        }
        
        $result = Invoke-Command -ComputerName $IPAddress -Credential $credential -ScriptBlock $scriptBlock -SessionOption $sessionOption -ErrorAction Stop
        
        return [PSCustomObject]@{
            'Component Type' = 'Server'
            'Hostname' = $result.Hostname
            'IP Address' = $IPAddress
            'Virtual Asset' = $result.Virtual
            'Manufacturer' = $result.Manufacturer
            'Model Number' = $result.Model
            'Serial Number' = $result.Serial
            'OS/IOS' = $result.OS
            'FW Version' = $result.Firmware
            'Memory Size' = $result.Memory
            'Memory Type' = $result.MemType
            'Kernel Version' = $result.Kernel
            'OS Type' = 'Windows'
            'Scan Status' = 'Success'
        }
    }
    catch {
        return New-FailedResult -IPAddress $IPAddress -OSType "Windows" -Error $_.Exception.Message
    }
}

function Parse-UnixOutput {
    param([string]$Output, [string]$IPAddress, [string]$OSType)
    
    $lines = $Output -split "`n" | ForEach-Object { $_.Trim() } | Where-Object { $_ -and $_ -notmatch '^Warning:' -and $_ -notmatch '^Using' }
    
    $info = @{
        'HOSTNAME' = 'Unknown'; 'VIRTUAL' = 'Unknown'; 'MANUFACTURER' = 'Unknown'
        'MODEL' = 'Unknown'; 'SERIAL' = 'Unknown'; 'OS' = 'Unknown'
        'KERNEL' = 'Unknown'; 'MEMORY' = 'Unknown'; 'MEMTYPE' = 'Unknown'; 'FIRMWARE' = 'Unknown'
    }
    
    foreach ($line in $lines) {
        if ($line -match '^(\w+):(.*)$') {
            $key = $matches[1].ToUpper()
            $value = $matches[2].Trim()
            if ($value -and $info.ContainsKey($key)) {
                $info[$key] = $value
            }
        }
        elseif ($info['HOSTNAME'] -eq 'Unknown' -and $line -notmatch ':' -and $line.Length -gt 0 -and $line.Length -lt 64) {
            $info['HOSTNAME'] = $line
        }
    }
    
    return [PSCustomObject]@{
        'Component Type' = 'Server'
        'Hostname' = $info['HOSTNAME']
        'IP Address' = $IPAddress
        'Virtual Asset' = $info['VIRTUAL']
        'Manufacturer' = $info['MANUFACTURER']
        'Model Number' = $info['MODEL']
        'Serial Number' = $info['SERIAL']
        'OS/IOS' = $info['OS']
        'FW Version' = $info['FIRMWARE']
        'Memory Size' = $info['MEMORY']
        'Memory Type' = $info['MEMTYPE']
        'Kernel Version' = $info['KERNEL']
        'OS Type' = $OSType
        'Scan Status' = 'Success'
    }
}

function New-FailedResult {
    param([string]$IPAddress, [string]$OSType, [string]$Error)
    
    return [PSCustomObject]@{
        'Component Type' = 'Server'
        'Hostname' = 'Unknown'
        'IP Address' = $IPAddress
        'Virtual Asset' = 'Unknown'
        'Manufacturer' = 'Unknown'
        'Model Number' = 'Unknown'
        'Serial Number' = 'Unknown'
        'OS/IOS' = 'Unknown'
        'FW Version' = 'Unknown'
        'Memory Size' = 'Unknown'
        'Memory Type' = 'Unknown'
        'Kernel Version' = 'Unknown'
        'OS Type' = $OSType
        'Scan Status' = "Failed: $Error"
    }
}

#endregion

#region Scanning Functions

function Test-SingleHost {
    Show-Banner
    
    Write-Host "  ┌─────────────────────────────────────────────────────────────┐" -ForegroundColor White
    Write-Host "  │              TEST CONNECTION TO SINGLE HOST                 │" -ForegroundColor White
    Write-Host "  └─────────────────────────────────────────────────────────────┘" -ForegroundColor White
    Write-Host ""
    
    $testIP = Read-Host "  Enter IP address to test"
    
    if (-not $script:Username) {
        $script:Username = Read-Host "  Enter username"
    }
    
    if (-not $script:Password) {
        $script:Password = Read-Host "  Enter password"
    }
    
    Write-Host ""
    Write-Host "  Testing connection to $testIP..." -ForegroundColor Yellow
    Write-Host ""
    
    # Test SSH port
    Write-Host "  [1/3] Checking SSH port (22)..." -NoNewline
    $sshOpen = Test-Port -IPAddress $testIP -Port 22 -Timeout 2000
    if ($sshOpen) {
        Write-Host " OPEN" -ForegroundColor Green
    }
    else {
        Write-Host " CLOSED" -ForegroundColor Red
    }
    
    # Test WinRM port
    Write-Host "  [2/3] Checking WinRM port (5985)..." -NoNewline
    $winrmOpen = Test-Port -IPAddress $testIP -Port 5985 -Timeout 2000
    if ($winrmOpen) {
        Write-Host " OPEN" -ForegroundColor Green
    }
    else {
        Write-Host " CLOSED" -ForegroundColor Red
    }
    
    # Test actual connection
    Write-Host "  [3/3] Testing authentication..." -NoNewline
    
    if ($sshOpen) {
        $result = Invoke-SSHCommand -IPAddress $testIP -Username $script:Username -Password $script:Password -Command "hostname && echo CONNECTION_SUCCESS" -Timeout 20
        
        if ($result.Success -and $result.Output -match "CONNECTION_SUCCESS") {
            Write-Host " SUCCESS" -ForegroundColor Green
            Write-Host ""
            Write-Host "  Output:" -ForegroundColor Cyan
            Write-Host "  $($result.Output -replace 'CONNECTION_SUCCESS', '' | ForEach-Object { $_.Trim() })" -ForegroundColor Gray
        }
        else {
            Write-Host " FAILED" -ForegroundColor Red
            Write-Host ""
            Write-Host "  Error: $($result.Error)" -ForegroundColor Red
        }
    }
    elseif ($winrmOpen) {
        Write-Host " SKIPPED (WinRM test requires actual scan)" -ForegroundColor Yellow
    }
    else {
        Write-Host " SKIPPED (no open ports)" -ForegroundColor Yellow
    }
    
    Write-Host ""
    Read-Host "  Press Enter to continue"
}

function Start-Scan {
    param(
        [bool]$ScanSSH = $true,
        [bool]$ScanWinRM = $true
    )
    
    Show-Banner
    
    Write-Host "  ┌─────────────────────────────────────────────────────────────┐" -ForegroundColor White
    Write-Host "  │                    STARTING SCAN                            │" -ForegroundColor White
    Write-Host "  └─────────────────────────────────────────────────────────────┘" -ForegroundColor White
    Write-Host ""
    
    # Get required settings
    if (-not (Get-RequiredSettings)) {
        Write-Host "  Missing required settings. Please configure first." -ForegroundColor Red
        Read-Host "  Press Enter to continue"
        return
    }
    
    # Initialize SSH tool
    if ($ScanSSH) {
        $sshReady = Initialize-SSHTool
        if (-not $sshReady -and -not $ScanWinRM) {
            Write-Host ""
            Write-Host "  Cannot proceed without SSH tool for SSH-only scan." -ForegroundColor Red
            Read-Host "  Press Enter to continue"
            return
        }
    }
    
    Write-Host ""
    Write-Host "  Subnet: $($script:Subnet)" -ForegroundColor White
    Write-Host "  Scan SSH (Linux/Solaris): $ScanSSH" -ForegroundColor White
    Write-Host "  Scan WinRM (Windows): $ScanWinRM" -ForegroundColor White
    Write-Host "  Output: $($script:OutputPath)" -ForegroundColor White
    Write-Host ""
    
    $confirm = Read-Host "  Proceed with scan? (Y/N)"
    if ($confirm -ne 'Y' -and $confirm -ne 'y') {
        return
    }
    
    Write-Host ""
    Write-Host "  Generating IP list..." -ForegroundColor Yellow
    
    try {
        $ipList = Get-IPRange -CIDR $script:Subnet
        Write-Host "  Total IPs: $($ipList.Count)" -ForegroundColor Green
    }
    catch {
        Write-Host "  Error parsing subnet: $($_.Exception.Message)" -ForegroundColor Red
        Read-Host "  Press Enter to continue"
        return
    }
    
    # Phase 1: Port Discovery
    Write-Host ""
    Write-Host "  Phase 1: Discovering hosts..." -ForegroundColor Cyan
    
    $sshHosts = [System.Collections.ArrayList]::new()
    $winrmHosts = [System.Collections.ArrayList]::new()
    $completed = 0
    $total = $ipList.Count
    
    foreach ($ip in $ipList) {
        $completed++
        $percent = [math]::Round(($completed / $total) * 100, 0)
        Write-Progress -Activity "Discovering hosts" -Status "$completed / $total ($percent%)" -PercentComplete $percent
        
        if ($ScanSSH) {
            if (Test-Port -IPAddress $ip -Port 22 -Timeout 1000) {
                [void]$sshHosts.Add($ip)
            }
        }
        
        if ($ScanWinRM) {
            if (Test-Port -IPAddress $ip -Port 5985 -Timeout 1000) {
                [void]$winrmHosts.Add($ip)
            }
        }
    }
    
    Write-Progress -Activity "Discovering hosts" -Completed
    
    Write-Host "  SSH hosts found: $($sshHosts.Count)" -ForegroundColor Green
    Write-Host "  WinRM hosts found: $($winrmHosts.Count)" -ForegroundColor Green
    
    $totalHosts = $sshHosts.Count + $winrmHosts.Count
    
    if ($totalHosts -eq 0) {
        Write-Host ""
        Write-Host "  No hosts found!" -ForegroundColor Yellow
        Read-Host "  Press Enter to continue"
        return
    }
    
    # Phase 2: Collect Information
    Write-Host ""
    Write-Host "  Phase 2: Collecting system information..." -ForegroundColor Cyan
    Write-Host "  Estimated time: $([math]::Round($totalHosts * 0.5, 0)) - $([math]::Round($totalHosts * 1.5, 0)) minutes" -ForegroundColor Gray
    Write-Host ""
    
    $results = [System.Collections.ArrayList]::new()
    $completed = 0
    $startTime = Get-Date
    
    # Process SSH hosts
    foreach ($ip in $sshHosts) {
        $completed++
        $percent = [math]::Round(($completed / $totalHosts) * 100, 0)
        
        if ($completed -gt 1) {
            $elapsed = ((Get-Date) - $startTime).TotalSeconds
            $avgTime = $elapsed / ($completed - 1)
            $remaining = ($totalHosts - $completed) * $avgTime
            $eta = [math]::Round($remaining / 60, 1)
            Write-Progress -Activity "Collecting info" -Status "$ip ($completed/$totalHosts) ETA: $eta min" -PercentComplete $percent
        }
        else {
            Write-Progress -Activity "Collecting info" -Status "$ip ($completed/$totalHosts)" -PercentComplete $percent
        }
        
        Write-Host "  [$completed/$totalHosts] $ip" -NoNewline
        
        # Detect OS type
        $osType = Get-RemoteOSType -IPAddress $ip -Username $script:Username -Password $script:Password
        Write-Host " [$osType]" -ForegroundColor Gray -NoNewline
        
        # Get info based on OS
        switch ($osType) {
            "Solaris" {
                $info = Get-SolarisSystemInfo -IPAddress $ip -Username $script:Username -Password $script:Password -Timeout $script:CommandTimeout
            }
            "Linux" {
                $info = Get-LinuxSystemInfo -IPAddress $ip -Username $script:Username -Password $script:Password -Timeout $script:CommandTimeout
            }
            default {
                $info = Get-LinuxSystemInfo -IPAddress $ip -Username $script:Username -Password $script:Password -Timeout $script:CommandTimeout
                $info.'OS Type' = "Unknown-SSH"
            }
        }
        
        [void]$results.Add($info)
        
        if ($info.'Scan Status' -eq 'Success') {
            Write-Host " ✓ $($info.Hostname)" -ForegroundColor Green
        }
        else {
            Write-Host " ✗" -ForegroundColor Red
        }
    }
    
    # Process WinRM hosts
    foreach ($ip in $winrmHosts) {
        $completed++
        $percent = [math]::Round(($completed / $totalHosts) * 100, 0)
        Write-Progress -Activity "Collecting info" -Status "$ip ($completed/$totalHosts)" -PercentComplete $percent
        
        Write-Host "  [$completed/$totalHosts] $ip [Windows]" -NoNewline
        
        $info = Get-WindowsSystemInfo -IPAddress $ip -Username $script:Username -Password $script:Password -Timeout $script:CommandTimeout
        [void]$results.Add($info)
        
        if ($info.'Scan Status' -eq 'Success') {
            Write-Host " ✓ $($info.Hostname)" -ForegroundColor Green
        }
        else {
            Write-Host " ✗" -ForegroundColor Red
        }
    }
    
    Write-Progress -Activity "Collecting info" -Completed
    
    # Calculate time
    $totalTime = ((Get-Date) - $startTime).TotalMinutes
    
    # Export results
    Write-Host ""
    Write-Host "  ═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "                         RESULTS" -ForegroundColor Cyan
    Write-Host "  ═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    
    $results | Export-Csv -Path $script:OutputPath -NoTypeInformation -Encoding UTF8
    Write-Host "  ✓ Saved: $($script:OutputPath)" -ForegroundColor Green
    Write-Host ""
    
    $successCount = ($results | Where-Object {$_.'Scan Status' -eq 'Success'}).Count
    $failCount = $results.Count - $successCount
    
    Write-Host "  Total scanned:  $($results.Count)" -ForegroundColor White
    Write-Host "  Successful:     $successCount" -ForegroundColor Green
    Write-Host "  Failed:         $failCount" -ForegroundColor Red
    Write-Host "  Scan time:      $([math]::Round($totalTime, 1)) minutes" -ForegroundColor Gray
    Write-Host ""
    
    # OS breakdown
    if ($successCount -gt 0) {
        Write-Host "  By OS Type:" -ForegroundColor Cyan
        $results | Where-Object {$_.'Scan Status' -eq 'Success'} | 
            Group-Object 'OS Type' | Sort-Object Count -Descending |
            ForEach-Object { Write-Host "    $($_.Name): $($_.Count)" -ForegroundColor White }
        Write-Host ""
        
        $virtCount = ($results | Where-Object {$_.'Virtual Asset' -eq 'Yes'}).Count
        $physCount = ($results | Where-Object {$_.'Virtual Asset' -eq 'No'}).Count
        Write-Host "  Virtual:  $virtCount" -ForegroundColor White
        Write-Host "  Physical: $physCount" -ForegroundColor White
    }
    
    Write-Host ""
    $open = Read-Host "  Open CSV file? (Y/N)"
    if ($open -eq 'Y' -or $open -eq 'y') {
        if ($script:RunningOnWindows) {
            Start-Process $script:OutputPath
        }
        else {
            # Linux - try common viewers
            if (Get-Command xdg-open -ErrorAction SilentlyContinue) {
                & xdg-open $script:OutputPath
            }
            elseif (Get-Command libreoffice -ErrorAction SilentlyContinue) {
                & libreoffice $script:OutputPath
            }
            else {
                Write-Host "  CSV saved to: $($script:OutputPath)" -ForegroundColor Yellow
            }
        }
    }
}

#endregion

#region Main Loop

function Main {
    # Initialize
    Initialize-SSHTool | Out-Null
    
    while ($true) {
        $choice = Show-MainMenu
        
        switch ($choice) {
            "1" {
                # Quick Scan - All Platforms
                Start-Scan -ScanSSH $true -ScanWinRM $true
            }
            "2" {
                # Linux/Solaris Only
                Start-Scan -ScanSSH $true -ScanWinRM $false
            }
            "3" {
                # Windows Only
                Start-Scan -ScanSSH $false -ScanWinRM $true
            }
            "4" {
                # Custom Scan
                Show-Banner
                Write-Host "  Custom Scan Options:" -ForegroundColor Cyan
                Write-Host ""
                $scanSSH = Read-Host "  Scan SSH hosts (Linux/Solaris)? (Y/N)"
                $scanWinRM = Read-Host "  Scan WinRM hosts (Windows)? (Y/N)"
                
                Start-Scan -ScanSSH ($scanSSH -eq 'Y' -or $scanSSH -eq 'y') -ScanWinRM ($scanWinRM -eq 'Y' -or $scanWinRM -eq 'y')
            }
            "5" {
                # Settings Menu
                $settingsLoop = $true
                while ($settingsLoop) {
                    $settingsChoice = Show-SettingsMenu
                    
                    switch ($settingsChoice) {
                        "1" { $script:Subnet = Read-Host "  Enter subnet (e.g., 192.168.1.0/24)" }
                        "2" { $script:Username = Read-Host "  Enter username" }
                        "3" { $script:Password = Read-Host "  Enter password" }
                        "4" { $script:OutputPath = Read-Host "  Enter output path (e.g., C:\Reports\inventory.csv)" }
                        "5" { 
                            $timeout = Read-Host "  Enter timeout in seconds (current: $($script:CommandTimeout))"
                            if ($timeout -match '^\d+$') { $script:CommandTimeout = [int]$timeout }
                        }
                        "6" { 
                            $threads = Read-Host "  Enter thread count (current: $($script:Threads))"
                            if ($threads -match '^\d+$') { $script:Threads = [int]$threads }
                        }
                        "0" { $settingsLoop = $false }
                        default { }
                    }
                }
            }
            "6" {
                # View Settings
                Show-CurrentSettings
            }
            "7" {
                # Test Single Host
                Test-SingleHost
            }
            "8" {
                # Help
                Show-Help
            }
            "9" {
                # About
                Show-About
            }
            "0" {
                # Exit
                Show-Banner
                Write-Host "  Thank you for using AXIS!" -ForegroundColor Cyan
                Write-Host ""
                Write-Host "  GitHub: https://github.com/IICarrionII/Axis" -ForegroundColor Gray
                Write-Host ""
                Write-Host "  Goodbye!" -ForegroundColor Yellow
                Write-Host ""
                exit 0
            }
            default {
                # Invalid choice - just redraw menu
            }
        }
    }
}

# Start the program
Main

#endregion
