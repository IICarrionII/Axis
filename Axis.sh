#!/bin/bash
#===============================================================================
#
#    AXIS - Asset eXploration & Inventory Scanner
#    Cross-Platform Hardware & Software Inventory Tool
#    
#    Created by: Yan Carrion
#    GitHub: https://github.com/IICarrionII/Axis
#    
#    Bash Version - No Dependencies Required
#    Works on: RHEL 6/7/8/9, CentOS, Solaris 10/11, Ubuntu, Debian
#    
#    Scans: Linux, Solaris SPARC, Windows (limited)
#
#===============================================================================

VERSION="1.0.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
GRAY='\033[0;90m'
NC='\033[0m' # No Color

# Global variables
SUBNET=""
USERNAME=""
PASSWORD=""
OUTPUT_FILE=""
TIMEOUT=10
SCAN_SSH=true
SCAN_WINRM=false  # Limited on pure bash

# Detect OS we're running on
detect_local_os() {
    if [[ "$(uname -s)" == "SunOS" ]]; then
        echo "Solaris"
    elif [[ "$(uname -s)" == "Linux" ]]; then
        echo "Linux"
    else
        echo "Unknown"
    fi
}

LOCAL_OS=$(detect_local_os)

#===============================================================================
# BANNER AND MENUS
#===============================================================================

show_banner() {
    clear
    echo ""
    echo -e "${CYAN}     █████╗ ██╗  ██╗██╗███████╗${NC}"
    echo -e "${CYAN}    ██╔══██╗╚██╗██╔╝██║██╔════╝${NC}"
    echo -e "${CYAN}    ███████║ ╚███╔╝ ██║███████╗${NC}"
    echo -e "${CYAN}    ██╔══██║ ██╔██╗ ██║╚════██║${NC}"
    echo -e "${CYAN}    ██║  ██║██╔╝ ██╗██║███████║${NC}"
    echo -e "${CYAN}    ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝╚══════╝${NC}"
    echo ""
    echo -e "${YELLOW}  ╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}  ║   AXIS - Asset eXploration & Inventory Scanner            ║${NC}"
    echo -e "${YELLOW}  ║   Cross-Platform Hardware & Software Inventory Tool       ║${NC}"
    echo -e "${YELLOW}  ╠═══════════════════════════════════════════════════════════╣${NC}"
    echo -e "${YELLOW}  ║   Supports: Linux (RHEL) | Solaris SPARC                  ║${NC}"
    echo -e "${YELLOW}  ║   Air-Gapped Network Ready - No Dependencies Required     ║${NC}"
    echo -e "${YELLOW}  ╠═══════════════════════════════════════════════════════════╣${NC}"
    echo -e "${GRAY}  ║   Created by: Yan Carrion                                 ║${NC}"
    echo -e "${GRAY}  ║   GitHub: github.com/IICarrionII/Axis                     ║${NC}"
    echo -e "${YELLOW}  ╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  Running on: ${GRAY}$LOCAL_OS${NC} | Version: ${GRAY}$VERSION${NC} | Bash Version"
    echo ""
}

show_main_menu() {
    show_banner
    echo -e "${WHITE}  ┌─────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${WHITE}  │                      MAIN MENU                              │${NC}"
    echo -e "${WHITE}  ├─────────────────────────────────────────────────────────────┤${NC}"
    echo -e "${WHITE}  │                                                             │${NC}"
    echo -e "${GREEN}  │   [1]  Quick Scan (Linux/Solaris)                           │${NC}"
    echo -e "${GREEN}  │   [2]  Scan with Custom Settings                            │${NC}"
    echo -e "${WHITE}  │                                                             │${NC}"
    echo -e "${CYAN}  │   [3]  Configure Settings                                   │${NC}"
    echo -e "${CYAN}  │   [4]  View Current Settings                                │${NC}"
    echo -e "${CYAN}  │   [5]  Test Connection to Single Host                       │${NC}"
    echo -e "${WHITE}  │                                                             │${NC}"
    echo -e "${YELLOW}  │   [6]  Help / Instructions                                  │${NC}"
    echo -e "${YELLOW}  │   [7]  About                                                │${NC}"
    echo -e "${WHITE}  │                                                             │${NC}"
    echo -e "${RED}  │   [0]  Exit                                                 │${NC}"
    echo -e "${WHITE}  │                                                             │${NC}"
    echo -e "${WHITE}  └─────────────────────────────────────────────────────────────┘${NC}"
    echo ""
    read -p "  Enter your choice: " choice
    echo "$choice"
}

