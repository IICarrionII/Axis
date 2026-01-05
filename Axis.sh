#!/bin/bash
#===============================================================================
#
#    AXIS - Asset eXploration & Inventory Scanner
#    Cross-Platform Hardware & Software Inventory Tool
#    
#    Created by: Yan Carrion
#    GitHub: https://github.com/IICarrionII/Axis
#    
#    Bash Version - Self-Contained / No System Dependencies Required
#    
#    Run From: RHEL 6/7/8/9, CentOS, Solaris 10/11, macOS (for testing)
#    Scans:    Linux, Solaris SPARC
#
#===============================================================================

VERSION="1.0.0"

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Global variables
SUBNET=""
USERNAME=""
PASSWORD=""
OUTPUT_FILE=""
TIMEOUT=15

# Tool paths - check local folder first, then system
SSHPASS_CMD=""
EXPECT_CMD=""
SSH_CMD=""

#===============================================================================
# TOOL DETECTION - Check local ./tools folder first, then system PATH
#===============================================================================

init_tools() {
    # Check for sshpass
    if [[ -x "$SCRIPT_DIR/tools/sshpass" ]]; then
        SSHPASS_CMD="$SCRIPT_DIR/tools/sshpass"
    elif [[ -x "$SCRIPT_DIR/sshpass" ]]; then
        SSHPASS_CMD="$SCRIPT_DIR/sshpass"
    elif command -v sshpass &> /dev/null; then
        SSHPASS_CMD="$(command -v sshpass)"
    fi
    
    # Check for expect
    if [[ -x "$SCRIPT_DIR/tools/expect" ]]; then
        EXPECT_CMD="$SCRIPT_DIR/tools/expect"
    elif [[ -x "$SCRIPT_DIR/expect" ]]; then
        EXPECT_CMD="$SCRIPT_DIR/expect"
    elif command -v expect &> /dev/null; then
        EXPECT_CMD="$(command -v expect)"
    fi
    
    # Check for ssh
    if command -v ssh &> /dev/null; then
        SSH_CMD="$(command -v ssh)"
    fi
}

has_sshpass() {
    [[ -n "$SSHPASS_CMD" && -x "$SSHPASS_CMD" ]]
}

has_expect() {
    [[ -n "$EXPECT_CMD" && -x "$EXPECT_CMD" ]]
}

has_ssh() {
    [[ -n "$SSH_CMD" && -x "$SSH_CMD" ]]
}

# Detect OS we're running on
detect_local_os() {
    local uname_out
    uname_out="$(uname -s)"
    
    case "$uname_out" in
        Linux*)   echo "Linux" ;;
        Darwin*)  echo "macOS" ;;
        SunOS*)   echo "Solaris" ;;
        *)        echo "Unknown ($uname_out)" ;;
    esac
}

LOCAL_OS=$(detect_local_os)

#===============================================================================
# BANNER AND MENUS
#===============================================================================

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
    echo "  ║   Cross-Platform Hardware & Software Inventory Tool       ║"
    echo "  ╠═══════════════════════════════════════════════════════════╣"
    echo "  ║   Supports: Linux (RHEL) | Solaris SPARC                  ║"
    echo "  ║   Air-Gapped Network Ready - Self-Contained               ║"
    echo "  ╠═══════════════════════════════════════════════════════════╣"
    echo "  ║   Created by: Yan Carrion                                 ║"
    echo "  ║   GitHub: github.com/IICarrionII/Axis                     ║"
    echo "  ╚═══════════════════════════════════════════════════════════╝"
    echo ""
    echo "  Running on: $LOCAL_OS | Version: $VERSION | Bash Edition"
    echo ""
}

