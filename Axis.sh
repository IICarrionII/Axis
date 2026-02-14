#!/bin/bash
#===============================================================================
#
#    AXIS - Asset eXploration & Inventory Scanner
#    Cross-Platform Hardware & Software Inventory Tool
#    
#    Created by: Yan Carrion
#    GitHub: https://github.com/IICarrionII/Axis
#    
#    Bash Version - Mirrors PowerShell functionality
#    
#    Run From: Linux (RHEL, CentOS, Ubuntu), Solaris, macOS
#    Scans:    Linux, Solaris SPARC (Windows requires PowerShell version)
#
#===============================================================================

VERSION="1.1.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

SUBNET=""
OUTPUT_PATH=""
COMMAND_TIMEOUT=60
declare -a CREDENTIALS=()
LAST_WORKING_CRED=""

show_banner() {
    clear
    echo ""
    echo "     █████╗ ██╗  ██╗██╗███████╗"
    echo "    ██╔══██╗╚██╗██╔╝██║██╔════╝"
    echo "    ███████║ ╚███╔╝ ██║███████╗"
    echo "    ██╔══██║ ██╔██╗ ██║╚════██║"
    echo "    ██║  ██║██╔╝ ██╗██║███████║"
    echo "    ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝╚══════╝"
    echo ""
    echo "  ╔═══════════════════════════════════════════════════════════╗"
    echo "  ║   AXIS - Asset eXploration & Inventory Scanner            ║"
    echo "  ║   Supports: Linux (RHEL) | Solaris SPARC                  ║"
    echo "  ║   Air-Gapped Network Ready | Multi-Credential Support     ║"
    echo "  ╠═══════════════════════════════════════════════════════════╣"
    echo "  ║   Created by: Yan Carrion | github.com/IICarrionII/Axis   ║"
    echo "  ╚═══════════════════════════════════════════════════════════╝"
    echo "  Version: $VERSION | Bash Edition"
    echo ""
}

show_main_menu() {
    show_banner
    echo "  [1] Scan Subnet          [2] Scan Single Host"
    echo "  [3] Manage Credentials   [4] Settings   [5] View Settings"
    echo "  [6] Help                 [7] About      [0] Exit"
    echo ""
}

generate_ip_range() {
    local cidr="$1" base="${cidr%/*}" prefix="${cidr#*/}"
    IFS='.' read -r i1 i2 i3 i4 <<< "$base"
    local ip_int=$(( (i1<<24)+(i2<<16)+(i3<<8)+i4 ))
    local mask=$(( 0xFFFFFFFF << (32-prefix) & 0xFFFFFFFF ))
    local net=$(( ip_int & mask )) bcast=$(( net | (~mask & 0xFFFFFFFF) ))
    for (( i=net+1; i<bcast; i++ )); do
        echo "$(( (i>>24)&255 )).$(( (i>>16)&255 )).$(( (i>>8)&255 )).$(( i&255 ))"
    done
}

test_port() {
    local ip="$1" port="$2" t="${3:-2}"
    nc -z -w "$t" "$ip" "$port" &>/dev/null || timeout "$t" bash -c "echo >/dev/tcp/$ip/$port" 2>/dev/null
}

ssh_cmd() {
    local ip="$1" user="$2" pass="$3" cmd="$4"
    local opts="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=$COMMAND_TIMEOUT"
    if command -v sshpass &>/dev/null && [[ -n "$pass" ]]; then
        sshpass -p "$pass" ssh $opts "$user@$ip" "$cmd" 2>/dev/null
    else
        ssh $opts -o BatchMode=yes "$user@$ip" "$cmd" 2>/dev/null
    fi
}

ssh_with_creds() {
    local ip="$1" cmd="$2"
    for cred in "${CREDENTIALS[@]}"; do
        IFS='|' read -r label user pass <<< "$cred"
        local result; result=$(ssh_cmd "$ip" "$user" "$pass" "$cmd")
        if [[ $? -eq 0 && -n "$result" ]]; then
            LAST_WORKING_CRED="$cred"
            echo "$result"
            return 0
        fi
    done
    return 1
}

detect_os() {
    local uname; uname=$(ssh_with_creds "$1" "uname -s" 2>/dev/null)
    case "$uname" in *SunOS*) echo "Solaris";; *Linux*) echo "Linux";; *) echo "Unknown";; esac
}