show_settings_menu() {
    show_banner
    
    # Format current values for display
    local subnet_display="${SUBNET:-Not Set}"
    local user_display="${USERNAME:-Not Set}"
    local pass_display="Not Set"
    [[ -n "$PASSWORD" ]] && pass_display="********"
    
    echo -e "${WHITE}  ┌─────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${WHITE}  │                   SETTINGS                                  │${NC}"
    echo -e "${WHITE}  ├─────────────────────────────────────────────────────────────┤${NC}"
    echo -e "${WHITE}  │                                                             │${NC}"
    echo -e "${WHITE}  │   [1]  Set Subnet        (Current: $(printf "%-20s" "$subnet_display"))│${NC}"
    echo -e "${WHITE}  │   [2]  Set Username      (Current: $(printf "%-20s" "$user_display"))│${NC}"
    echo -e "${WHITE}  │   [3]  Set Password      (Current: $(printf "%-20s" "$pass_display"))│${NC}"
    echo -e "${WHITE}  │   [4]  Set Output File                                      │${NC}"
    echo -e "${WHITE}  │   [5]  Set Timeout       (Current: ${TIMEOUT}s)                        │${NC}"
    echo -e "${WHITE}  │                                                             │${NC}"
    echo -e "${YELLOW}  │   [0]  Back to Main Menu                                    │${NC}"
    echo -e "${WHITE}  │                                                             │${NC}"
    echo -e "${WHITE}  └─────────────────────────────────────────────────────────────┘${NC}"
    echo ""
    read -p "  Enter your choice: " choice
    echo "$choice"
}

show_help() {
    show_banner
    echo -e "${WHITE}  ┌─────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${WHITE}  │                     HELP / INSTRUCTIONS                     │${NC}"
    echo -e "${WHITE}  └─────────────────────────────────────────────────────────────┘${NC}"
    echo ""
    echo -e "${CYAN}  QUICK START:${NC}"
    echo "  1. Select option [1] Quick Scan from main menu"
    echo "  2. Enter subnet when prompted (e.g., 192.168.1.0/24)"
    echo "  3. Enter username and password"
    echo "  4. Wait for scan to complete"
    echo "  5. CSV file will be saved automatically"
    echo ""
    echo -e "${CYAN}  SUPPORTED PLATFORMS:${NC}"
    echo "  - Linux (RHEL, CentOS, Fedora, Ubuntu, etc.)"
    echo "  - Solaris 10/11 SPARC"
    echo ""
    echo -e "${CYAN}  REQUIREMENTS:${NC}"
    echo "  - SSH access to target systems"
    echo "  - User account with sudo privileges"
    echo "  - sshpass (optional, for automated password input)"
    echo "    If sshpass not available, you'll enter password per host"
    echo ""
    echo -e "${CYAN}  NO DEPENDENCIES NEEDED:${NC}"
    echo "  This Bash version uses only built-in Linux/Solaris tools:"
    echo "  - bash, ssh, awk, grep, sed"
    echo ""
    echo -e "${CYAN}  GITHUB:${NC}"
    echo "  https://github.com/IICarrionII/Axis"
    echo ""
    read -p "  Press Enter to continue..."
}

