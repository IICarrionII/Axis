#!/usr/bin/env pwsh
#requires -Version 5.1
# AXIS - Asset eXploration & Inventory Scanner v1.1.0
# Created by: Yan Carrion | GitHub: github.com/IICarrionII/Axis

$script:Version = "1.1.0"
$script:Subnet = ""
$script:OutputPath = ""
$script:CommandTimeout = 60
$script:PlinkPath = ""
$script:Credentials = [System.Collections.ArrayList]::new()

function Show-Banner { Clear-Host; Write-Host "`n     AXIS - Asset eXploration & Inventory Scanner`n     Version $($script:Version) | github.com/IICarrionII/Axis`n" -ForegroundColor Cyan }

function Show-MainMenu {
    Show-Banner
    Write-Host "  [1] Scan Subnet (All)    [2] Scan Single Host"
    Write-Host "  [3] Linux/Solaris Only   [4] Windows Only"
    Write-Host "  [5] Manage Credentials   [6] Settings   [7] View Settings"
    Write-Host "  [8] Help   [9] About   [0] Exit`n"
    return (Read-Host "  Choice")
}

function Get-IPRange { param([string]$CIDR); $n,$p=$CIDR-split'/'; $b=[System.Net.IPAddress]::Parse($n).GetAddressBytes(); [Array]::Reverse($b); $i=[BitConverter]::ToUInt32($b,0); $m=[UInt32]([Math]::Pow(2,32)-[Math]::Pow(2,32-[int]$p)); $s=$i-band$m; $e=$s-bor(-bnot$m); $r=@(); for($x=$s+1;$x-lt$e;$x++){$y=[BitConverter]::GetBytes($x);[Array]::Reverse($y);$r+=[System.Net.IPAddress]::new($y).ToString()}; $r }
function Test-Port { param($IP,$Port,$T=1000); try{$c=New-Object Net.Sockets.TcpClient;$w=$c.BeginConnect($IP,$Port,$null,$null);if($w.AsyncWaitHandle.WaitOne($T,$false)){try{$c.EndConnect($w);$c.Close();$true}catch{$false}}else{$c.Close();$false}}catch{$false} }
function Initialize-Plink { @("$PSScriptRoot\plink.exe",".\plink.exe")|%{if(Test-Path $_ -EA 0){$script:PlinkPath=(Resolve-Path $_).Path;return $true}};$false }

function Invoke-PlinkCommand { param($IP,$U,$P,$Cmd,$T)
    try { $a="-ssh -batch -pw `"$P`" $U@$IP `"$Cmd`""; $pi=New-Object Diagnostics.ProcessStartInfo; $pi.FileName=$script:PlinkPath; $pi.Arguments=$a; $pi.UseShellExecute=$false; $pi.CreateNoWindow=$true; $pi.RedirectStandardOutput=$true; $pi.RedirectStandardError=$true
        $pr=New-Object Diagnostics.Process; $pr.StartInfo=$pi; $ob=New-Object Text.StringBuilder; $eb=New-Object Text.StringBuilder
        $oe=Register-ObjectEvent $pr OutputDataReceived -Action {if($EventArgs.Data){[void]$Event.MessageData.AppendLine($EventArgs.Data)}} -MessageData $ob
        $ee=Register-ObjectEvent $pr ErrorDataReceived -Action {if($EventArgs.Data){[void]$Event.MessageData.AppendLine($EventArgs.Data)}} -MessageData $eb
        [void]$pr.Start(); $pr.BeginOutputReadLine(); $pr.BeginErrorReadLine()
        if(-not $pr.WaitForExit($T*1000)){$pr.Kill()}; Start-Sleep -Milliseconds 100
        Unregister-Event $oe.Name -Force -EA 0; Unregister-Event $ee.Name -Force -EA 0
        $o=$ob.ToString(); $e=$eb.ToString()
        if($e-match"host key is not cached"){return @{Success=$false;NeedHostKey=$true}}
        if($pr.ExitCode-eq 0-or$o.Trim()){@{Success=$true;Output=$o}}else{@{Success=$false;Error=$e}}
    }catch{@{Success=$false;Error=$_.Exception.Message}}
}