collect_linux() {
    local ip="$1"
    IFS='|' read -r _ user pass <<< "$LAST_WORKING_CRED"
    ssh_cmd "$ip" "$user" "$pass" 'hostname && echo VIRTUAL:$(systemd-detect-virt 2>/dev/null|grep -qv none && echo Yes || echo No) && echo MANUFACTURER:$(sudo dmidecode -s system-manufacturer 2>/dev/null||echo Unknown) && echo MODEL:$(sudo dmidecode -s system-product-name 2>/dev/null||echo Unknown) && echo SERIAL:$(sudo dmidecode -s system-serial-number 2>/dev/null||echo Unknown) && echo OS:$(. /etc/os-release 2>/dev/null && echo $PRETTY_NAME||uname -sr) && echo KERNEL:$(uname -r) && echo MEMORY:$(free -h 2>/dev/null|awk "/^Mem:/{print \$2}"||echo Unknown) && echo MEMTYPE:$(sudo dmidecode -t memory 2>/dev/null|grep Type:|grep -v Error|head -1|awk "{print \$2}"||echo Unknown) && echo FIRMWARE:$(sudo dmidecode -s bios-version 2>/dev/null||echo Unknown)'
}

collect_solaris() {
    local ip="$1"
    IFS='|' read -r _ user pass <<< "$LAST_WORKING_CRED"
    ssh_cmd "$ip" "$user" "$pass" 'echo HOSTNAME:$(hostname) && echo VIRTUAL:$([ -x /usr/sbin/virtinfo ] && /usr/sbin/virtinfo 2>/dev/null|grep -qi virtual && echo Yes || echo No) && echo MANUFACTURER:$(/usr/sbin/prtconf -pv 2>/dev/null|grep banner-name|head -1|cut -d\x27 -f2||echo Unknown) && echo MODEL:$(/usr/sbin/prtconf -b 2>/dev/null|head -1||echo Unknown) && echo SERIAL:$(/usr/bin/hostid 2>/dev/null||echo Unknown) && echo OS:SunOS $(uname -r) && echo KERNEL:$(uname -v) && echo MEMORY:$(/usr/sbin/prtconf 2>/dev/null|grep "Memory size"|awk "{print \$3,\$4}"||echo Unknown) && echo MEMTYPE:Unknown && echo FIRMWARE:Unknown'
}