show_about() {
    show_banner
    echo -e "${WHITE}  ┌─────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${WHITE}  │                        ABOUT                                │${NC}"
    echo -e "${WHITE}  └─────────────────────────────────────────────────────────────┘${NC}"
    echo ""
    echo -e "${CYAN}  AXIS - Asset eXploration & Inventory Scanner${NC}"
    echo -e "${WHITE}  Version: $VERSION (Bash Edition)${NC}"
    echo ""
    echo -e "${YELLOW}  Created by: Yan Carrion${NC}"
    echo -e "${YELLOW}  GitHub: https://github.com/IICarrionII/Axis${NC}"
    echo ""
    echo -e "${WHITE}  A cross-platform hardware and software inventory tool${NC}"
    echo -e "${WHITE}  designed for air-gapped enterprise networks.${NC}"
    echo ""
    echo -e "${CYAN}  Features:${NC}"
    echo "  - Zero dependencies - uses only built-in tools"
    echo "  - Runs on Linux and Solaris"
    echo "  - Scans Linux and Solaris SPARC targets"
    echo "  - Auto-accepts SSH host keys (air-gapped safe)"
    echo "  - Menu-driven interface"
    echo "  - Exports to CSV format"
    echo ""
    echo -e "${GRAY}  ─────────────────────────────────────────────────────────────${NC}"
    echo -e "${GRAY}  Licensed under MIT License${NC}"
    echo -e "${GRAY}  ─────────────────────────────────────────────────────────────${NC}"
    echo ""
    read -p "  Press Enter to continue..."
}

#===============================================================================
# UTILITY FUNCTIONS
#===============================================================================

# Check if sshpass is available
has_sshpass() {
    command -v sshpass &> /dev/null
}

# Generate IP range from CIDR
generate_ip_range() {
    local cidr="$1"
    local base_ip="${cidr%/*}"
    local prefix="${cidr#*/}"
    
    # Convert IP to integer
    local IFS='.'
    read -r i1 i2 i3 i4 <<< "$base_ip"
    local ip_int=$(( (i1 << 24) + (i2 << 16) + (i3 << 8) + i4 ))
    
    # Calculate network and broadcast
    local mask=$(( 0xFFFFFFFF << (32 - prefix) & 0xFFFFFFFF ))
    local network=$(( ip_int & mask ))
    local broadcast=$(( network | (~mask & 0xFFFFFFFF) ))
    
    # Generate IPs (skip network and broadcast)
    local ip_list=()
    for (( i = network + 1; i < broadcast; i++ )); do
        local o1=$(( (i >> 24) & 255 ))
        local o2=$(( (i >> 16) & 255 ))
        local o3=$(( (i >> 8) & 255 ))
        local o4=$(( i & 255 ))
        ip_list+=("$o1.$o2.$o3.$o4")
    done
    
    echo "${ip_list[@]}"
}

# Test if port is open (using /dev/tcp or nc)
test_port() {
    local ip="$1"
    local port="$2"
    local timeout="${3:-2}"
    
    # Try /dev/tcp first (bash built-in)
    if (echo >/dev/tcp/"$ip"/"$port") 2>/dev/null; then
        return 0
    fi
    
    # Fallback to nc if available
    if command -v nc &> /dev/null; then
        nc -z -w "$timeout" "$ip" "$port" &> /dev/null
        return $?
    fi
    
    # Fallback to timeout + bash
    timeout "$timeout" bash -c "echo >/dev/tcp/$ip/$port" 2>/dev/null
    return $?
}

# Execute SSH command
ssh_command() {
    local ip="$1"
    local user="$2"
    local pass="$3"
    local cmd="$4"
    local ssh_timeout="${5:-$TIMEOUT}"
    
    local ssh_opts="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=$ssh_timeout -o BatchMode=yes"
    
    if has_sshpass && [[ -n "$pass" ]]; then
        sshpass -p "$pass" ssh $ssh_opts "$user@$ip" "$cmd" 2>/dev/null
    else
        # Without sshpass, try key-based auth
        ssh $ssh_opts "$user@$ip" "$cmd" 2>/dev/null
    fi
}