function Add-PlinkHostKey { param($IP,$U,$P); Write-Host "`n  Host key not cached - type 'y' and Enter..." -ForegroundColor Yellow
    $pi=New-Object Diagnostics.ProcessStartInfo; $pi.FileName=$script:PlinkPath; $pi.Arguments="-ssh -pw `"$P`" $U@$IP `"echo done`""; $pi.CreateNoWindow=$false
    $pr=[Diagnostics.Process]::Start($pi); $pr.WaitForExit(30000); $pr.ExitCode-eq 0
}

function Invoke-PlinkWithHostKey { param($IP,$U,$P,$Cmd,$T); $r=Invoke-PlinkCommand $IP $U $P $Cmd $T; if($r.NeedHostKey){if(Add-PlinkHostKey $IP $U $P){$r=Invoke-PlinkCommand $IP $U $P $Cmd $T}}; $r }
function Invoke-PlinkWithCreds { param($IP,$Cmd,$T); foreach($c in $script:Credentials){$r=Invoke-PlinkWithHostKey $IP $c.Username $c.Password $Cmd $T; if($r.Success){return @{Success=$true;Output=$r.Output;Cred=$c}}}; @{Success=$false} }

function Get-RemoteOS { param($IP); $r=Invoke-PlinkWithCreds $IP "uname -s" 15; if($r.Success){$o=$r.Output.ToLower(); if($o-match"sunos"){@{OS="Solaris";Cred=$r.Cred}}elseif($o-match"linux"){@{OS="Linux";Cred=$r.Cred}}else{@{OS="Unknown"}}}else{@{OS="Unknown"}} }

function Parse-Unix { param($Out,$IP,$OS); $info=@{HOSTNAME='Unknown';VIRTUAL='Unknown';MANUFACTURER='Unknown';MODEL='Unknown';SERIAL='Unknown';OS='Unknown';KERNEL='Unknown';MEMORY='Unknown';MEMTYPE='Unknown';FIRMWARE='Unknown'}
    ($Out-split"`n"|%{$_.Trim()}|?{$_-and$_-notmatch'^Warning'})|%{if($_-match'^(\w+):(.*)$'){$k=$matches[1].ToUpper();$v=$matches[2].Trim();if($v-and$info.ContainsKey($k)){$info[$k]=$v}}elseif($info.HOSTNAME-eq'Unknown'-and$_-notmatch':'-and$_.Length-gt0-and$_.Length-lt64){$info.HOSTNAME=$_}}
    [PSCustomObject]@{'Component Type'='Server';Hostname=$info.HOSTNAME;'IP Address'=$IP;'Virtual Asset'=$info.VIRTUAL;Manufacturer=$info.MANUFACTURER;'Model Number'=$info.MODEL;'Serial Number'=$info.SERIAL;'OS/IOS'=$info.OS;'FW Version'=$info.FIRMWARE;'Memory Size'=$info.MEMORY;'Memory Type'=$info.MEMTYPE;'Kernel Version'=$info.KERNEL;'OS Type'=$OS;'Scan Status'='Success'}
}

function New-Failed { param($IP,$OS,$Err); [PSCustomObject]@{'Component Type'='Server';Hostname='Unknown';'IP Address'=$IP;'Virtual Asset'='Unknown';Manufacturer='Unknown';'Model Number'='Unknown';'Serial Number'='Unknown';'OS/IOS'='Unknown';'FW Version'='Unknown';'Memory Size'='Unknown';'Memory Type'='Unknown';'Kernel Version'='Unknown';'OS Type'=$OS;'Scan Status'="Failed: $Err"} }

