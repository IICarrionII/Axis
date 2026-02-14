#!/bin/bash
# AXIS - Asset eXploration & Inventory Scanner v1.1.0 (Bash Edition)
# Created by: Yan Carrion | GitHub: github.com/IICarrionII/Axis
# Note: This is a backup scanner for Linux/Solaris only. Use Axis.ps1 for full features.

VERSION="1.1.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SUBNET="" USERNAME="" PASSWORD="" OUTPUT_FILE="" TIMEOUT=15

show_banner() {
    clear
    echo ""
    echo "     AXIS - Asset eXploration & Inventory Scanner"
    echo "     Version $VERSION | Bash Edition (Linux/Solaris Only)"
    echo "     github.com/IICarrionII/Axis"
    echo ""
}

show_menu() {
    show_banner
    echo "  [1] Scan Subnet"
    echo "  [2] Scan Single Host"
    echo "  [3] Configure Settings"
    echo "  [4] View Settings"
    echo "  [5] Help"
    echo "  [0] Exit"
    echo ""
    read -p "  Choice: " choice
}

get_settings() {
    [[ -z "$SUBNET" ]] && read -p "  Subnet (e.g., 192.168.1.0/24): " SUBNET
    [[ -z "$USERNAME" ]] && read -p "  Username: " USERNAME
    [[ -z "$PASSWORD" ]] && read -s -p "  Password: " PASSWORD && echo ""
    [[ -z "$OUTPUT_FILE" ]] && OUTPUT_FILE="$SCRIPT_DIR/AXIS_$(date +%Y%m%d_%H%M%S).csv"
}

generate_ips() {
    local cidr="$1" base="${cidr%/*}" prefix="${cidr#*/}"
    IFS='.' read -r i1 i2 i3 i4 <<< "$base"
    local ip_int=$(( (i1<<24) + (i2<<16) + (i3<<8) + i4 ))
    local mask=$(( 0xFFFFFFFF << (32-prefix) & 0xFFFFFFFF ))
    local net=$(( ip_int & mask )) bcast=$(( net | (~mask & 0xFFFFFFFF) ))
    for (( i=net+1; i<bcast; i++ )); do
        echo "$(( (i>>24)&255 )).$(( (i>>16)&255 )).$(( (i>>8)&255 )).$(( i&255 ))"
    done
}

test_port() {
    nc -z -w 2 "$1" "$2" &>/dev/null || timeout 2 bash -c "echo >/dev/tcp/$1/$2" 2>/dev/null
}

ssh_cmd() {
    local ip="$1" cmd="$2"
    if command -v sshpass &>/dev/null; then
        sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=$TIMEOUT "$USERNAME@$ip" "$cmd" 2>/dev/null
    else
        ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o BatchMode=yes -o ConnectTimeout=$TIMEOUT "$USERNAME@$ip" "$cmd" 2>/dev/null
    fi
}

detect_os() {
    local uname=$(ssh_cmd "$1" "uname -s" 2>/dev/null)
    case "$uname" in *SunOS*) echo "Solaris";; *Linux*) echo "Linux";; *) echo "Unknown";; esac
}

collect_linux() {
    local ip="$1"
    ssh_cmd "$ip" 'hostname && echo VIRTUAL:$(systemd-detect-virt 2>/dev/null|grep -qv none && echo Yes || echo No) && echo MANUFACTURER:$(sudo dmidecode -s system-manufacturer 2>/dev/null||echo Unknown) && echo MODEL:$(sudo dmidecode -s system-product-name 2>/dev/null||echo Unknown) && echo SERIAL:$(sudo dmidecode -s system-serial-number 2>/dev/null||echo Unknown) && echo OS:$(. /etc/os-release 2>/dev/null && echo $PRETTY_NAME||uname -sr) && echo KERNEL:$(uname -r) && echo MEMORY:$(free -h 2>/dev/null|awk "/^Mem:/{print \$2}"||echo Unknown) && echo FIRMWARE:$(sudo dmidecode -s bios-version 2>/dev/null||echo Unknown)'
}

collect_solaris() {
    local ip="$1"
    ssh_cmd "$ip" 'echo HOSTNAME:$(hostname) && echo VIRTUAL:No && echo MODEL:$(/usr/sbin/prtconf -b 2>/dev/null|head -1||echo Unknown) && echo SERIAL:$(/usr/bin/hostid 2>/dev/null||echo Unknown) && echo OS:SunOS $(uname -r) && echo KERNEL:$(uname -v) && echo MEMORY:$(/usr/sbin/prtconf 2>/dev/null|grep "Memory size"|awk "{print \$3,\$4}"||echo Unknown)'
}

scan_host() {
    local ip="$1"
    echo -n "  $ip "
    if ! test_port "$ip" 22; then echo "[CLOSED]"; return; fi
    local os=$(detect_os "$ip")
    echo -n "[$os] "
    local output
    case "$os" in Linux) output=$(collect_linux "$ip");; Solaris) output=$(collect_solaris "$ip");; *) echo "[SKIP]"; return;; esac
    if [[ -n "$output" ]]; then
        local hostname=$(echo "$output"|head -1)
        echo "[OK] $hostname"
        echo "\"Server\",\"$hostname\",\"$ip\",\"$os\",\"Success\"" >> "$OUTPUT_FILE"
    else
        echo "[FAILED]"
    fi
}

scan_subnet() {
    get_settings
    echo ""; echo "  Generating IPs..."
    local ips=($(generate_ips "$SUBNET"))
    echo "  Total: ${#ips[@]}"
    echo '"Type","Hostname","IP","OS","Status"' > "$OUTPUT_FILE"
    echo ""; echo "  Scanning..."
    for ip in "${ips[@]}"; do scan_host "$ip"; done
    echo ""; echo "  Saved: $OUTPUT_FILE"
    read -p "  Press Enter..."
}

scan_single() {
    [[ -z "$USERNAME" ]] && read -p "  Username: " USERNAME
    [[ -z "$PASSWORD" ]] && read -s -p "  Password: " PASSWORD && echo ""
    read -p "  IP Address: " ip
    echo ""; scan_host "$ip"
    read -p "  Press Enter..."
}

configure() {
    read -p "  Subnet: " SUBNET
    read -p "  Username: " USERNAME
    read -s -p "  Password: " PASSWORD; echo ""
    read -p "  Timeout (current: $TIMEOUT): " t; [[ "$t" =~ ^[0-9]+$ ]] && TIMEOUT=$t
    read -p "  Press Enter..."
}

view_settings() {
    show_banner
    echo "  Subnet:   ${SUBNET:-Not set}"
    echo "  Username: ${USERNAME:-Not set}"
    echo "  Password: $(if [[ -n "$PASSWORD" ]]; then echo "********"; else echo "Not set"; fi)"
    echo "  Timeout:  $TIMEOUT seconds"
    echo "  sshpass:  $(command -v sshpass &>/dev/null && echo "Available" || echo "Not found")"
    echo ""
    read -p "  Press Enter..."
}

show_help() {
    show_banner
    echo "  This is the Bash version of AXIS for Linux/Solaris systems."
    echo "  For full features (Windows, multi-credential), use Axis.ps1"
    echo ""
    echo "  Requirements:"
    echo "  - SSH access to targets"
    echo "  - sshpass for password auth (optional)"
    echo "  - sudo access on targets for hardware info"
    echo ""
    read -p "  Press Enter..."
}

# Main
while true; do
    show_menu
    case "$choice" in
        1) scan_subnet;;
        2) scan_single;;
        3) configure;;
        4) view_settings;;
        5) show_help;;
        0) echo "  Goodbye!"; exit 0;;
    esac
done