# Detect remote OS type
detect_remote_os() {
    local ip="$1"
    local user="$2"
    local pass="$3"
    
    local uname_result
    uname_result=$(ssh_command "$ip" "$user" "$pass" "uname -s" 5)
    
    case "$uname_result" in
        *SunOS*) echo "Solaris" ;;
        *Linux*) echo "Linux" ;;
        *) echo "Unknown" ;;
    esac
}

#===============================================================================
# DATA COLLECTION FUNCTIONS
#===============================================================================

# Collect Linux system info
collect_linux_info() {
    local ip="$1"
    local user="$2"
    local pass="$3"
    
    local cmd='
hostname 2>/dev/null || echo "Unknown"
echo "---MARKER---"
systemd-detect-virt 2>/dev/null | grep -qv none && echo "Yes" || echo "No"
echo "---MARKER---"
sudo dmidecode -s system-manufacturer 2>/dev/null || echo "Unknown"
echo "---MARKER---"
sudo dmidecode -s system-product-name 2>/dev/null || echo "Unknown"
echo "---MARKER---"
sudo dmidecode -s system-serial-number 2>/dev/null || echo "Unknown"
echo "---MARKER---"
source /etc/os-release 2>/dev/null && echo "$PRETTY_NAME" || uname -sr
echo "---MARKER---"
uname -r
echo "---MARKER---"
free -h 2>/dev/null | awk "/^Mem:/ {print \$2}" || echo "Unknown"
echo "---MARKER---"
sudo dmidecode -t memory 2>/dev/null | grep "Type:" | grep -v "Error" | head -1 | awk "{print \$2}" || echo "Unknown"
echo "---MARKER---"
sudo dmidecode -s bios-version 2>/dev/null || echo "Unknown"
'
    
    local output
    output=$(ssh_command "$ip" "$user" "$pass" "$cmd" "$TIMEOUT")
    
    if [[ -z "$output" ]]; then
        echo "FAILED:Connection failed"
        return 1
    fi
    
    # Parse output
    IFS='---MARKER---' read -ra fields <<< "$output"
    
    local hostname=$(echo "${fields[0]}" | tr -d '\n' | xargs)
    local virtual=$(echo "${fields[1]}" | tr -d '\n' | xargs)
    local manufacturer=$(echo "${fields[2]}" | tr -d '\n' | xargs)
    local model=$(echo "${fields[3]}" | tr -d '\n' | xargs)
    local serial=$(echo "${fields[4]}" | tr -d '\n' | xargs)
    local os=$(echo "${fields[5]}" | tr -d '\n' | xargs)
    local kernel=$(echo "${fields[6]}" | tr -d '\n' | xargs)
    local memory=$(echo "${fields[7]}" | tr -d '\n' | xargs)
    local memtype=$(echo "${fields[8]}" | tr -d '\n' | xargs)
    local firmware=$(echo "${fields[9]}" | tr -d '\n' | xargs)
    
    # Clean up empty values
    [[ -z "$hostname" ]] && hostname="Unknown"
    [[ -z "$virtual" ]] && virtual="Unknown"
    [[ -z "$manufacturer" ]] && manufacturer="Unknown"
    [[ -z "$model" ]] && model="Unknown"
    [[ -z "$serial" ]] && serial="Unknown"
    [[ -z "$os" ]] && os="Unknown"
    [[ -z "$kernel" ]] && kernel="Unknown"
    [[ -z "$memory" ]] && memory="Unknown"
    [[ -z "$memtype" ]] && memtype="Unknown"
    [[ -z "$firmware" ]] && firmware="Unknown"
    
    echo "$hostname|$virtual|$manufacturer|$model|$serial|$os|$kernel|$memory|$memtype|$firmware|Linux|Success"
}