show_main_menu() {
    show_banner
    echo "  ┌─────────────────────────────────────────────────────────────┐"
    echo "  │                      MAIN MENU                              │"
    echo "  ├─────────────────────────────────────────────────────────────┤"
    echo "  │                                                             │"
    echo "  │   [1]  Quick Scan (Linux/Solaris)                           │"
    echo "  │   [2]  Scan with Custom Settings                            │"
    echo "  │                                                             │"
    echo "  │   [3]  Configure Settings                                   │"
    echo "  │   [4]  View Current Settings                                │"
    echo "  │   [5]  Test Connection to Single Host                       │"
    echo "  │                                                             │"
    echo "  │   [6]  Help / Instructions                                  │"
    echo "  │   [7]  About                                                │"
    echo "  │                                                             │"
    echo "  │   [0]  Exit                                                 │"
    echo "  │                                                             │"
    echo "  └─────────────────────────────────────────────────────────────┘"
    echo ""
}

show_settings_menu() {
    show_banner
    
    # Format current values for display
    local subnet_display="${SUBNET:-Not Set}"
    local user_display="${USERNAME:-Not Set}"
    local pass_display="Not Set"
    [[ -n "$PASSWORD" ]] && pass_display="********"
    
    echo "  ┌─────────────────────────────────────────────────────────────┐"
    echo "  │                      SETTINGS                               │"
    echo "  ├─────────────────────────────────────────────────────────────┤"
    echo "  │                                                             │"
    printf "  │   [1]  Set Subnet        (Current: %-20s) │\n" "$subnet_display"
    printf "  │   [2]  Set Username      (Current: %-20s) │\n" "$user_display"
    printf "  │   [3]  Set Password      (Current: %-20s) │\n" "$pass_display"
    echo "  │   [4]  Set Output File                                      │"
    printf "  │   [5]  Set Timeout       (Current: %-3s seconds)            │\n" "$TIMEOUT"
    echo "  │                                                             │"
    echo "  │   [0]  Back to Main Menu                                    │"
    echo "  │                                                             │"
    echo "  └─────────────────────────────────────────────────────────────┘"
    echo ""
}

show_help() {
    show_banner
    echo "  ┌─────────────────────────────────────────────────────────────┐"
    echo "  │                  HELP / INSTRUCTIONS                        │"
    echo "  └─────────────────────────────────────────────────────────────┘"
    echo ""
    echo "  QUICK START:"
    echo "  ─────────────"
    echo "  1. Select option [1] Quick Scan from main menu"
    echo "  2. Enter subnet when prompted (e.g., 192.168.1.0/24)"
    echo "  3. Enter username and password"
    echo "  4. Wait for scan to complete"
    echo "  5. CSV file will be saved automatically"
    echo ""
    echo "  SUPPORTED PLATFORMS:"
    echo "  ─────────────────────"
    echo "  - Linux (RHEL, CentOS, Fedora, Ubuntu, etc.)"
    echo "  - Solaris 10/11 SPARC"
    echo ""
    echo "  SELF-CONTAINED MODE:"
    echo "  ─────────────────────"
    echo "  Place these files in ./tools/ folder for air-gapped use:"
    echo "  - sshpass (for password authentication)"
    echo "  - expect  (alternative for password auth)"
    echo ""
    echo "  REQUIREMENTS:"
    echo "  ──────────────"
    echo "  - SSH access to target systems"
    echo "  - User account with sudo privileges (for hardware info)"
    echo ""
    echo "  GITHUB: https://github.com/IICarrionII/Axis"
    echo ""
    read -p "  Press Enter to continue..."
}

