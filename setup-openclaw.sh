#!/bin/bash
# ============================================================
# Ubuntu OpenClaw Setup Script
# All-in-one: update system, remote access, NVM, Node, OpenClaw
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
NVM_DIR="$ACTUAL_HOME/.nvm"

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
    echo -e "${BOLD}${GREEN}  [$1/5]${NC} ${BOLD}${WHITE}$2${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Spinner — shows animation while PID is alive, then clears line
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

# Run a command in background with spinner, return its exit code
run_with_spinner() {
    local msg="$1"
    shift
    "$@" &
    local pid=$!
    spinner "$pid" "$msg"
    wait "$pid"
    return $?
}

# Run command as actual user with NVM loaded
run_as_user() {
    sudo -u "$ACTUAL_USER" bash -c "
        export HOME=\"$ACTUAL_HOME\"
        export NVM_DIR=\"$NVM_DIR\"
        [ -s \"\$NVM_DIR/nvm.sh\" ] && . \"\$NVM_DIR/nvm.sh\"
        $1
    "
}

# ── Check Root ───────────────────────────────────────────────
check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo ""
        echo -e "${RED}  ╔═══════════════════════════════════════════════╗${NC}"
        echo -e "${RED}  ║  ERROR: This script must be run as root!     ║${NC}"
        echo -e "${RED}  ║                                              ║${NC}"
        echo -e "${RED}  ║  Usage: sudo bash setup-openclaw.sh          ║${NC}"
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
    echo -e "${GREEN}  ║${WHITE}    ___                    ____ _                ${GREEN}║${NC}"
    echo -e "${GREEN}  ║${WHITE}   / _ \\ _ __   ___ _ __  / ___| | __ ___      __${GREEN}║${NC}"
    echo -e "${GREEN}  ║${WHITE}  | | | | '_ \\ / _ \\ '_ \\| |   | |/ _\` \\ \\ /\\ / /${GREEN}║${NC}"
    echo -e "${GREEN}  ║${WHITE}  | |_| | |_) |  __/ | | | |___| | (_| |\\ V  V / ${GREEN}║${NC}"
    echo -e "${GREEN}  ║${WHITE}   \\___/| .__/ \\___|_| |_|\\____|_|\\__,_| \\_/\\_/  ${GREEN}║${NC}"
    echo -e "${GREEN}  ║${WHITE}        |_|                                      ${GREEN}║${NC}"
    echo -e "${GREEN}  ║                                                  ║${NC}"
    echo -e "${GREEN}  ║${CYAN}       UBUNTU SETUP ${DIM}v1.0${NC}${GREEN}                          ║${NC}"
    echo -e "${GREEN}  ║${DIM}       github.com/hoaity/ubuntu-openclaw-setup${NC}${GREEN}  ║${NC}"
    echo -e "${GREEN}  ║                                                  ║${NC}"
    echo -e "${GREEN}  ╚══════════════════════════════════════════════════╝${NC}"
    echo ""
    type_color "$DIM" "  Initializing full system setup..." 0.03
    sleep 0.5
}

# ── Step 1: Update System ──────────────────────────────────
update_system() {
    print_step "1" "UPDATE SYSTEM"
    echo ""

    type_color "$DIM" "  > Updating package lists..." 0.02
    run_with_spinner "Updating package lists..." apt-get update -qq -o=Dpkg::Use-Pty=0
    print_ok "Package lists updated"

    echo ""
    type_color "$DIM" "  > Upgrading packages..." 0.02
    run_with_spinner "Upgrading packages..." apt-get upgrade -y -qq -o=Dpkg::Use-Pty=0
    print_ok "All packages upgraded"

    echo ""
    type_color "$DIM" "  > Cleaning up..." 0.02
    apt-get autoremove -y -qq > /dev/null 2>&1
    apt-get autoclean -qq > /dev/null 2>&1
    print_ok "Unused packages removed"

    echo ""
    echo -e "  ${DIM}System is up to date${NC}"
}

# ── Step 2: Install Dependencies ─────────────────────────
install_deps() {
    print_step "2" "INSTALL DEPENDENCIES"
    echo ""

    local PACKAGES="curl git build-essential python3"

    type_color "$DIM" "  > Installing: $PACKAGES ..." 0.02
    run_with_spinner "Installing $PACKAGES..." apt-get install -y -qq -o=Dpkg::Use-Pty=0 $PACKAGES

    # Verify each one
    local all_ok=true
    for cmd in curl git gcc python3; do
        if command -v "$cmd" &> /dev/null; then
            print_ok "$cmd ready"
        else
            print_fail "$cmd not found after install"
            all_ok=false
        fi
    done

    if [ "$all_ok" = false ]; then
        echo -e "  ${RED}Some dependencies failed to install${NC}"
        return 1
    fi
}