# Collect Solaris system info
collect_solaris_info() {
    local ip="$1"
    local user="$2"
    local pass="$3"
    
    local cmd='
hostname 2>/dev/null || echo "Unknown"
echo "---MARKER---"
/usr/sbin/virtinfo 2>/dev/null | grep -q "virtual" && echo "Yes" || echo "No"
echo "---MARKER---"
sudo /usr/sbin/prtconf -pv 2>/dev/null | grep "banner-name" | head -1 | cut -d"'"'"'" -f2 || echo "Unknown"
echo "---MARKER---"
sudo /usr/sbin/prtdiag 2>/dev/null | head -1 | sed "s/System Configuration: //" || /usr/sbin/prtconf -b 2>/dev/null | head -1 || echo "Unknown"
echo "---MARKER---"
sudo /usr/sbin/sneep 2>/dev/null || /usr/bin/hostid 2>/dev/null || echo "Unknown"
echo "---MARKER---"
echo "SunOS $(uname -r) $(cat /etc/release 2>/dev/null | head -1 | xargs)"
echo "---MARKER---"
uname -v
echo "---MARKER---"
sudo /usr/sbin/prtconf 2>/dev/null | grep "Memory size" | awk "{print \$3, \$4}" || echo "Unknown"
echo "---MARKER---"
echo "Unknown"
echo "---MARKER---"
sudo /usr/sbin/prtdiag -v 2>/dev/null | grep "OBP" | head -1 | awk "{print \$2}" || echo "Unknown"
'
    
    local output
    output=$(ssh_command "$ip" "$user" "$pass" "$cmd" "$TIMEOUT")
    
    if [[ -z "$output" ]]; then
        echo "FAILED:Connection failed"
        return 1
    fi
    
    # Parse output (same as Linux)
    IFS='---MARKER---' read -ra fields <<< "$output"
    
    local hostname=$(echo "${fields[0]}" | tr -d '\n' | xargs)
    local virtual=$(echo "${fields[1]}" | tr -d '\n' | xargs)
    local manufacturer=$(echo "${fields[2]}" | tr -d '\n' | xargs)
    local model=$(echo "${fields[3]}" | tr -d '\n' | xargs)
    local serial=$(echo "${fields[4]}" | tr -d '\n' | xargs)
    local os=$(echo "${fields[5]}" | tr -d '\n' | xargs)
    local kernel=$(echo "${fields[6]}" | tr -d '\n' | xargs)
    local memory=$(echo "${fields[7]}" | tr -d '\n' | xargs)
    local memtype=$(echo "${fields[8]}" | tr -d '\n' | xargs)
    local firmware=$(echo "${fields[9]}" | tr -d '\n' | xargs)
    
    # Clean up empty values
    [[ -z "$hostname" ]] && hostname="Unknown"
    [[ -z "$virtual" ]] && virtual="Unknown"
    [[ -z "$manufacturer" ]] && manufacturer="Unknown"
    [[ -z "$model" ]] && model="Unknown"
    [[ -z "$serial" ]] && serial="Unknown"
    [[ -z "$os" ]] && os="Unknown"
    [[ -z "$kernel" ]] && kernel="Unknown"
    [[ -z "$memory" ]] && memory="Unknown"
    [[ -z "$memtype" ]] && memtype="Unknown"
    [[ -z "$firmware" ]] && firmware="Unknown"
    
    echo "$hostname|$virtual|$manufacturer|$model|$serial|$os|$kernel|$memory|$memtype|$firmware|Solaris|Success"
}

#===============================================================================
# SCANNING FUNCTIONS
#===============================================================================