show_about() {
    show_banner
    echo "  ┌─────────────────────────────────────────────────────────────┐"
    echo "  │                         ABOUT                               │"
    echo "  └─────────────────────────────────────────────────────────────┘"
    echo ""
    echo "  AXIS - Asset eXploration & Inventory Scanner"
    echo "  Version: $VERSION (Bash Edition)"
    echo ""
    echo "  Created by: Yan Carrion"
    echo "  GitHub: https://github.com/IICarrionII/Axis"
    echo ""
    echo "  A cross-platform hardware and software inventory tool"
    echo "  designed for air-gapped enterprise networks."
    echo ""
    echo "  FEATURES:"
    echo "  ──────────"
    echo "  - Self-contained - bundle tools in ./tools/ folder"
    echo "  - Runs on Linux, Solaris, and macOS"
    echo "  - Scans Linux and Solaris SPARC targets"
    echo "  - Auto-accepts SSH host keys (air-gapped safe)"
    echo "  - Menu-driven interface"
    echo "  - Exports to CSV format"
    echo ""
    echo "  ─────────────────────────────────────────────────────────────"
    echo "  Licensed under MIT License"
    echo "  ─────────────────────────────────────────────────────────────"
    echo ""
    read -p "  Press Enter to continue..."
}

#===============================================================================
# UTILITY FUNCTIONS
#===============================================================================

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

# Test if port is open
test_port() {
    local ip="$1"
    local port="$2"
    local timeout_val="${3:-2}"
    
    # Try nc first (most reliable cross-platform)
    if command -v nc &> /dev/null; then
        nc -z -w "$timeout_val" "$ip" "$port" &> /dev/null
        return $?
    fi
    
    # Try timeout + bash /dev/tcp
    if command -v timeout &> /dev/null; then
        timeout "$timeout_val" bash -c "echo >/dev/tcp/$ip/$port" 2>/dev/null
        return $?
    fi
    
    # macOS - use native bash with background process
    (echo >/dev/tcp/"$ip"/"$port") &>/dev/null &
    local pid=$!
    
    # Wait for connection or timeout
    local count=0
    while kill -0 "$pid" 2>/dev/null && (( count < timeout_val * 10 )); do
        sleep 0.1
        ((count++))
    done
    
    if kill -0 "$pid" 2>/dev/null; then
        kill "$pid" 2>/dev/null
        wait "$pid" 2>/dev/null
        return 1
    fi
    
    wait "$pid" 2>/dev/null
    return $?
}

# Execute SSH command with expect
ssh_with_expect() {
    local ip="$1"
    local user="$2"
    local pass="$3"
    local cmd="$4"
    local ssh_timeout="${5:-$TIMEOUT}"
    
    "$EXPECT_CMD" -c "
        log_user 0
        set timeout $ssh_timeout
        spawn $SSH_CMD -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=$ssh_timeout $user@$ip \"$cmd\"
        expect {
            -re \".*assword.*\" {
                send \"$pass\r\"
                log_user 1
                expect {
                    -re \".*assword.*\" { exit 1 }
                    eof { catch wait result; exit [lindex \$result 3] }
                }
            }
            eof { catch wait result; exit [lindex \$result 3] }
            timeout { exit 1 }
        }
    " 2>/dev/null
}

# Execute SSH command
ssh_command() {
    local ip="$1"
    local user="$2"
    local pass="$3"
    local cmd="$4"
    local ssh_timeout="${5:-$TIMEOUT}"
    
    local ssh_opts="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=$ssh_timeout"
    
    # Try sshpass first (best option)
    if has_sshpass && [[ -n "$pass" ]]; then
        "$SSHPASS_CMD" -p "$pass" "$SSH_CMD" $ssh_opts "$user@$ip" "$cmd" 2>/dev/null
        return $?
    fi
    
    # Try expect second
    if has_expect && [[ -n "$pass" ]]; then
        ssh_with_expect "$ip" "$user" "$pass" "$cmd" "$ssh_timeout"
        return $?
    fi
    
    # Last resort - key-based auth only
    "$SSH_CMD" $ssh_opts -o BatchMode=yes "$user@$ip" "$cmd" 2>/dev/null
}

