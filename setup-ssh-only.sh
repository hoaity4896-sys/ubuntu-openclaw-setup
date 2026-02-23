#!/bin/bash
# ============================================================
# Ubuntu SSH-Only Setup Script
# Lightweight: install curl + setup SSH remote access
# Author: hoaity
# License: MIT
# ============================================================

# ── Colors ───────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
DIM='\033[2m'
BOLD='\033[1m'
NC='\033[0m'
BG_GREEN='\033[42m'
BG_RED='\033[41m'

# ── Resolve actual user (not root) ──────────────────────────
ACTUAL_USER="${SUDO_USER:-$USER}"
ACTUAL_HOME=$(eval echo "~$ACTUAL_USER")

# ── Helper Functions ─────────────────────────────────────────

type_color() {
    local color="$1" text="$2" delay="${3:-0.02}"
    printf "%b" "$color"
    for ((i=0; i<${#text}; i++)); do
        printf "%s" "${text:$i:1}"
        sleep "$delay"
    done
    printf "%b\n" "$NC"
}

print_ok()   { echo -e "  ${BG_GREEN}${WHITE} OK ${NC} ${GREEN}$1${NC}"; }
print_fail() { echo -e "  ${BG_RED}${WHITE} FAIL ${NC} ${RED}$1${NC}"; }
print_skip() { echo -e "  ${YELLOW}[ SKIP ]${NC} ${DIM}$1${NC}"; }

print_step() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}${GREEN}  [$1/4]${NC} ${BOLD}${WHITE}$2${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

spinner() {
    local pid=$1 msg="$2"
    local chars='⣾⣽⣻⢿⡿⣟⣯⣷'
    while kill -0 "$pid" 2>/dev/null; do
        for ((i=0; i<${#chars}; i++)); do
            printf "\r  ${GREEN}${chars:$i:1}${NC} %s" "$msg"
            sleep 0.1
        done
    done
    printf "\r\033[2K"
}

# ── Check Root ───────────────────────────────────────────────
check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo ""
        echo -e "${RED}  ╔═══════════════════════════════════════════════╗${NC}"
        echo -e "${RED}  ║  ERROR: This script must be run as root!     ║${NC}"
        echo -e "${RED}  ║                                              ║${NC}"
        echo -e "${RED}  ║  Usage: sudo bash setup-ssh-only.sh          ║${NC}"
        echo -e "${RED}  ╚═══════════════════════════════════════════════╝${NC}"
        echo ""
        exit 1
    fi
}

# ── Banner ───────────────────────────────────────────────────
show_banner() {
    clear
    echo ""
    echo -e "${GREEN}  ╔══════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}  ║                                                  ║${NC}"
    echo -e "${GREEN}  ║${WHITE}    ____ ____  _   _    ___        _             ${GREEN}║${NC}"
    echo -e "${GREEN}  ║${WHITE}   / ___/ ___|| | | |  / _ \ _ __ | |_   _      ${GREEN}║${NC}"
    echo -e "${GREEN}  ║${WHITE}   \___ \___ \| |_| | | | | | '_ \| | | | |     ${GREEN}║${NC}"
    echo -e "${GREEN}  ║${WHITE}    ___) |__) |  _  | | |_| | | | | | |_| |     ${GREEN}║${NC}"
    echo -e "${GREEN}  ║${WHITE}   |____/____/|_| |_|  \___/|_| |_|_|\__, |     ${GREEN}║${NC}"
    echo -e "${GREEN}  ║${WHITE}                                     |___/      ${GREEN}║${NC}"
    echo -e "${GREEN}  ║                                                  ║${NC}"
    echo -e "${GREEN}  ║${CYAN}       SSH-ONLY SETUP ${DIM}v1.0${NC}${GREEN}                        ║${NC}"
    echo -e "${GREEN}  ║${DIM}       curl + SSH remote access${NC}${GREEN}                   ║${NC}"
    echo -e "${GREEN}  ║                                                  ║${NC}"
    echo -e "${GREEN}  ╚══════════════════════════════════════════════════╝${NC}"
    echo ""
    type_color "$DIM" "  Initializing SSH setup..." 0.03
    sleep 0.5
}

# ── Step 1: Update System ──────────────────────────────────
update_system() {
    print_step "1" "UPDATE SYSTEM"
    echo ""

    type_color "$DIM" "  > Updating package lists..." 0.02
    apt-get update -qq -o=Dpkg::Use-Pty=0 > /dev/null 2>&1 &
    spinner $! "Updating package lists..."
    print_ok "Package lists updated"
}

# ── Step 2: Install Curl ─────────────────────────────────
install_curl() {
    print_step "2" "INSTALL CURL"
    echo ""

    if command -v curl &> /dev/null; then
        print_skip "curl is already installed"
        echo ""
        type_color "$DIM" "  > Skipping installation..." 0.02
        return 0
    fi

    type_color "$DIM" "  > Installing curl..." 0.02
    apt-get install -y -qq -o=Dpkg::Use-Pty=0 curl > /dev/null 2>&1 &
    spinner $! "Installing curl..."

    if command -v curl &> /dev/null; then
        print_ok "curl installed"
    else
        print_fail "Failed to install curl"
        return 1
    fi
}

# ── Step 3: Install & Enable SSH ─────────────────────────
setup_ssh() {
    print_step "3" "INSTALL & ENABLE SSH"
    echo ""

    # Install openssh-server
    if dpkg -l | grep -q openssh-server; then
        print_skip "OpenSSH Server is already installed"
    else
        type_color "$DIM" "  > Installing openssh-server..." 0.02
        apt-get install -y -qq -o=Dpkg::Use-Pty=0 openssh-server > /dev/null 2>&1 &
        spinner $! "Installing openssh-server..."

        if dpkg -l | grep -q openssh-server; then
            print_ok "OpenSSH Server installed"
        else
            print_fail "Failed to install OpenSSH Server"
            return 1
        fi
    fi

    # Enable SSH on boot
    echo ""
    type_color "$DIM" "  > Enabling SSH service..." 0.02
    systemctl enable ssh > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        print_ok "SSH enabled on boot"
    else
        print_fail "Failed to enable SSH"
    fi

    # Start SSH
    type_color "$DIM" "  > Starting SSH service..." 0.02
    systemctl start ssh > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        print_ok "SSH service is running"
    else
        systemctl enable sshd > /dev/null 2>&1
        systemctl start sshd > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            print_ok "SSH service is running (sshd)"
        else
            print_fail "Failed to start SSH service"
        fi
    fi

    # Verify
    if systemctl is-active --quiet ssh 2>/dev/null || systemctl is-active --quiet sshd 2>/dev/null; then
        echo ""
        echo -e "  ${GREEN}●${NC} ${WHITE}SSH Status: ${GREEN}ACTIVE${NC}"
    fi

    # Disable sleep/suspend
    echo ""
    type_color "$DIM" "  > Disabling sleep/suspend..." 0.02
    systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        print_ok "Sleep/suspend disabled"
    fi
}

# ── Step 4: Configure Bashrc Display ──────────────────────
configure_display() {
    print_step "4" "CONFIGURE TERMINAL DISPLAY"
    echo ""

    local BASHRC="$ACTUAL_HOME/.bashrc"

    type_color "$DIM" "  > Configuring $BASHRC ..." 0.02

    # Check if already configured
    if grep -q "# >>> SSH-ONLY-SETUP >>>" "$BASHRC" 2>/dev/null; then
        sed -i '/# >>> SSH-ONLY-SETUP >>>/,/# <<< SSH-ONLY-SETUP <<</d' "$BASHRC"
        print_skip "Removing old configuration..."
    fi

    # Add new block
    cat >> "$BASHRC" << 'BASHRC_BLOCK'

# >>> SSH-ONLY-SETUP >>>
# Auto-display SSH connection info on terminal open
_show_ssh_info() {
    local G='\033[0;32m'
    local C='\033[0;36m'
    local W='\033[1;37m'
    local D='\033[2m'
    local N='\033[0m'
    local IP
    IP=$(hostname -I 2>/dev/null | awk '{print $1}')
    local USER_NAME
    USER_NAME=$(whoami)
    local SSH_STATUS

    if systemctl is-active --quiet ssh 2>/dev/null || systemctl is-active --quiet sshd 2>/dev/null; then
        SSH_STATUS="${G}● Running${N}"
    else
        SSH_STATUS="\033[0;31m● Stopped${N}"
    fi

    echo ""
    echo -e "${G}  ┌──────────────────────────────────────────────┐${N}"
    echo -e "${G}  │${N}  ${W}SSH REMOTE ACCESS${N}                             ${G}│${N}"
    echo -e "${G}  │${N}  ${D}────────────────────────────────────────${N}    ${G}│${N}"
    echo -e "${G}  │${N}  ${C}Connect:${N} ${W}ssh ${USER_NAME}@${IP}${N}$(printf '%*s' $((23 - ${#USER_NAME} - ${#IP})) '')${G}│${N}"
    echo -e "${G}  │${N}  ${C}Status :${N} ${SSH_STATUS}$(printf '%*s' 28 '')${G}│${N}"
    echo -e "${G}  └──────────────────────────────────────────────┘${N}"
    echo ""
}
_show_ssh_info

# <<< SSH-ONLY-SETUP <<<
BASHRC_BLOCK

    print_ok "Terminal display configured"
    echo -e "  ${DIM}SSH info will show on every new terminal${NC}"
}

# ── Show Final Result ────────────────────────────────────
show_result() {
    local IP
    IP=$(hostname -I 2>/dev/null | awk '{print $1}')

    echo ""
    echo ""
    type_color "$GREEN" "  ══════════════════════════════════════════════════" 0.01
    type_color "$GREEN" "   SETUP COMPLETE" 0.03
    type_color "$GREEN" "  ══════════════════════════════════════════════════" 0.01
    echo ""

    echo -e "${GREEN}  ╔══════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}  ║${NC}  ${BOLD}${WHITE}CONNECTION INFO${NC}                                 ${GREEN}║${NC}"
    echo -e "${GREEN}  ╠══════════════════════════════════════════════════╣${NC}"
    echo -e "${GREEN}  ║${NC}                                                  ${GREEN}║${NC}"
    echo -e "${GREEN}  ║${NC}  ${CYAN}User${NC} : ${WHITE}${ACTUAL_USER}${NC}$(printf '%*s' $((38 - ${#ACTUAL_USER})) '')${GREEN}║${NC}"
    echo -e "${GREEN}  ║${NC}  ${CYAN}IP${NC}   : ${WHITE}${IP:-N/A}${NC}$(printf '%*s' $((38 - ${#IP})) '')${GREEN}║${NC}"
    echo -e "${GREEN}  ║${NC}  ${CYAN}Port${NC} : ${WHITE}22${NC}$(printf '%*s' 36 '')${GREEN}║${NC}"
    echo -e "${GREEN}  ║${NC}                                                  ${GREEN}║${NC}"
    echo -e "${GREEN}  ║${NC}  ${BOLD}${YELLOW}ssh ${ACTUAL_USER}@${IP}${NC}$(printf '%*s' $((33 - ${#ACTUAL_USER} - ${#IP})) '')${GREEN}║${NC}"
    echo -e "${GREEN}  ║${NC}                                                  ${GREEN}║${NC}"
    echo -e "${GREEN}  ╠══════════════════════════════════════════════════╣${NC}"
    echo -e "${GREEN}  ║${NC}  ${BOLD}${WHITE}QUICK GUIDE${NC}                                    ${GREEN}║${NC}"
    echo -e "${GREEN}  ╠══════════════════════════════════════════════════╣${NC}"
    echo -e "${GREEN}  ║${NC}                                                  ${GREEN}║${NC}"
    echo -e "${GREEN}  ║${NC}  ${WHITE}1.${NC} From another PC, open terminal              ${GREEN}║${NC}"
    echo -e "${GREEN}  ║${NC}  ${WHITE}2.${NC} Run:  ${CYAN}ssh ${ACTUAL_USER}@${IP}${NC}$(printf '%*s' $((25 - ${#ACTUAL_USER} - ${#IP})) '')${GREEN}║${NC}"
    echo -e "${GREEN}  ║${NC}  ${WHITE}3.${NC} Enter your Ubuntu password                  ${GREEN}║${NC}"
    echo -e "${GREEN}  ║${NC}  ${WHITE}4.${NC} Copy file to remote:                        ${GREEN}║${NC}"
    echo -e "${GREEN}  ║${NC}     ${CYAN}scp file.txt ${ACTUAL_USER}@${IP}:~/${NC}$(printf '%*s' $((18 - ${#ACTUAL_USER} - ${#IP})) '')${GREEN}║${NC}"
    echo -e "${GREEN}  ║${NC}  ${WHITE}5.${NC} To disconnect: type ${CYAN}exit${NC}                   ${GREEN}║${NC}"
    echo -e "${GREEN}  ║${NC}                                                  ${GREEN}║${NC}"
    echo -e "${GREEN}  ╚══════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  ${DIM}Open a new terminal to see the SSH info display.${NC}"
    echo ""
}

# ── Main ─────────────────────────────────────────────────
main() {
    check_root
    show_banner
    update_system
    install_curl
    setup_ssh
    configure_display
    show_result
}

main "$@"