# ── Step 3: Run Ubuntu Remote Setup ──────────────────────
run_remote_setup() {
    print_step "3" "UBUNTU REMOTE ACCESS SETUP"
    echo ""

    local REMOTE_URL="https://raw.githubusercontent.com/hoaity4896-sys/ubuntu-remote-setup/main/setup-ubuntu-remote.sh"

    type_color "$DIM" "  > Downloading remote setup script..." 0.02
    local SCRIPT_CONTENT
    SCRIPT_CONTENT=$(curl -fsSL "$REMOTE_URL" 2>/dev/null)

    if [ -z "$SCRIPT_CONTENT" ]; then
        print_fail "Failed to download remote setup script"
        echo -e "  ${DIM}URL: $REMOTE_URL${NC}"
        return 1
    fi

    print_ok "Script downloaded"
    echo ""
    type_color "$DIM" "  > Running ubuntu-remote-setup..." 0.02
    echo ""

    bash -c "$SCRIPT_CONTENT"

    if [ $? -eq 0 ]; then
        echo ""
        print_ok "Ubuntu remote setup completed"
    else
        print_fail "Ubuntu remote setup encountered errors"
    fi
}

# ── Step 4: Install NVM + Node ───────────────────────────
install_node() {
    print_step "4" "INSTALL NVM + NODE 24"
    echo ""

    local NVM_VERSION="v0.40.3"

    # Install NVM
    type_color "$DIM" "  > Installing NVM $NVM_VERSION for $ACTUAL_USER..." 0.02

    sudo -u "$ACTUAL_USER" bash -c "
        export HOME=\"$ACTUAL_HOME\"
        curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/$NVM_VERSION/install.sh | bash
    " > /dev/null 2>&1 &
    local pid=$!
    spinner "$pid" "Installing NVM..."
    wait "$pid"

    if [ -s "$NVM_DIR/nvm.sh" ]; then
        print_ok "NVM $NVM_VERSION installed"
    else
        print_fail "Failed to install NVM"
        return 1
    fi

    # Install Node 24
    echo ""
    type_color "$DIM" "  > Installing Node.js 24..." 0.02

    run_as_user "nvm install 24 && nvm alias default 24" > /dev/null 2>&1 &
    pid=$!
    spinner "$pid" "Installing Node.js 24..."
    wait "$pid"

    # Verify
    local NODE_V NPM_V
    NODE_V=$(run_as_user "node -v 2>/dev/null")
    NPM_V=$(run_as_user "npm -v 2>/dev/null")

    if [ -n "$NODE_V" ]; then
        print_ok "Node.js $NODE_V installed"
        print_ok "npm $NPM_V installed"
        print_ok "Default alias set to Node 24"
    else
        print_fail "Failed to install Node.js 24"
        return 1
    fi
}