function Get-LinuxInfo { param($IP,$Cred,$T)
    $cmd='hostname && echo VIRTUAL:$(systemd-detect-virt 2>/dev/null|grep -qv none && echo Yes || echo No) && echo MANUFACTURER:$(sudo dmidecode -s system-manufacturer 2>/dev/null||echo Unknown) && echo MODEL:$(sudo dmidecode -s system-product-name 2>/dev/null||echo Unknown) && echo SERIAL:$(sudo dmidecode -s system-serial-number 2>/dev/null||echo Unknown) && echo OS:$(. /etc/os-release 2>/dev/null && echo $PRETTY_NAME||uname -sr) && echo KERNEL:$(uname -r) && echo MEMORY:$(free -h 2>/dev/null|awk "/^Mem:/{print \$2}"||echo Unknown) && echo MEMTYPE:$(sudo dmidecode -t memory 2>/dev/null|grep Type:|grep -v Error|head -1|awk "{print \$2}"||echo Unknown) && echo FIRMWARE:$(sudo dmidecode -s bios-version 2>/dev/null||echo Unknown)'
    $r=Invoke-PlinkWithHostKey $IP $Cred.Username $Cred.Password $cmd $T; if($r.Success){Parse-Unix $r.Output $IP "Linux"}else{New-Failed $IP "Linux" $r.Error}
}

function Get-SolarisInfo { param($IP,$Cred,$T)
    $cmd='echo HOSTNAME:$(hostname) && echo VIRTUAL:$([ -x /usr/sbin/virtinfo ] && /usr/sbin/virtinfo 2>/dev/null|grep -qi virtual && echo Yes || echo No) && echo MANUFACTURER:$(/usr/sbin/prtconf -pv 2>/dev/null|grep banner-name|head -1|cut -d\x27 -f2||echo Unknown) && echo MODEL:$(/usr/sbin/prtconf -b 2>/dev/null|head -1||echo Unknown) && echo SERIAL:$(/usr/bin/hostid 2>/dev/null||echo Unknown) && echo OS:SunOS $(uname -r) && echo KERNEL:$(uname -v) && echo MEMORY:$(/usr/sbin/prtconf 2>/dev/null|grep "Memory size"|awk "{print \$3,\$4}"||echo Unknown) && echo MEMTYPE:Unknown && echo FIRMWARE:Unknown'
    $r=Invoke-PlinkWithHostKey $IP $Cred.Username $Cred.Password $cmd $T; if($r.Success){Parse-Unix $r.Output $IP "Solaris"}else{New-Failed $IP "Solaris" $r.Error}
}

function Get-WindowsInfo { param($IP,$T)
    foreach($c in $script:Credentials){ try{ $sp=ConvertTo-SecureString $c.Password -AsPlainText -Force; $cr=New-Object PSCredential($c.Username,$sp)
        $co=New-CimSessionOption -Protocol Dcom; $cs=New-CimSession -ComputerName $IP -Credential $cr -SessionOption $co -OperationTimeoutSec $T -EA Stop
        $s=Get-CimInstance -CimSession $cs Win32_ComputerSystem -EA Stop; $o=Get-CimInstance -CimSession $cs Win32_OperatingSystem -EA Stop; $b=Get-CimInstance -CimSession $cs Win32_BIOS -EA Stop
        Remove-CimSession $cs -EA 0
        $v=if($s.Model-match"Virtual|VMware|Hyper-V|KVM"){"Yes"}else{"No"}; $m=if($s.TotalPhysicalMemory){"$([math]::Round($s.TotalPhysicalMemory/1GB,1)) GB"}else{"Unknown"}
        return [PSCustomObject]@{'Component Type'='Server';Hostname=$s.Name;'IP Address'=$IP;'Virtual Asset'=$v;Manufacturer=$s.Manufacturer;'Model Number'=$s.Model;'Serial Number'=$b.SerialNumber;'OS/IOS'="$($o.Caption) $($o.Version)";'FW Version'=$b.SMBIOSBIOSVersion;'Memory Size'=$m;'Memory Type'='Unknown';'Kernel Version'=$o.BuildNumber;'OS Type'='Windows';'Scan Status'='Success'}
    }catch{continue}}; New-Failed $IP "Windows" "All credentials failed"
}