# Detect remote OS type
detect_remote_os() {
    local ip="$1"
    local user="$2"
    local pass="$3"
    
    local uname_result
    uname_result=$(ssh_command "$ip" "$user" "$pass" "uname -s" 10)
    
    case "$uname_result" in
        *SunOS*) echo "Solaris" ;;
        *Linux*) echo "Linux" ;;
        *Darwin*) echo "macOS" ;;
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
HOSTNAME=$(hostname 2>/dev/null || echo "Unknown")
VIRTUAL=$(systemd-detect-virt 2>/dev/null | grep -qv none && echo "Yes" || echo "No")
MANUFACTURER=$(sudo dmidecode -s system-manufacturer 2>/dev/null || echo "Unknown")
MODEL=$(sudo dmidecode -s system-product-name 2>/dev/null || echo "Unknown")
SERIAL=$(sudo dmidecode -s system-serial-number 2>/dev/null || echo "Unknown")
if [[ -f /etc/os-release ]]; then
    source /etc/os-release 2>/dev/null
    OS="$PRETTY_NAME"
else
    OS=$(uname -sr)
fi
KERNEL=$(uname -r)
MEMORY=$(free -h 2>/dev/null | awk "/^Mem:/ {print \$2}" || echo "Unknown")
MEMTYPE=$(sudo dmidecode -t memory 2>/dev/null | grep "Type:" | grep -v "Error" | grep -v "Unknown" | head -1 | awk "{print \$2}" || echo "Unknown")
FIRMWARE=$(sudo dmidecode -s bios-version 2>/dev/null || echo "Unknown")
echo "${HOSTNAME}|${VIRTUAL}|${MANUFACTURER}|${MODEL}|${SERIAL}|${OS}|${KERNEL}|${MEMORY}|${MEMTYPE}|${FIRMWARE}"
'
    
    local output
    output=$(ssh_command "$ip" "$user" "$pass" "$cmd" "$TIMEOUT")
    
    if [[ -z "$output" || "$output" == *"Permission denied"* || "$output" == *"Connection refused"* ]]; then
        echo "Unknown|Unknown|Unknown|Unknown|Unknown|Unknown|Unknown|Unknown|Unknown|Unknown|Linux|Failed: Connection failed"
        return 1
    fi
    
    # Clean output - remove any warning lines
    output=$(echo "$output" | grep '|' | tail -1)
    
    if [[ -z "$output" ]]; then
        echo "Unknown|Unknown|Unknown|Unknown|Unknown|Unknown|Unknown|Unknown|Unknown|Unknown|Linux|Failed: No data returned"
        return 1
    fi
    
    echo "$output|Linux|Success"
}

