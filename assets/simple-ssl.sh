#!/bin/bash
# SSL setup using JensSpanier's acme.sh branch with certificate profile support
# Direct IP certificates with shortlived profile

set -e

# Check if running as root/sudo (required for port 80)
if [ "$EUID" -ne 0 ]; then
    echo -e "\033[0;31mError: This script must be run as root or with sudo!\033[0m"
    echo "Port 80 is a privileged port and requires root access."
    echo "Please run: sudo $0 $@"
    exit 1
fi

# Configuration
SERVER_IP="${1:-$(curl -s ifconfig.me)}"
EMAIL="a@aol.com"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}IP SSL setup using profile-enabled acme.sh for IP: $SERVER_IP${NC}"

# Validate IP
if [[ ! $SERVER_IP =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
    echo -e "${RED}Invalid IP: $SERVER_IP${NC}"
    exit 1
fi

# Clean up previous attempts
echo "Cleaning up previous certificate attempts..."
sudo rm -rf /tmp/acme-profiles
sudo rm -rf /tmp/certs

# Create certificate directory
mkdir -p /tmp/certs

# Clone profile-enabled acme.sh (only if not already present)
if [ ! -d "/tmp/acme-profiles" ]; then
    echo "Downloading profile-enabled acme.sh..."
    cd /tmp
    git clone -b dev https://github.com/JensSpanier/acme.sh.git acme-profiles
else
    echo "Using existing profile-enabled acme.sh..."
fi

cd /tmp/acme-profiles
chmod +x acme.sh

# Install dependencies if needed
if ! command -v socat &> /dev/null; then
    echo "Installing socat (required for standalone mode)..."
    sudo apt-get update && sudo apt-get install -y socat
fi

# Request IP certificate with shortlived profile
echo -e "${GREEN}Requesting IP certificate with shortlived profile...${NC}"
echo -e "${YELLOW}Using JensSpanier's branch with certificate profile support${NC}"

./acme.sh --issue \
    --standalone \
    --server letsencrypt_test \
    --accountemail "$EMAIL" \
    --certificate-profile shortlived \
    -d "$SERVER_IP" \
    --force \
    --debug 2

# Check if certificate was created (checks both RSA and ECC directories)
CERT_DIR_RSA="$HOME/.acme.sh/$SERVER_IP"
CERT_DIR_ECC="$HOME/.acme.sh/${SERVER_IP}_ecc"

# Check both possible certificate directories
if [ -f "$CERT_DIR_ECC/fullchain.cer" ] && [ -f "$CERT_DIR_ECC/$SERVER_IP.key" ]; then
    CERT_DIR="$CERT_DIR_ECC"
    echo -e "${GREEN}✓ IP certificate (ECC) obtained successfully!${NC}"
elif [ -f "$CERT_DIR_RSA/fullchain.cer" ] && [ -f "$CERT_DIR_RSA/$SERVER_IP.key" ]; then
    CERT_DIR="$CERT_DIR_RSA"
    echo -e "${GREEN}✓ IP certificate (RSA) obtained successfully!${NC}"
else
    echo -e "${RED}Certificate generation failed${NC}"
    echo "Checked directories:"
    echo "  RSA: $CERT_DIR_RSA"
    echo "  ECC: $CERT_DIR_ECC"
    ls -la "$CERT_DIR_RSA" 2>/dev/null || echo "  RSA directory not found"
    ls -la "$CERT_DIR_ECC" 2>/dev/null || echo "  ECC directory not found"
    exit 1
fi

# Copy certificates to accessible location
sudo cp "$CERT_DIR/fullchain.cer" /tmp/certs/
sudo cp "$CERT_DIR/$SERVER_IP.key" /tmp/certs/
sudo chmod 644 /tmp/certs/*

echo ""
echo -e "${GREEN}🎉 IP SSL certificate obtained successfully!${NC}"
echo ""
echo -e "${GREEN}Certificate files are located at:${NC}"
echo "  Certificate: /tmp/certs/fullchain.cer"
echo "  Private key: /tmp/certs/$SERVER_IP.key"
echo "  Source: $CERT_DIR"
echo ""
echo -e "${YELLOW}Certificate details:${NC}"
echo "  Profile: shortlived"
echo "  Valid for: ~6 days"
echo "  Environment: Staging (browsers will show warning)"
echo ""
echo -e "${GREEN}You can now use these certificate files with your web server of choice.${NC}"