function Add-Cred { $l=Read-Host "  Label"; $u=Read-Host "  Username"; $p=Read-Host "  Password"; if($u-and$p){[void]$script:Credentials.Add(@{Label=$l;Username=$u;Password=$p}); Write-Host "  Added!" -ForegroundColor Green}; Read-Host "  Enter to continue" }
function View-Creds { Write-Host "`n  Credentials:"; if($script:Credentials.Count-eq 0){Write-Host "  None stored."}else{$i=1;$script:Credentials|%{Write-Host "  [$i] $($_.Label) - $($_.Username)";$i++}}; Read-Host "`n  Enter to continue" }
function Remove-Cred { if($script:Credentials.Count-eq 0){Write-Host "  None to remove.";return}; $i=1;$script:Credentials|%{Write-Host "  [$i] $($_.Label)";$i++}; $n=Read-Host "  Number to remove"; if($n-match'^\d+$'-and[int]$n-gt 0-and[int]$n-le$script:Credentials.Count){$script:Credentials.RemoveAt([int]$n-1);Write-Host "  Removed."}; Read-Host "  Enter" }

function Scan-SingleHost {
    Show-Banner; if(-not(Get-CredsForScan)){return}
    $ip=Read-Host "  Enter IP"; if(-not$ip){return}
    Write-Host "  Scanning $ip..." -ForegroundColor Yellow
    $ssh=Test-Port $ip 22; $wmi=Test-Port $ip 135
    Write-Host "  Ports: $(if($ssh){'SSH '}else{''})$(if($wmi){'WMI'}else{''})" -ForegroundColor Cyan
    $r=$null
    if($ssh-and$script:PlinkPath){$os=Get-RemoteOS $ip; Write-Host "  OS: $($os.OS)"; if($os.Cred){if($os.OS-eq"Linux"){$r=Get-LinuxInfo $ip $os.Cred $script:CommandTimeout}elseif($os.OS-eq"Solaris"){$r=Get-SolarisInfo $ip $os.Cred $script:CommandTimeout}}}
    if((-not$r-or$r.'Scan Status'-notmatch'Success')-and$wmi){$r=Get-WindowsInfo $ip $script:CommandTimeout}
    if($r){Write-Host "`n  Results:" -ForegroundColor Green; $r|Format-List; $s=Read-Host "  Save CSV? (Y/N)"; if($s-eq'Y'){$f=".\AXIS_$($ip.Replace('.','_'))_$(Get-Date -f 'yyyyMMdd_HHmmss').csv"; $r|Export-Csv $f -NoType; Write-Host "  Saved: $f"}}
    Read-Host "`n  Enter to continue"
}

