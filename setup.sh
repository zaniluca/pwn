#!/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

VM_NAME="default"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_FILE="$SCRIPT_DIR/pwn.yaml"

print_step() {
    echo -e "\n${BLUE}==>${NC} ${1}"
}

print_success() {
    echo -e "${GREEN}${NC} ${1}"
}

print_warning() {
    echo -e "${YELLOW}${NC} ${1}"
}

print_error() {
    echo -e "${RED}${NC} ${1}"
}

check_macos() {
    print_step "Checking operating system..."
    if [[ "$(uname)" != "Darwin" ]]; then
        print_error "This script is designed for macOS only."
        exit 1
    fi
    print_success "Operating system is macOS"
}

check_apple_silicon() {
    print_step "Checking processor architecture..."
    if [[ "$(uname -m)" != "arm64" ]]; then
        print_warning "This script is optimized for Apple Silicon (ARM64)."
        print_warning "You appear to be running on Intel. The x86_64 VM may work differently."
        read -p "Continue anyway? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    else
        print_success "Running on Apple Silicon"
    fi
}

check_brew() {
    print_step "Checking for Homebrew..."
    if command -v brew &> /dev/null; then
        print_success "Homebrew is already installed"
    else
        print_warning "Homebrew not found, homebrew is required to continue."
        print_warning "See https://brew.sh/ for installation instructions."
        exit 1
    fi
}

setup_lima() {
    print_step "Checking for Lima..."
    if command -v limactl &> /dev/null; then
        print_success "Lima is already installed"
    else
        print_warning "Lima not found. Installing..."
        brew install lima
        print_success "Lima installed"
    fi
}

setup_lima_guestagents() {
    print_step "Checking for Lima additional guest agents..."
    
    LIMA_SHARE="$(brew --prefix)/share/lima"
    if [[ -f "$LIMA_SHARE/lima-guestagent.Linux-x86_64" ]] || [[ -f "$LIMA_SHARE/lima-guestagent.Linux-x86_64.gz" ]]; then
        print_success "Lima additional guest agents already installed"
    else
        print_warning "Lima additional guest agents not found. Installing..."
        brew install lima-additional-guestagents
        print_success "Lima additional guest agents installed"
    fi
}

check_template() {
    print_step "Checking for template file..."
    if [[ ! -f "$TEMPLATE_FILE" ]]; then
        print_error "Template file not found: $TEMPLATE_FILE"
        print_error "Make sure pwn.yaml is in the same directory as this script."
        exit 1
    fi
    print_success "Template file found"
}

setup_vm() {
    print_step "Checking for existing VM '$VM_NAME'..."
    
    if limactl list -q | grep -q "^${VM_NAME}$"; then
        print_warning "VM '$VM_NAME' already exists."
        read -p "Do you want to delete it and create a fresh one? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_step "Stopping and deleting existing VM..."
            limactl stop "$VM_NAME" 2>/dev/null || true
            limactl delete "$VM_NAME" -f
            print_success "Existing VM deleted"
        else
            print_warning "Keeping existing VM. Skipping VM creation."
            return 0
        fi
    fi
    
    print_step "Creating VM '$VM_NAME' (this may take a moment)..."
    limactl create --name="$VM_NAME" "$TEMPLATE_FILE"
    print_success "VM created"
    
    print_step "Starting VM '$VM_NAME'..."
    echo -e "${YELLOW}This will take various minutes on first boot as it installs all tools.${NC}"
    echo -e "${YELLOW}Please be patient...${NC}"
    limactl start "$VM_NAME"
    print_success "VM started"
}

setup_vscode_ssh() {
    print_step "Setting up VS Code SSH configuration..."
    
    SSH_CONFIG="$HOME/.ssh/config"
    LIMA_SSH_CONFIG="$HOME/.lima/$VM_NAME/ssh.config"
    
    # Create .ssh directory if it doesn't exist
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"
    
    # Check if Lima SSH config exists
    if [[ ! -f "$LIMA_SSH_CONFIG" ]]; then
        print_warning "Lima SSH config not found. VM may not be running."
        return 1
    fi
    
    # Check if already configured
    if grep -q "lima-$VM_NAME" "$SSH_CONFIG" 2>/dev/null; then
        print_success "VS Code SSH already configured"
    else
        print_warning "Adding Lima SSH config to $SSH_CONFIG..."
        echo "" >> "$SSH_CONFIG"
        echo "# Lima PWN/CTF VM" >> "$SSH_CONFIG"
        cat "$LIMA_SSH_CONFIG" >> "$SSH_CONFIG"
        print_success "VS Code SSH configured"
    fi
}

print_instructions() {
    echo ""
    echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}  Setup Complete!${NC}"
    echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${BLUE}Quick Start:${NC}"
    echo "  Enter the VM:              lima"
    echo "  Stop the VM:               limactl stop $VM_NAME"
    echo "  Start the VM:              limactl start $VM_NAME"
    echo ""
    echo -e "${BLUE}Tip:${NC}"
    echo "  Check out README.md at https://github.com/zaniluca/pwn for more info!"
    echo ""
    echo -e "${BLUE}Your Mac files are at:${NC} /Users/$(whoami)/"
    echo ""
}

main() {
    check_macos
    check_apple_silicon
    check_template
    check_brew
    setup_lima
    setup_lima_guestagents
    setup_vm
    setup_vscode_ssh
    print_instructions
}

main "$@"
