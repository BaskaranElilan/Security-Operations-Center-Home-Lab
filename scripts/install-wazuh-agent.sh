#!/bin/bash
# ============================================================
# Wazuh Agent Installation Script
# SOC Home Lab
#
# Usage: ./install-wazuh-agent.sh <WAZUH_SERVER_IP>
# Run on: Linux endpoint VMs
# ============================================================

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# ==================== Validate Input ====================
if [ $# -lt 1 ]; then
    echo -e "${RED}Usage: $0 <WAZUH_SERVER_IP>${NC}"
    echo "  Example: $0 10.0.1.10"
    exit 1
fi

WAZUH_SERVER_IP="$1"
WAZUH_VERSION="4.9"

echo -e "${CYAN}"
echo "╔═══════════════════════════════════════════════╗"
echo "║     Wazuh Agent Installation Script           ║"
echo "║     SOC Home Lab                              ║"
echo "╚═══════════════════════════════════════════════╝"
echo -e "${NC}"
echo -e "  Server IP: ${GREEN}${WAZUH_SERVER_IP}${NC}"
echo -e "  Version:   ${GREEN}${WAZUH_VERSION}${NC}"
echo ""

# ==================== Install Agent ====================
echo -e "${YELLOW}[1/4] Adding Wazuh repository...${NC}"

curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | sudo gpg --no-default-keyring --keyring gnupg-ring:/usr/share/keyrings/wazuh.gpg --import && sudo chmod 644 /usr/share/keyrings/wazuh.gpg

echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/${WAZUH_VERSION}/apt/ stable main" | sudo tee /etc/apt/sources.list.d/wazuh.list

echo -e "${GREEN}  ✓ Repository added${NC}"

echo -e "${YELLOW}[2/4] Installing Wazuh agent...${NC}"

sudo apt-get update -qq
sudo WAZUH_MANAGER="${WAZUH_SERVER_IP}" apt-get install -y wazuh-agent

echo -e "${GREEN}  ✓ Agent installed${NC}"

# ==================== Configure Agent ====================
echo -e "${YELLOW}[3/4] Configuring agent...${NC}"

# Ensure the server address is set
sudo sed -i "s|<address>.*</address>|<address>${WAZUH_SERVER_IP}</address>|g" /var/ossec/etc/ossec.conf

# Enable File Integrity Monitoring
sudo sed -i 's|<disabled>yes</disabled>|<disabled>no</disabled>|' /var/ossec/etc/ossec.conf

echo -e "${GREEN}  ✓ Agent configured for server ${WAZUH_SERVER_IP}${NC}"

# ==================== Start Agent ====================
echo -e "${YELLOW}[4/4] Starting Wazuh agent service...${NC}"

sudo systemctl daemon-reload
sudo systemctl enable wazuh-agent
sudo systemctl start wazuh-agent

# ==================== Verify ====================
sleep 3
STATUS=$(sudo systemctl is-active wazuh-agent)

if [ "$STATUS" = "active" ]; then
    echo -e "\n${GREEN}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║  ✓ Wazuh Agent installed and running!          ║${NC}"
    echo -e "${GREEN}╠═══════════════════════════════════════════════╣${NC}"
    echo -e "${GREEN}║  Server: ${WAZUH_SERVER_IP}                           ║${NC}"
    echo -e "${GREEN}║  Status: active                                ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════╝${NC}"
else
    echo -e "\n${RED}✗ Agent failed to start. Check logs:${NC}"
    echo "  sudo journalctl -u wazuh-agent -n 20"
    echo "  sudo cat /var/ossec/logs/ossec.log"
    exit 1
fi

# ==================== Install Node Exporter ====================
echo -e "\n${YELLOW}[Bonus] Installing Prometheus Node Exporter...${NC}"

sudo apt-get install -y prometheus-node-exporter
sudo systemctl enable prometheus-node-exporter
sudo systemctl start prometheus-node-exporter

echo -e "${GREEN}  ✓ Node Exporter running on port 9100${NC}"
echo -e "\n${GREEN}Done! Check the Wazuh Dashboard to verify agent registration.${NC}"