get_required_settings() {
    if [[ -z "$SUBNET" ]]; then
        echo ""
        echo -e "${YELLOW}  Subnet is required.${NC}"
        read -p "  Enter subnet (e.g., 192.168.1.0/24): " SUBNET
    fi
    
    if [[ -z "$USERNAME" ]]; then
        echo ""
        echo -e "${YELLOW}  Username is required.${NC}"
        read -p "  Enter username: " USERNAME
    fi
    
    if [[ -z "$PASSWORD" ]]; then
        echo ""
        echo -e "${YELLOW}  Password is required.${NC}"
        read -sp "  Enter password: " PASSWORD
        echo ""
    fi
    
    if [[ -z "$OUTPUT_FILE" ]]; then
        OUTPUT_FILE="./AXIS_Inventory_$(date +%Y%m%d_%H%M%S).csv"
    fi
    
    # Validate
    if [[ -z "$SUBNET" || -z "$USERNAME" ]]; then
        return 1
    fi
    return 0
}

test_single_host() {
    show_banner
    echo -e "${WHITE}  ┌─────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${WHITE}  │              TEST CONNECTION TO SINGLE HOST                 │${NC}"
    echo -e "${WHITE}  └─────────────────────────────────────────────────────────────┘${NC}"
    echo ""
    
    read -p "  Enter IP address to test: " test_ip
    
    [[ -z "$USERNAME" ]] && read -p "  Enter username: " USERNAME
    [[ -z "$PASSWORD" ]] && read -sp "  Enter password: " PASSWORD && echo ""
    
    echo ""
    echo -e "  Testing connection to ${CYAN}$test_ip${NC}..."
    echo ""
    
    # Test SSH port
    echo -n "  [1/3] Checking SSH port (22)..."
    if test_port "$test_ip" 22 2; then
        echo -e " ${GREEN}OPEN${NC}"
        local ssh_open=true
    else
        echo -e " ${RED}CLOSED${NC}"
        local ssh_open=false
    fi
    
    # Test authentication
    echo -n "  [2/3] Testing authentication..."
    if [[ "$ssh_open" == "true" ]]; then
        local test_result
        test_result=$(ssh_command "$test_ip" "$USERNAME" "$PASSWORD" "echo CONNECTION_SUCCESS && hostname" 15)
        
        if [[ "$test_result" == *"CONNECTION_SUCCESS"* ]]; then
            echo -e " ${GREEN}SUCCESS${NC}"
            echo ""
            echo -e "  ${CYAN}Hostname:${NC} $(echo "$test_result" | tail -1)"
        else
            echo -e " ${RED}FAILED${NC}"
            if ! has_sshpass; then
                echo ""
                echo -e "  ${YELLOW}Note: sshpass not installed. Using key-based auth only.${NC}"
                echo -e "  ${YELLOW}Password auth requires sshpass or SSH keys.${NC}"
            fi
        fi
    else
        echo -e " ${YELLOW}SKIPPED (port closed)${NC}"
    fi
    
    # Detect OS
    echo -n "  [3/3] Detecting OS type..."
    if [[ "$ssh_open" == "true" ]]; then
        local os_type
        os_type=$(detect_remote_os "$test_ip" "$USERNAME" "$PASSWORD")
        echo -e " ${GREEN}$os_type${NC}"
    else
        echo -e " ${YELLOW}SKIPPED${NC}"
    fi
    
    echo ""
    read -p "  Press Enter to continue..."
}

