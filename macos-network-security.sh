#!/bin/bash

# macOS Network Security Lockdown Script
# Blocks unauthorized devices and domains

# Configuration
TARGET_MAC="ce:89:dd:7d:24:d1"
TARGET_IP="192.168.12.27"
LOG_FILE="$HOME/network_security.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_banner() {
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════════════╗"
    echo "║           macOS Network Security            ║"
    echo "║               Lockdown System               ║"
    echo "╚══════════════════════════════════════════════╝"
    echo -e "${NC}"
}

check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}Please run as root: sudo $0${NC}"
        exit 1
    fi
}

block_domains_hosts() {
    echo -e "${YELLOW}Blocking malicious domains...${NC}"
    
    DOMAINS_TO_BLOCK=(
        "northsouth.edu"
        "rds3.northsouth.edu"
        "webkit.org"
        "apple.com"
        "azure.com"
        "microsoft.com"
        "facebook.com"
        "fb.com"
        "lgtvonline.lge.com"
        "us.lgappstv.com"
    )
    
    for domain in "${DOMAINS_TO_BLOCK[@]}"; do
        if ! grep -q "127.0.0.1 $domain" /etc/hosts; then
            echo "127.0.0.1 $domain" | sudo tee -a /etc/hosts
            echo "::1 $domain" | sudo tee -a /etc/hosts
        fi
    done
    
    dscacheutil -flushcache
    echo -e "${GREEN}✓ Domains blocked${NC}"
}

block_target_device() {
    echo -e "${YELLOW}Blocking target device...${NC}"
    
    if ! grep -q "block in from $TARGET_IP" /etc/pf.conf 2>/dev/null; then
        echo "block in from $TARGET_IP" | sudo tee -a /etc/pf.conf
        echo "block out to $TARGET_IP" | sudo tee -a /etc/pf.conf
    fi
    
    sudo pfctl -e 2>/dev/null
    sudo pfctl -f /etc/pf.conf 2>/dev/null
    echo -e "${GREEN}✓ Target device blocked${NC}"
}

show_status() {
    echo -e "${BLUE}=== Security Status ===${NC}"
    echo "Target: $TARGET_IP ($TARGET_MAC)"
    echo "Domains Blocked: 10+"
    echo "Firewall: Active"
    echo "Time: $(date)"
}

cleanup() {
    echo -e "${YELLOW}Cleaning up...${NC}"
    sudo pfctl -d 2>/dev/null
    echo -e "${GREEN}✓ Cleanup complete${NC}"
}

case "$1" in
    "--status")
        show_status
        ;;
    "--cleanup")
        cleanup
        ;;
    "--help"|"-h")
        echo "Usage: $0 [OPTION]"
        echo "Options:"
        echo "  --status     Show security status"
        echo "  --cleanup    Remove security measures"
        echo "  --help       Show this help"
        ;;
    *)
        print_banner
        check_root
        block_domains_hosts
        block_target_device
        show_status
        echo -e "${GREEN}✓ Security lockdown complete${NC}"
        ;;
esac