function Scan-Subnet { param($SSH=$true,$Win=$true)
    Show-Banner; if(-not(Get-CredsForScan)){return}
    if($SSH-and-not$script:PlinkPath){Write-Host "  plink.exe not found!" -ForegroundColor Red; $SSH=$false}
    $sub=Read-Host "  Subnet (e.g., 192.168.1.0/24)"; if(-not$sub){return}
    Write-Host "  Generating IPs..."; $ips=Get-IPRange $sub; Write-Host "  Total: $($ips.Count)"
    Write-Host "  Phase 1: Discovery..."
    $sshH=[Collections.ArrayList]::new(); $winH=[Collections.ArrayList]::new()
    $ips|%{if($SSH-and(Test-Port $_ 22 500)){[void]$sshH.Add($_)}; if($Win-and(Test-Port $_ 135 500)){if(-not$sshH.Contains($_)){[void]$winH.Add($_)}}}
    Write-Host "  SSH: $($sshH.Count), WMI: $($winH.Count)"
    if(($sshH.Count+$winH.Count)-eq 0){Write-Host "  No hosts!"; Read-Host "  Enter"; return}
    Write-Host "  Phase 2: Collecting..."
    $results=[Collections.ArrayList]::new(); $tot=$sshH.Count+$winH.Count; $n=0
    $sshH|%{$n++; Write-Host "  [$n/$tot] $_" -NoNewline; $os=Get-RemoteOS $_; Write-Host " [$($os.OS)]" -NoNewline
        if($os.Cred){if($os.OS-eq"Solaris"){$i=Get-SolarisInfo $_ $os.Cred $script:CommandTimeout}else{$i=Get-LinuxInfo $_ $os.Cred $script:CommandTimeout}}else{$i=New-Failed $_ "SSH" "No creds"}
        [void]$results.Add($i); Write-Host $(if($i.'Scan Status'-eq'Success'){" OK $($i.Hostname)"}else{" FAIL"}) -ForegroundColor $(if($i.'Scan Status'-eq'Success'){'Green'}else{'Red'})}
    $winH|%{$n++; Write-Host "  [$n/$tot] $_ [Win]" -NoNewline; $i=Get-WindowsInfo $_ $script:CommandTimeout; [void]$results.Add($i)
        Write-Host $(if($i.'Scan Status'-eq'Success'){" OK $($i.Hostname)"}else{" FAIL"}) -ForegroundColor $(if($i.'Scan Status'-eq'Success'){'Green'}else{'Red'})}
    $f=".\AXIS_$(Get-Date -f 'yyyyMMdd_HHmmss').csv"; $results|Export-Csv $f -NoType
    Write-Host "`n  Saved: $f" -ForegroundColor Green; Write-Host "  Total: $($results.Count), Success: $(($results|?{$_.'Scan Status'-eq'Success'}).Count)"
    Read-Host "`n  Enter to continue"
}

function Get-CredsForScan { if($script:Credentials.Count-eq 0){Write-Host "  No credentials. Add one first." -ForegroundColor Yellow; Add-Cred}; $script:Credentials.Count-gt 0 }
function Show-Settings { Show-Banner; Write-Host "  Subnet: $(if($script:Subnet){$script:Subnet}else{'Not set'})"; Write-Host "  Timeout: $($script:CommandTimeout)s"; Write-Host "  Credentials: $($script:Credentials.Count)"; Write-Host "  plink: $(if($script:PlinkPath){$script:PlinkPath}else{'Not found'})"; Read-Host "`n  Enter" }
function Show-Help { Show-Banner; Write-Host "  1. Place plink.exe in same folder`n  2. Add credentials (option 5)`n  3. Scan subnet or single host`n`n  Supports: Linux, Solaris, Windows"; Read-Host "`n  Enter" }
function Show-About { Show-Banner; Write-Host "  AXIS v$($script:Version)`n  By Yan Carrion`n  github.com/IICarrionII/Axis`n`n  MIT License"; Read-Host "`n  Enter" }

# Main
Initialize-Plink|Out-Null
while($true){ switch(Show-MainMenu){ "1"{Scan-Subnet} "2"{Scan-SingleHost} "3"{Scan-Subnet -Win $false} "4"{Scan-Subnet -SSH $false} "5"{$l=$true;while($l){Show-Banner;Write-Host "  [1]Add [2]View [3]Remove [0]Back";switch(Read-Host "  Choice"){"1"{Add-Cred}"2"{View-Creds}"3"{Remove-Cred}"0"{$l=$false}}}} "6"{$script:Subnet=Read-Host "  Subnet";$t=Read-Host "  Timeout";if($t-match'^\d+$'){$script:CommandTimeout=[int]$t}} "7"{Show-Settings} "8"{Show-Help} "9"{Show-About} "0"{Write-Host "`n  Goodbye!`n";exit} }}