parse_output() {
    local output="$1" ip="$2" ostype="$3"
    local hostname="Unknown" virtual="Unknown" mfr="Unknown" model="Unknown" serial="Unknown"
    local os="Unknown" kernel="Unknown" mem="Unknown" memtype="Unknown" fw="Unknown"
    while IFS= read -r line; do
        line=$(echo "$line"|tr -d '\r'|xargs); [[ -z "$line" || "$line" == *Warning* ]] && continue
        if [[ "$line" == *:* ]]; then
            local k="${line%%:*}" v="${line#*:}"; v=$(echo "$v"|xargs)
            case "${k^^}" in
                HOSTNAME) hostname="$v";; VIRTUAL) virtual="$v";; MANUFACTURER) mfr="$v";;
                MODEL) model="$v";; SERIAL) serial="$v";; OS) os="$v";; KERNEL) kernel="$v";;
                MEMORY) mem="$v";; MEMTYPE) memtype="$v";; FIRMWARE) fw="$v";;
            esac
        elif [[ "$hostname" == "Unknown" && ${#line} -lt 64 ]]; then hostname="$line"; fi
    done <<< "$output"
    echo "$hostname|$virtual|$mfr|$model|$serial|$os|$kernel|$mem|$memtype|$fw|$ostype|Success"
}

add_cred() {
    echo ""; read -p "  Label: " label; read -p "  Username: " user; read -s -p "  Password: " pass; echo ""
    [[ -n "$user" && -n "$pass" ]] && CREDENTIALS+=("$label|$user|$pass") && echo "  Added!" || echo "  Required!"
    read -p "  Enter to continue..."
}

view_creds() {
    echo ""; if [[ ${#CREDENTIALS[@]} -eq 0 ]]; then echo "  None stored."; else
        local i=1; for c in "${CREDENTIALS[@]}"; do IFS='|' read -r l u _ <<< "$c"; echo "  [$i] ${l:-Cred $i} - $u"; ((i++)); done
    fi; read -p "  Enter to continue..."
}

remove_cred() {
    if [[ ${#CREDENTIALS[@]} -eq 0 ]]; then echo "  None."; read -p "  Enter..."; return; fi
    local i=1; for c in "${CREDENTIALS[@]}"; do IFS='|' read -r l u _ <<< "$c"; echo "  [$i] $l - $u"; ((i++)); done
    read -p "  Number to remove: " n
    [[ "$n" =~ ^[0-9]+$ && $n -gt 0 && $n -le ${#CREDENTIALS[@]} ]] && unset 'CREDENTIALS[$((n-1))]' && CREDENTIALS=("${CREDENTIALS[@]}")
    read -p "  Enter..."
}

get_creds() {
    if [[ ${#CREDENTIALS[@]} -eq 0 ]]; then
        echo "  No credentials. Add one:"; read -p "  Label: " l; read -p "  User: " u; read -s -p "  Pass: " p; echo ""
        [[ -n "$u" && -n "$p" ]] && CREDENTIALS+=("$l|$u|$p") && return 0 || return 1
    fi; return 0
}

scan_single() {
    show_banner; echo "  === SCAN SINGLE HOST ==="; echo ""
    command -v sshpass &>/dev/null || echo "  WARNING: sshpass not found"
    get_creds || { read -p "  Enter..."; return; }
    read -p "  IP Address: " ip; [[ -z "$ip" ]] && return
    echo "  Scanning $ip..."
    echo -n "  Port 22: "; test_port "$ip" 22 && echo "OPEN" || { echo "CLOSED"; read -p "  Enter..."; return; }
    echo -n "  OS: "; local os=$(detect_os "$ip"); echo "$os"
    [[ "$os" == "Unknown" ]] && { echo "  Cannot detect OS"; read -p "  Enter..."; return; }
    echo "  Collecting info..."
    local out; [[ "$os" == "Linux" ]] && out=$(collect_linux "$ip") || out=$(collect_solaris "$ip")
    local parsed=$(parse_output "$out" "$ip" "$os")
    IFS='|' read -r hn virt mfr mod ser oss kern mem memt fw ost stat <<< "$parsed"
    echo ""; echo "  === RESULTS ==="; echo "  Hostname: $hn"; echo "  IP: $ip"; echo "  OS: $oss"
    echo "  Manufacturer: $mfr"; echo "  Model: $mod"; echo "  Serial: $ser"; echo "  Memory: $mem"
    echo "  Virtual: $virt"; echo "  Kernel: $kern"; echo "  Status: $stat"
    read -p "  Save CSV? (Y/N): " s
    if [[ "$s" == "Y" || "$s" == "y" ]]; then
        local f="$SCRIPT_DIR/AXIS_${ip//./_}_$(date +%Y%m%d_%H%M%S).csv"
        echo '"Type","Hostname","IP","Virtual","Manufacturer","Model","Serial","OS","FW","Memory","MemType","Kernel","OSType","Status"' > "$f"
        echo "\"Server\",\"$hn\",\"$ip\",\"$virt\",\"$mfr\",\"$mod\",\"$ser\",\"$oss\",\"$fw\",\"$mem\",\"$memt\",\"$kern\",\"$ost\",\"$stat\"" >> "$f"
        echo "  Saved: $f"
    fi; read -p "  Enter..."
}

scan_subnet() {
    show_banner; echo "  === SUBNET SCAN ==="; echo ""
    command -v sshpass &>/dev/null || echo "  WARNING: sshpass not found"
    get_creds || { read -p "  Enter..."; return; }
    local sub="$SUBNET"; [[ -z "$sub" ]] && read -p "  Subnet (e.g., 192.168.1.0/24): " sub
    [[ -z "$sub" ]] && return
    local f="$SCRIPT_DIR/AXIS_$(date +%Y%m%d_%H%M%S).csv"
    echo "  Subnet: $sub"; echo "  Credentials: ${#CREDENTIALS[@]}"; echo "  Output: $f"
    read -p "  Proceed? (Y/N): " c; [[ "$c" != "Y" && "$c" != "y" ]] && return
    echo "  Generating IPs..."; local ips=($(generate_ip_range "$sub")); echo "  Total: ${#ips[@]}"
    echo "  Phase 1: Discovery..."
    local hosts=(); local n=0; local tot=${#ips[@]}
    for ip in "${ips[@]}"; do ((n++)); (( n%10==0 )) && printf "\r  %d/%d" "$n" "$tot"
        test_port "$ip" 22 1 && hosts+=("$ip"); done
    echo ""; echo "  SSH hosts: ${#hosts[@]}"
    [[ ${#hosts[@]} -eq 0 ]] && { echo "  None found!"; read -p "  Enter..."; return; }
    echo "  Phase 2: Collecting..."
    echo '"Type","Hostname","IP","Virtual","Manufacturer","Model","Serial","OS","FW","Memory","MemType","Kernel","OSType","Status"' > "$f"
    n=0; local ok=0 fail=0; tot=${#hosts[@]}
    for ip in "${hosts[@]}"; do ((n++)); echo -n "  [$n/$tot] $ip"
        local os=$(detect_os "$ip"); echo -n " [$os]"
        local out; [[ "$os" == "Linux" ]] && out=$(collect_linux "$ip") || out=$(collect_solaris "$ip")
        local p=$(parse_output "$out" "$ip" "$os")
        IFS='|' read -r hn vi mf mo se os ke me mt fw ot st <<< "$p"
        echo "\"Server\",\"$hn\",\"$ip\",\"$vi\",\"$mf\",\"$mo\",\"$se\",\"$os\",\"$fw\",\"$me\",\"$mt\",\"$ke\",\"$ot\",\"$st\"" >> "$f"
        [[ "$st" == "Success" ]] && { echo " OK $hn"; ((ok++)); } || { echo " FAIL"; ((fail++)); }
    done
    echo ""; echo "  === RESULTS ==="; echo "  Saved: $f"; echo "  Success: $ok, Failed: $fail"
    read -p "  Enter..."
}

show_settings() {
    show_banner; echo "  Subnet: ${SUBNET:-Not set}"; echo "  Output: ${OUTPUT_PATH:-Auto}"
    echo "  Timeout: ${COMMAND_TIMEOUT}s"; echo "  Credentials: ${#CREDENTIALS[@]}"
    echo "  sshpass: $(command -v sshpass 2>/dev/null || echo 'Not found')"
    if [[ ${#CREDENTIALS[@]} -gt 0 ]]; then echo "  Stored:"; local i=1
        for c in "${CREDENTIALS[@]}"; do IFS='|' read -r l u _ <<< "$c"; echo "    [$i] $l - $u"; ((i++)); done
    fi; read -p "  Enter..."
}

show_help() {
    show_banner
    echo "  QUICK START:"
    echo "  1. Add credentials (option 3)"
    echo "  2. Scan subnet or single host"
    echo "  3. Results saved to CSV"
    echo ""
    echo "  REQUIREMENTS:"
    echo "  - sshpass for password auth (yum install sshpass)"
    echo "  - SSH access to targets"
    echo "  - sudo on targets for hardware info"
    echo ""
    echo "  NOTE: For Windows scanning, use Axis.ps1"
    read -p "  Enter..."
}

show_about() {
    show_banner; echo "  AXIS v$VERSION (Bash)"; echo "  By Yan Carrion"
    echo "  github.com/IICarrionII/Axis"; echo "  MIT License"; read -p "  Enter..."
}

cred_menu() {
    while true; do show_banner; echo "  [1] Add  [2] View  [3] Remove  [4] Clear  [0] Back"; read -p "  Choice: " c
        case "$c" in 1) add_cred;; 2) view_creds;; 3) remove_cred;; 4) CREDENTIALS=(); echo "  Cleared."; read -p "  Enter...";; 0) break;; esac
    done
}

settings_menu() {
    while true; do show_banner; echo "  [1] Subnet  [2] Output  [3] Timeout  [0] Back"; read -p "  Choice: " c
        case "$c" in 1) read -p "  Subnet: " SUBNET;; 2) read -p "  Output: " OUTPUT_PATH;;
            3) read -p "  Timeout: " t; [[ "$t" =~ ^[0-9]+$ ]] && COMMAND_TIMEOUT=$t;; 0) break;; esac
    done
}

# Main loop
while true; do
    show_main_menu; read -p "  Choice: " choice
    case "$choice" in
        1) scan_subnet;; 2) scan_single;; 3) cred_menu;; 4) settings_menu;;
        5) show_settings;; 6) show_help;; 7) show_about;;
        0) show_banner; echo "  Goodbye!"; exit 0;;
    esac
done