view_current_settings() {
    show_banner
    echo -e "${WHITE}  ┌─────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${WHITE}  │                 CURRENT SETTINGS                            │${NC}"
    echo -e "${WHITE}  ├─────────────────────────────────────────────────────────────┤${NC}"
    echo -e "${WHITE}  │                                                             │${NC}"
    printf "${WHITE}  │  Subnet:        %-43s│${NC}\n" "${SUBNET:-Not Set}"
    printf "${WHITE}  │  Username:      %-43s│${NC}\n" "${USERNAME:-Not Set}"
    printf "${WHITE}  │  Password:      %-43s│${NC}\n" "$(if [[ -n "$PASSWORD" ]]; then echo "********"; else echo "Not Set"; fi)"
    printf "${WHITE}  │  Output File:   %-43s│${NC}\n" "${OUTPUT_FILE:-Auto-generate}"
    printf "${WHITE}  │  Timeout:       %-43s│${NC}\n" "${TIMEOUT} seconds"
    echo -e "${WHITE}  │                                                             │${NC}"
    
    # Show tool availability
    local ssh_tool="ssh (native)"
    local sshpass_status="Not Available"
    has_sshpass && sshpass_status="Available"
    
    printf "${WHITE}  │  SSH Tool:      %-43s│${NC}\n" "$ssh_tool"
    printf "${WHITE}  │  sshpass:       %-43s│${NC}\n" "$sshpass_status"
    echo -e "${WHITE}  │                                                             │${NC}"
    echo -e "${WHITE}  └─────────────────────────────────────────────────────────────┘${NC}"
    echo ""
    
    if ! has_sshpass; then
        echo -e "${YELLOW}  Note: sshpass not installed. Password authentication requires${NC}"
        echo -e "${YELLOW}  either sshpass or SSH key-based authentication.${NC}"
        echo ""
    fi
    
    read -p "  Press Enter to continue..."
}

