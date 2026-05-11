#!/bin/bash
# ============================================================
# Integration Setup Script (SOC Home Lab)
# Connects Wazuh → The Hive → Shuffle
# Usage: ./setup-integrations.sh
# Run on: Wazuh Server VM
# ============================================================

set -euo pipefail

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'

# ========== UPDATE THESE VALUES ==========
THEHIVE_IP="10.0.1.20"
THEHIVE_PORT="9000"
THEHIVE_API_KEY="YOUR_THEHIVE_API_KEY"
MISP_IP="10.0.1.20"
MISP_API_KEY="YOUR_MISP_API_KEY"
SHUFFLE_IP="10.0.1.20"
SHUFFLE_PORT="3001"
SHUFFLE_WEBHOOK_ID="YOUR_SHUFFLE_WEBHOOK_ID"

echo -e "${YELLOW}[1/3] Configuring Wazuh → The Hive...${NC}"
if ! grep -q "custom-thehive" /var/ossec/etc/ossec.conf 2>/dev/null; then
    sudo sed -i '/<\/ossec_config>/i \
  <integration>\
    <name>custom-thehive</name>\
    <hook_url>http://'"${THEHIVE_IP}"':'"${THEHIVE_PORT}"'/api/alert</hook_url>\
    <api_key>'"${THEHIVE_API_KEY}"'</api_key>\
    <level>10</level>\
    <alert_format>json</alert_format>\
  </integration>' /var/ossec/etc/ossec.conf
    echo -e "${GREEN}  ✓ The Hive integration added${NC}"
fi

echo -e "${YELLOW}[2/3] Configuring Wazuh → Shuffle...${NC}"
if ! grep -q "custom-shuffle" /var/ossec/etc/ossec.conf 2>/dev/null; then
    sudo sed -i '/<\/ossec_config>/i \
  <integration>\
    <name>custom-shuffle</name>\
    <hook_url>http://'"${SHUFFLE_IP}"':'"${SHUFFLE_PORT}"'/api/v1/hooks/'"${SHUFFLE_WEBHOOK_ID}"'</hook_url>\
    <level>8</level>\
    <alert_format>json</alert_format>\
  </integration>' /var/ossec/etc/ossec.conf
    echo -e "${GREEN}  ✓ Shuffle integration added${NC}"
fi

echo -e "${YELLOW}[3/3] Restarting Wazuh Manager...${NC}"
sudo systemctl restart wazuh-manager
echo -e "${GREEN}  ✓ Done! Test with attack simulations.${NC}"