# Collect Solaris system info
collect_solaris_info() {
    local ip="$1"
    local user="$2"
    local pass="$3"
    
    local cmd='
HOSTNAME=$(hostname 2>/dev/null || echo "Unknown")
VIRTUAL=$(/usr/sbin/virtinfo 2>/dev/null | grep -q "virtual" && echo "Yes" || echo "No")
MANUFACTURER=$(sudo /usr/sbin/prtconf -pv 2>/dev/null | grep "banner-name" | head -1 | cut -d"'"'"'" -f2 || echo "Unknown")
MODEL=$(sudo /usr/sbin/prtdiag 2>/dev/null | head -1 | sed "s/System Configuration: //" || echo "Unknown")
SERIAL=$(sudo /usr/sbin/sneep 2>/dev/null || /usr/bin/hostid 2>/dev/null || echo "Unknown")
OS="SunOS $(uname -r) $(cat /etc/release 2>/dev/null | head -1 | xargs)"
KERNEL=$(uname -v)
MEMORY=$(sudo /usr/sbin/prtconf 2>/dev/null | grep "Memory size" | awk "{print \$3, \$4}" || echo "Unknown")
MEMTYPE="Unknown"
FIRMWARE=$(sudo /usr/sbin/prtdiag -v 2>/dev/null | grep "OBP" | head -1 | awk "{print \$2}" || echo "Unknown")
echo "${HOSTNAME}|${VIRTUAL}|${MANUFACTURER}|${MODEL}|${SERIAL}|${OS}|${KERNEL}|${MEMORY}|${MEMTYPE}|${FIRMWARE}"
'
    
    local output
    output=$(ssh_command "$ip" "$user" "$pass" "$cmd" "$TIMEOUT")
    
    if [[ -z "$output" ]]; then
        echo "Unknown|Unknown|Unknown|Unknown|Unknown|Unknown|Unknown|Unknown|Unknown|Unknown|Solaris|Failed: Connection failed"
        return 1
    fi
    
    # Clean output
    output=$(echo "$output" | grep '|' | tail -1)
    
    echo "$output|Solaris|Success"
}

# Collect macOS system info (for testing)
collect_macos_info() {
    local ip="$1"
    local user="$2"
    local pass="$3"
    
    local cmd='
HOSTNAME=$(hostname 2>/dev/null || echo "Unknown")
VIRTUAL=$(system_profiler SPHardwareDataType 2>/dev/null | grep -q "Virtual" && echo "Yes" || echo "No")
MANUFACTURER="Apple Inc."
MODEL=$(system_profiler SPHardwareDataType 2>/dev/null | grep "Model Name" | cut -d":" -f2 | xargs || echo "Unknown")
SERIAL=$(system_profiler SPHardwareDataType 2>/dev/null | grep "Serial Number" | cut -d":" -f2 | xargs || echo "Unknown")
OS=$(sw_vers -productName 2>/dev/null) 
OS="$OS $(sw_vers -productVersion 2>/dev/null)"
KERNEL=$(uname -r)
MEMORY=$(system_profiler SPHardwareDataType 2>/dev/null | grep "Memory:" | cut -d":" -f2 | xargs || echo "Unknown")
MEMTYPE="Unknown"
FIRMWARE=$(system_profiler SPHardwareDataType 2>/dev/null | grep "Boot ROM" | cut -d":" -f2 | xargs || echo "Unknown")
echo "${HOSTNAME}|${VIRTUAL}|${MANUFACTURER}|${MODEL}|${SERIAL}|${OS}|${KERNEL}|${MEMORY}|${MEMTYPE}|${FIRMWARE}"
'
    
    local output
    output=$(ssh_command "$ip" "$user" "$pass" "$cmd" "$TIMEOUT")
    
    if [[ -z "$output" ]]; then
        echo "Unknown|Unknown|Unknown|Unknown|Unknown|Unknown|Unknown|Unknown|Unknown|Unknown|macOS|Failed: Connection failed"
        return 1
    fi
    
    output=$(echo "$output" | grep '|' | tail -1)
    echo "$output|macOS|Success"
}

#===============================================================================
# SCANNING FUNCTIONS
#===============================================================================

get_required_settings() {
    if [[ -z "$SUBNET" ]]; then
        echo ""
        echo "  Subnet is required."
        read -p "  Enter subnet (e.g., 192.168.1.0/24): " SUBNET
    fi
    
    if [[ -z "$USERNAME" ]]; then
        echo ""
        echo "  Username is required."
        read -p "  Enter username: " USERNAME
    fi
    
    if [[ -z "$PASSWORD" ]]; then
        echo ""
        echo "  Password is required."
        read -s -p "  Enter password: " PASSWORD
        echo ""
    fi
    
    if [[ -z "$OUTPUT_FILE" ]]; then
        OUTPUT_FILE="$SCRIPT_DIR/AXIS_Inventory_$(date +%Y%m%d_%H%M%S).csv"
    fi
    
    # Validate
    if [[ -z "$SUBNET" || -z "$USERNAME" ]]; then
        return 1
    fi
    return 0
}

test_single_host() {
    show_banner
    echo "  ┌─────────────────────────────────────────────────────────────┐"
    echo "  │              TEST CONNECTION TO SINGLE HOST                 │"
    echo "  └─────────────────────────────────────────────────────────────┘"
    echo ""
    
    read -p "  Enter IP address to test: " test_ip
    
    # Always ask for username if not set
    if [[ -z "$USERNAME" ]]; then
        read -p "  Enter username: " USERNAME
    else
        echo "  Using username: $USERNAME"
    fi
    
    # Always ask for password if not set
    if [[ -z "$PASSWORD" ]]; then
        read -s -p "  Enter password: " PASSWORD
        echo ""
    else
        echo "  Using saved password: ********"
    fi
    
    echo ""
    
    # Show auth method being used
    echo "  Authentication method:"
    if has_sshpass; then
        echo "    -> sshpass: $SSHPASS_CMD"
    elif has_expect; then
        echo "    -> expect: $EXPECT_CMD"
    else
        echo "    -> SSH keys only (no password auth available)"
    fi
    echo ""
    
    echo "  Testing connection to $test_ip..."
    echo ""
    
    # Test SSH port
    echo -n "  [1/3] Checking SSH port (22)... "
    if test_port "$test_ip" 22 2; then
        echo "OPEN"
        local ssh_open=true
    else
        echo "CLOSED"
        local ssh_open=false
    fi
    
    # Test authentication
    echo -n "  [2/3] Testing authentication... "
    if [[ "$ssh_open" == "true" ]]; then
        local test_result
        test_result=$(ssh_command "$test_ip" "$USERNAME" "$PASSWORD" "echo CONNECTION_SUCCESS && hostname" 15)
        
        if [[ "$test_result" == *"CONNECTION_SUCCESS"* ]]; then
            echo "SUCCESS"
            echo ""
            echo "  Hostname: $(echo "$test_result" | grep -v CONNECTION_SUCCESS | tail -1)"
        else
            echo "FAILED"
            echo ""
            echo "  Possible causes:"
            echo "  - Wrong username or password"
            if ! has_sshpass && ! has_expect; then
                echo "  - No password auth tool (sshpass/expect) available"
            fi
            echo "  - SSH key not set up for this user"
            echo "  - User not allowed to SSH to this host"
        fi
    else
        echo "SKIPPED (port closed)"
    fi
    
    # Detect OS
    echo -n "  [3/3] Detecting OS type... "
    if [[ "$ssh_open" == "true" ]]; then
        local os_type
        os_type=$(detect_remote_os "$test_ip" "$USERNAME" "$PASSWORD")
        echo "$os_type"
    else
        echo "SKIPPED"
    fi
    
    echo ""
    read -p "  Press Enter to continue..."
}

view_current_settings() {
    show_banner
    
    local sshpass_status="Not Found"
    local expect_status="Not Found"
    local ssh_status="Not Found"
    local auth_method="None (SSH Keys Only)"
    
    if has_sshpass; then
        sshpass_status="$SSHPASS_CMD"
        auth_method="sshpass"
    fi
    
    if has_expect; then
        expect_status="$EXPECT_CMD"
        [[ "$auth_method" == "None (SSH Keys Only)" ]] && auth_method="expect"
    fi
    
    if has_ssh; then
        ssh_status="$SSH_CMD"
    fi
    
    echo "  ┌─────────────────────────────────────────────────────────────┐"
    echo "  │                  CURRENT SETTINGS                           │"
    echo "  ├─────────────────────────────────────────────────────────────┤"
    echo "  │                                                             │"
    printf "  │  Subnet:        %-43s│\n" "${SUBNET:-Not Set}"
    printf "  │  Username:      %-43s│\n" "${USERNAME:-Not Set}"
    printf "  │  Password:      %-43s│\n" "$(if [[ -n "$PASSWORD" ]]; then echo "********"; else echo "Not Set"; fi)"
    printf "  │  Output File:   %-43s│\n" "${OUTPUT_FILE:-Auto-generate}"
    printf "  │  Timeout:       %-43s│\n" "${TIMEOUT} seconds"
    echo "  │                                                             │"
    echo "  ├─────────────────────────────────────────────────────────────┤"
    echo "  │                  DETECTED TOOLS                             │"
    echo "  ├─────────────────────────────────────────────────────────────┤"
    echo "  │                                                             │"
    printf "  │  SSH:           %-43s│\n" "$ssh_status"
    printf "  │  sshpass:       %-43s│\n" "$sshpass_status"
    printf "  │  expect:        %-43s│\n" "$expect_status"
    echo "  │                                                             │"
    printf "  │  Auth Method:   %-43s│\n" "$auth_method"
    echo "  │                                                             │"
    echo "  └─────────────────────────────────────────────────────────────┘"
    echo ""
    
    if ! has_sshpass && ! has_expect; then
        echo "  WARNING: No password authentication tools found!"
        echo ""
        echo "  To enable password auth, either:"
        echo "  1. Install sshpass: sudo yum install sshpass"
        echo "  2. Copy sshpass binary to: $SCRIPT_DIR/tools/"
        echo "  3. Use SSH key-based authentication instead"
        echo ""
    fi
    
    read -p "  Press Enter to continue..."
}

start_scan() {
    show_banner
    echo "  ┌─────────────────────────────────────────────────────────────┐"
    echo "  │                     STARTING SCAN                           │"
    echo "  └─────────────────────────────────────────────────────────────┘"
    echo ""
    
    # Get required settings
    if ! get_required_settings; then
        echo "  Missing required settings. Please configure first."
        read -p "  Press Enter to continue..."
        return
    fi
    
    echo ""
    echo "  Subnet:   $SUBNET"
    echo "  Username: $USERNAME"
    echo "  Output:   $OUTPUT_FILE"
    echo ""
    
    # Show auth method
    if has_sshpass; then
        echo "  Auth:     sshpass (password)"
    elif has_expect; then
        echo "  Auth:     expect (password)"
    else
        echo "  Auth:     SSH keys only"
    fi
    echo ""
    
    read -p "  Proceed with scan? (Y/N): " confirm
    if [[ "$confirm" != "Y" && "$confirm" != "y" ]]; then
        return
    fi
    
    echo ""
    echo "  Generating IP list..."
    
    # Generate IP list
    local ip_array
    read -ra ip_array <<< "$(generate_ip_range "$SUBNET")"
    local total_ips=${#ip_array[@]}
    
    echo "  Total IPs: $total_ips"
    
    # Phase 1: Discover SSH hosts
    echo ""
    echo "  Phase 1: Discovering SSH hosts..."
    echo ""
    
    local ssh_hosts=()
    local count=0
    
    for ip in "${ip_array[@]}"; do
        ((count++))
        
        # Progress update every 10 IPs
        if (( count % 10 == 0 )) || (( count == total_ips )); then
            local pct=$((count * 100 / total_ips))
            printf "\r  Scanning: %d/%d (%d%%)   " "$count" "$total_ips" "$pct"
        fi
        
        if test_port "$ip" 22 1; then
            ssh_hosts+=("$ip")
        fi
    done
    
    echo ""
    echo ""
    echo "  SSH hosts found: ${#ssh_hosts[@]}"
    
    if [[ ${#ssh_hosts[@]} -eq 0 ]]; then
        echo ""
        echo "  No SSH hosts found!"
        read -p "  Press Enter to continue..."
        return
    fi
    
    # Phase 2: Collect information
    echo ""
    echo "  Phase 2: Collecting system information..."
    
    local total_hosts=${#ssh_hosts[@]}
    local est_time=$((total_hosts / 2))
    echo "  Estimated time: $est_time - $((est_time * 2)) minutes"
    echo ""
    
    # Create CSV header
    echo '"Component Type","Hostname","IP Address","Virtual Asset","Manufacturer","Model Number","Serial Number","OS/IOS","FW Version","Memory Size","Memory Type","Kernel Version","OS Type","Scan Status"' > "$OUTPUT_FILE"
    
    local success_count=0
    local fail_count=0
    count=0
    
    for ip in "${ssh_hosts[@]}"; do
        ((count++))
        echo -n "  [$count/$total_hosts] $ip"
        
        # Detect OS
        local os_type
        os_type=$(detect_remote_os "$ip" "$USERNAME" "$PASSWORD")
        echo -n " [$os_type]"
        
        # Collect info based on OS
        local result
        case "$os_type" in
            "Linux")
                result=$(collect_linux_info "$ip" "$USERNAME" "$PASSWORD")
                ;;
            "Solaris")
                result=$(collect_solaris_info "$ip" "$USERNAME" "$PASSWORD")
                ;;
            "macOS")
                result=$(collect_macos_info "$ip" "$USERNAME" "$PASSWORD")
                ;;
            *)
                result=$(collect_linux_info "$ip" "$USERNAME" "$PASSWORD")
                ;;
        esac
        
        # Parse result - split by |
        IFS='|' read -ra fields <<< "$result"
        
        local hostname="${fields[0]:-Unknown}"
        local virtual="${fields[1]:-Unknown}"
        local manufacturer="${fields[2]:-Unknown}"
        local model="${fields[3]:-Unknown}"
        local serial="${fields[4]:-Unknown}"
        local os="${fields[5]:-Unknown}"
        local kernel="${fields[6]:-Unknown}"
        local memory="${fields[7]:-Unknown}"
        local memtype="${fields[8]:-Unknown}"
        local firmware="${fields[9]:-Unknown}"
        local ostype="${fields[10]:-Unknown}"
        local status="${fields[11]:-Unknown}"
        
        # Write to CSV
        echo "\"Server\",\"$hostname\",\"$ip\",\"$virtual\",\"$manufacturer\",\"$model\",\"$serial\",\"$os\",\"$firmware\",\"$memory\",\"$memtype\",\"$kernel\",\"$ostype\",\"$status\"" >> "$OUTPUT_FILE"
        
        if [[ "$status" == "Success" ]]; then
            echo " [OK] $hostname"
            ((success_count++))
        else
            echo " [FAILED]"
            ((fail_count++))
        fi
    done
    
    # Show results
    echo ""
    echo "  ═══════════════════════════════════════════════════════════"
    echo "                          RESULTS"
    echo "  ═══════════════════════════════════════════════════════════"
    echo ""
    echo "  Saved: $OUTPUT_FILE"
    echo ""
    echo "  Total scanned:  $total_hosts"
    echo "  Successful:     $success_count"
    echo "  Failed:         $fail_count"
    echo ""
    
    read -p "  Press Enter to continue..."
}

configure_settings() {
    while true; do
        show_settings_menu
        read -p "  Enter your choice: " settings_choice
        
        case "$settings_choice" in
            1)
                read -p "  Enter subnet (e.g., 192.168.1.0/24): " SUBNET
                ;;
            2)
                read -p "  Enter username: " USERNAME
                ;;
            3)
                read -s -p "  Enter password: " PASSWORD
                echo ""
                ;;
            4)
                read -p "  Enter output file path: " OUTPUT_FILE
                ;;
            5)
                read -p "  Enter timeout in seconds: " TIMEOUT
                ;;
            0)
                break
                ;;
            *)
                echo "  Invalid option. Please try again."
                sleep 1
                ;;
        esac
    done
}

#===============================================================================
# MAIN LOOP
#===============================================================================

main() {
    # Initialize tools on startup
    init_tools
    
    while true; do
        show_main_menu
        read -p "  Enter your choice: " choice
        
        case "$choice" in
            1)
                start_scan
                ;;
            2)
                start_scan
                ;;
            3)
                configure_settings
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
                echo "  Thank you for using AXIS!"
                echo ""
                echo "  GitHub: https://github.com/IICarrionII/Axis"
                echo ""
                echo "  Goodbye!"
                echo ""
                exit 0
                ;;
            *)
                echo "  Invalid option. Please enter 0-7."
                sleep 1
                ;;
        esac
    done
}

# Start the program
main