# ── Step 5: Install OpenClaw ─────────────────────────────
install_openclaw() {
    print_step "5" "INSTALL OPENCLAW"
    echo ""

    local LOGFILE="/tmp/openclaw-install-$$.log"

    type_color "$DIM" "  > Installing openclaw globally..." 0.02

    # Run npm install — log to file, spinner in foreground
    sudo -u "$ACTUAL_USER" bash -c "
        export HOME=\"$ACTUAL_HOME\"
        export NVM_DIR=\"$NVM_DIR\"
        export SHARP_IGNORE_GLOBAL_LIBVIPS=1
        [ -s \"\$NVM_DIR/nvm.sh\" ] && . \"\$NVM_DIR/nvm.sh\"
        npm install -g openclaw@latest
    " > "$LOGFILE" 2>&1 &
    local pid=$!
    spinner "$pid" "Installing openclaw@latest (this may take a while)..."
    wait "$pid"
    local rc=$?

    if [ $rc -ne 0 ]; then
        print_fail "Failed to install OpenClaw (exit code: $rc)"
        echo ""
        echo -e "  ${RED}Last error:${NC}"
        tail -5 "$LOGFILE" 2>/dev/null | while IFS= read -r line; do
            echo -e "  ${DIM}  $line${NC}"
        done
        echo ""
        echo -e "  ${DIM}Full log: $LOGFILE${NC}"
        echo -e "  ${DIM}Try manually:${NC}"
        echo -e "  ${WHITE}  SHARP_IGNORE_GLOBAL_LIBVIPS=1 npm install -g openclaw@latest${NC}"
        return 1
    fi
    rm -f "$LOGFILE"

    # Verify
    local OC_V
    OC_V=$(run_as_user "openclaw --version 2>/dev/null")

    if [ -n "$OC_V" ]; then
        print_ok "OpenClaw $OC_V installed"
    else
        print_skip "Installed but 'openclaw --version' returned empty"
        echo -e "  ${DIM}Open a new terminal and try: openclaw --version${NC}"
    fi
}

# ── Show Final Result ────────────────────────────────────
show_result() {
    local IP
    IP=$(hostname -I 2>/dev/null | awk '{print $1}')

    local NODE_V NPM_V OC_V
    NODE_V=$(run_as_user "node -v 2>/dev/null")
    NPM_V=$(run_as_user "npm -v 2>/dev/null")
    OC_V=$(run_as_user "openclaw --version 2>/dev/null")

    echo ""
    echo ""
    type_color "$GREEN" "  ══════════════════════════════════════════════════" 0.01
    type_color "$GREEN" "   SETUP COMPLETE" 0.03
    type_color "$GREEN" "  ══════════════════════════════════════════════════" 0.01
    echo ""

    echo -e "${GREEN}  ╔══════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}  ║${NC}  ${BOLD}${WHITE}ENVIRONMENT INFO${NC}                                ${GREEN}║${NC}"
    echo -e "${GREEN}  ╠══════════════════════════════════════════════════╣${NC}"
    echo -e "${GREEN}  ║${NC}                                                  ${GREEN}║${NC}"
    echo -e "${GREEN}  ║${NC}  ${CYAN}User${NC}     : ${WHITE}${ACTUAL_USER}${NC}$(printf '%*s' $((35 - ${#ACTUAL_USER})) '')${GREEN}║${NC}"
    echo -e "${GREEN}  ║${NC}  ${CYAN}IP${NC}       : ${WHITE}${IP:-N/A}${NC}$(printf '%*s' $((35 - ${#IP})) '')${GREEN}║${NC}"
    echo -e "${GREEN}  ║${NC}  ${CYAN}Node${NC}     : ${WHITE}${NODE_V:-N/A}${NC}$(printf '%*s' $((35 - ${#NODE_V})) '')${GREEN}║${NC}"
    echo -e "${GREEN}  ║${NC}  ${CYAN}npm${NC}      : ${WHITE}${NPM_V:-N/A}${NC}$(printf '%*s' $((35 - ${#NPM_V})) '')${GREEN}║${NC}"
    echo -e "${GREEN}  ║${NC}  ${CYAN}OpenClaw${NC} : ${WHITE}${OC_V:-N/A}${NC}$(printf '%*s' $((35 - ${#OC_V})) '')${GREEN}║${NC}"
    echo -e "${GREEN}  ║${NC}                                                  ${GREEN}║${NC}"
    echo -e "${GREEN}  ║${NC}  ${CYAN}SSH${NC}      : ${WHITE}ssh ${ACTUAL_USER}@${IP}${NC}$(printf '%*s' $((27 - ${#ACTUAL_USER} - ${#IP})) '')${GREEN}║${NC}"
    echo -e "${GREEN}  ║${NC}                                                  ${GREEN}║${NC}"
    echo -e "${GREEN}  ╠══════════════════════════════════════════════════╣${NC}"
    echo -e "${GREEN}  ║${NC}  ${BOLD}${WHITE}QUICK START${NC}                                    ${GREEN}║${NC}"
    echo -e "${GREEN}  ╠══════════════════════════════════════════════════╣${NC}"
    echo -e "${GREEN}  ║${NC}                                                  ${GREEN}║${NC}"
    echo -e "${GREEN}  ║${NC}  ${WHITE}1.${NC} Open a new terminal (or reconnect SSH)        ${GREEN}║${NC}"
    echo -e "${GREEN}  ║${NC}  ${WHITE}2.${NC} Run:  ${CYAN}openclaw --version${NC}                      ${GREEN}║${NC}"
    echo -e "${GREEN}  ║${NC}  ${WHITE}3.${NC} Run:  ${CYAN}node -v && npm -v${NC}                       ${GREEN}║${NC}"
    echo -e "${GREEN}  ║${NC}  ${WHITE}4.${NC} Remote: ${CYAN}ssh ${ACTUAL_USER}@${IP}${NC}$(printf '%*s' $((22 - ${#ACTUAL_USER} - ${#IP})) '')${GREEN}║${NC}"
    echo -e "${GREEN}  ║${NC}                                                  ${GREEN}║${NC}"
    echo -e "${GREEN}  ╚══════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  ${DIM}Open a new terminal for changes to take effect.${NC}"
    echo ""
}

# ── Main ─────────────────────────────────────────────────
main() {
    check_root
    show_banner
    update_system
    install_deps
    run_remote_setup
    install_node
    install_openclaw
    show_result
}

main "$@"