start_scan() {
    show_banner
    echo -e "${WHITE}  ┌─────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${WHITE}  │                    STARTING SCAN                            │${NC}"
    echo -e "${WHITE}  └─────────────────────────────────────────────────────────────┘${NC}"
    echo ""
    
    # Get required settings
    if ! get_required_settings; then
        echo -e "${RED}  Missing required settings. Please configure first.${NC}"
        read -p "  Press Enter to continue..."
        return
    fi
    
    echo ""
    echo -e "  Subnet: ${WHITE}$SUBNET${NC}"
    echo -e "  Username: ${WHITE}$USERNAME${NC}"
    echo -e "  Output: ${WHITE}$OUTPUT_FILE${NC}"
    echo ""
    
    read -p "  Proceed with scan? (Y/N): " confirm
    if [[ "$confirm" != "Y" && "$confirm" != "y" ]]; then
        return
    fi
    
    echo ""
    echo -e "  ${YELLOW}Generating IP list...${NC}"
    
    # Generate IP list
    local ip_array
    read -ra ip_array <<< "$(generate_ip_range "$SUBNET")"
    local total_ips=${#ip_array[@]}
    
    echo -e "  Total IPs: ${GREEN}$total_ips${NC}"
    
    # Phase 1: Discover SSH hosts
    echo ""
    echo -e "  ${CYAN}Phase 1: Discovering SSH hosts...${NC}"
    
    local ssh_hosts=()
    local count=0
    
    for ip in "${ip_array[@]}"; do
        ((count++))
        printf "\r  Scanning: %d/%d (%.0f%%)" "$count" "$total_ips" "$(echo "scale=0; $count * 100 / $total_ips" | bc 2>/dev/null || echo 0)"
        
        if test_port "$ip" 22 1; then
            ssh_hosts+=("$ip")
        fi
    done
    
    echo ""
    echo -e "  SSH hosts found: ${GREEN}${#ssh_hosts[@]}${NC}"
    
    if [[ ${#ssh_hosts[@]} -eq 0 ]]; then
        echo ""
        echo -e "${YELLOW}  No SSH hosts found!${NC}"
        read -p "  Press Enter to continue..."
        return
    fi
    
    # Phase 2: Collect information
    echo ""
    echo -e "  ${CYAN}Phase 2: Collecting system information...${NC}"
    
    local total_hosts=${#ssh_hosts[@]}
    local est_time=$((total_hosts / 2))
    echo -e "  ${GRAY}Estimated time: $est_time - $((est_time * 2)) minutes${NC}"
    echo ""
    
    # Create CSV header
    echo '"Component Type","Hostname","IP Address","Virtual Asset","Manufacturer","Model Number","Serial Number","OS/IOS","FW Version","Memory Size","Memory Type","Kernel Version","OS Type","Scan Status"' > "$OUTPUT_FILE"
    
    local success_count=0
    local fail_count=0
    count=0
    
    for ip in "${ssh_hosts[@]}"; do
        ((count++))
        printf "  [%d/%d] %s" "$count" "$total_hosts" "$ip"
        
        # Detect OS
        local os_type
        os_type=$(detect_remote_os "$ip" "$USERNAME" "$PASSWORD")
        printf " [%s]" "$os_type"
        
        # Collect info based on OS
        local result
        case "$os_type" in
            "Linux")
                result=$(collect_linux_info "$ip" "$USERNAME" "$PASSWORD")
                ;;
            "Solaris")
                result=$(collect_solaris_info "$ip" "$USERNAME" "$PASSWORD")
                ;;
            *)
                result=$(collect_linux_info "$ip" "$USERNAME" "$PASSWORD")
                os_type="Unknown-SSH"
                ;;
        esac
        
        # Parse result
        if [[ "$result" == FAILED:* ]]; then
            local error="${result#FAILED:}"
            echo -e " ${RED}✗${NC}"
            echo "\"Server\",\"Unknown\",\"$ip\",\"Unknown\",\"Unknown\",\"Unknown\",\"Unknown\",\"Unknown\",\"Unknown\",\"Unknown\",\"Unknown\",\"Unknown\",\"$os_type\",\"Failed: $error\"" >> "$OUTPUT_FILE"
            ((fail_count++))
        else
            IFS='|' read -ra info <<< "$result"
            local hostname="${info[0]}"
            echo -e " ${GREEN}✓ $hostname${NC}"
            echo "\"Server\",\"${info[0]}\",\"$ip\",\"${info[1]}\",\"${info[2]}\",\"${info[3]}\",\"${info[4]}\",\"${info[5]}\",\"${info[9]}\",\"${info[7]}\",\"${info[8]}\",\"${info[6]}\",\"${info[10]}\",\"${info[11]}\"" >> "$OUTPUT_FILE"
            ((success_count++))
        fi
    done
    
    # Show results
    echo ""
    echo -e "  ${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "                         ${CYAN}RESULTS${NC}"
    echo -e "  ${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "  ${GREEN}✓ Saved: $OUTPUT_FILE${NC}"
    echo ""
    echo -e "  Total scanned:  ${WHITE}$total_hosts${NC}"
    echo -e "  Successful:     ${GREEN}$success_count${NC}"
    echo -e "  Failed:         ${RED}$fail_count${NC}"
    echo ""
    
    read -p "  Press Enter to continue..."
}

#===============================================================================
# MAIN LOOP
#===============================================================================

main() {
    while true; do
        local choice
        choice=$(show_main_menu)
        
        case "$choice" in
            1)
                start_scan
                ;;
            2)
                start_scan
                ;;
            3)
                # Settings menu
                local settings_loop=true
                while $settings_loop; do
                    local settings_choice
                    settings_choice=$(show_settings_menu)
                    
                    case "$settings_choice" in
                        1) read -p "  Enter subnet (e.g., 192.168.1.0/24): " SUBNET ;;
                        2) read -p "  Enter username: " USERNAME ;;
                        3) read -sp "  Enter password: " PASSWORD; echo "" ;;
                        4) read -p "  Enter output file path: " OUTPUT_FILE ;;
                        5) read -p "  Enter timeout in seconds: " TIMEOUT ;;
                        0) settings_loop=false ;;
                        *) ;;
                    esac
                done
                ;;
            4)
                view_current_settings
                ;;
            5)
                test_single_host
                ;;
            6)
                show_help
                ;;
            7)
                show_about
                ;;
            0)
                show_banner
                echo -e "  ${CYAN}Thank you for using AXIS!${NC}"
                echo ""
                echo -e "  ${GRAY}GitHub: https://github.com/IICarrionII/Axis${NC}"
                echo ""
                echo -e "  ${YELLOW}Goodbye!${NC}"
                echo ""
                exit 0
                ;;
            *)
                ;;
        esac
    done
}

# Start the program
main
