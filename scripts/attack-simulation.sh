#!/bin/bash
# ============================================================
# Attack Simulation Script (SOC Home Lab)
# Run controlled attacks against monitored endpoints
#
# Usage: ./attack-simulation.sh <TARGET_IP>
# Run on: Kali Linux VM
# ============================================================

set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; NC='\033[0m'

if [ $# -lt 1 ]; then
    echo -e "${RED}Usage: $0 <TARGET_IP>${NC}"
    echo "  Example: $0 10.0.2.20"
    exit 1
fi

TARGET_IP="$1"

echo -e "${CYAN}"
echo "╔═══════════════════════════════════════════════╗"
echo "║     SOC Home Lab — Attack Simulation Suite    ║"
echo "║     ⚠  FOR EDUCATIONAL PURPOSES ONLY ⚠       ║"
echo "╚═══════════════════════════════════════════════╝"
echo -e "${NC}"
echo -e "  Target: ${RED}${TARGET_IP}${NC}"
echo ""

# ==================== Test 1: Port Scan ====================
echo -e "${YELLOW}[Test 1/4] Port Scanning (Nmap)...${NC}"
echo "  Running: nmap -sS -p 1-1000 ${TARGET_IP}"
echo ""

nmap -sS -p 1-1000 "$TARGET_IP" -oN /tmp/nmap_scan.txt 2>/dev/null || true

echo -e "${GREEN}  ✓ Port scan complete${NC}"
echo -e "  → Check Suricata/Wazuh for scan detection alerts"
echo ""
sleep 5

# ==================== Test 2: SSH Brute Force ====================
echo -e "${YELLOW}[Test 2/4] SSH Brute Force (Hydra)...${NC}"

# Create a small test wordlist
cat > /tmp/test_passwords.txt << 'EOF'
password
123456
admin
root
test
password123
letmein
welcome
monkey
dragon
EOF

echo "  Running: hydra -l admin -P /tmp/test_passwords.txt ssh://${TARGET_IP} -t 4"
echo ""

hydra -l admin -P /tmp/test_passwords.txt "ssh://${TARGET_IP}" -t 4 -V 2>/dev/null || true

echo -e "${GREEN}  ✓ SSH brute force simulation complete${NC}"
echo -e "  → Check Wazuh for rule 5710/5712 (SSH auth failure) alerts"
echo ""
sleep 5

# ==================== Test 3: Aggressive Scan ====================
echo -e "${YELLOW}[Test 3/4] Aggressive Service Scan (Nmap)...${NC}"
echo "  Running: nmap -A -T4 ${TARGET_IP}"
echo ""

nmap -A -T4 "$TARGET_IP" -oN /tmp/nmap_aggressive.txt 2>/dev/null || true

echo -e "${GREEN}  ✓ Aggressive scan complete${NC}"
echo -e "  → Check Suricata for exploit attempt alerts"
echo ""
sleep 5

# ==================== Test 4: Nikto Web Scan ====================
echo -e "${YELLOW}[Test 4/4] Web Vulnerability Scan (Nikto)...${NC}"
echo "  Running: nikto -h ${TARGET_IP} -p 80,443,8080"
echo ""

if command -v nikto &> /dev/null; then
    timeout 60 nikto -h "$TARGET_IP" -p 80 -output /tmp/nikto_scan.txt 2>/dev/null || true
    echo -e "${GREEN}  ✓ Web scan complete${NC}"
else
    echo -e "${YELLOW}  ⚠ Nikto not installed. Install with: sudo apt install nikto${NC}"
fi

echo ""

# ==================== Summary ====================
echo -e "${CYAN}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║           Attack Simulation Complete                      ║${NC}"
echo -e "${CYAN}╠═══════════════════════════════════════════════════════════╣${NC}"
echo -e "${CYAN}║  Now verify detection in:                                 ║${NC}"
echo -e "${CYAN}║   1. Wazuh Dashboard  → Security Events                  ║${NC}"
echo -e "${CYAN}║   2. The Hive         → New incident cases               ║${NC}"
echo -e "${CYAN}║   3. MISP             → IOC matches                      ║${NC}"
echo -e "${CYAN}║   4. Grafana          → Dashboard spike                  ║${NC}"
echo -e "${CYAN}║   5. Slack/Discord    → Alert notifications              ║${NC}"
echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "Scan results saved to /tmp/nmap_scan.txt and /tmp/nmap_aggressive.txt"

# Cleanup
rm -f /tmp/test_passwords.txt
