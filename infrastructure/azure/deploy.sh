#!/bin/bash
# ============================================================
# Azure Infrastructure Deployment Script
# SOC Home Lab — Cloud-Based Threat Intelligence Lab
#
# This script provisions the complete Azure infrastructure:
#   - Resource Group
#   - Virtual Network with 3 subnets
#   - Network Security Groups
#   - 7 Virtual Machines
#
# Usage: ./deploy.sh
# Prerequisites: Azure CLI installed and logged in (az login)
# ============================================================

set -euo pipefail

# ==================== Configuration ====================
RESOURCE_GROUP="soc-lab-rg"
LOCATION="uksouth"
VNET_NAME="soc-lab-vnet"
VNET_PREFIX="10.0.0.0/16"
ADMIN_USER="azureuser"

# Subnet Configuration
SECURITY_SUBNET="security-tools-subnet"
SECURITY_PREFIX="10.0.1.0/24"
ENDPOINTS_SUBNET="endpoints-subnet"
ENDPOINTS_PREFIX="10.0.2.0/24"
ATTACK_SUBNET="attack-subnet"
ATTACK_PREFIX="10.0.3.0/24"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}"
echo "╔═══════════════════════════════════════════════════╗"
echo "║       SOC Home Lab — Azure Deployment Script      ║"
echo "║       Cloud-Based Threat Intelligence Lab         ║"
echo "╚═══════════════════════════════════════════════════╝"
echo -e "${NC}"

# ==================== Pre-flight Checks ====================
echo -e "${YELLOW}[1/7] Pre-flight checks...${NC}"

if ! command -v az &> /dev/null; then
    echo -e "${RED}Error: Azure CLI is not installed. Install from https://docs.microsoft.com/en-us/cli/azure/install-azure-cli${NC}"
    exit 1
fi

# Check login status
az account show &> /dev/null || {
    echo -e "${RED}Error: Not logged in to Azure. Run 'az login' first.${NC}"
    exit 1
}

SUBSCRIPTION=$(az account show --query name -o tsv)
echo -e "${GREEN}  ✓ Azure CLI installed and logged in${NC}"
echo -e "${GREEN}  ✓ Subscription: ${SUBSCRIPTION}${NC}"

# ==================== Resource Group ====================
echo -e "${YELLOW}[2/7] Creating Resource Group...${NC}"

az group create \
    --name "$RESOURCE_GROUP" \
    --location "$LOCATION" \
    --tags project="SOC-Home-Lab" environment="lab" \
    --output none

echo -e "${GREEN}  ✓ Resource Group: ${RESOURCE_GROUP} (${LOCATION})${NC}"

# ==================== Virtual Network & Subnets ====================
echo -e "${YELLOW}[3/7] Creating Virtual Network and Subnets...${NC}"

az network vnet create \
    --resource-group "$RESOURCE_GROUP" \
    --name "$VNET_NAME" \
    --address-prefix "$VNET_PREFIX" \
    --output none

# Security Tools Subnet
az network vnet subnet create \
    --resource-group "$RESOURCE_GROUP" \
    --vnet-name "$VNET_NAME" \
    --name "$SECURITY_SUBNET" \
    --address-prefix "$SECURITY_PREFIX" \
    --output none

# Endpoints Subnet
az network vnet subnet create \
    --resource-group "$RESOURCE_GROUP" \
    --vnet-name "$VNET_NAME" \
    --name "$ENDPOINTS_SUBNET" \
    --address-prefix "$ENDPOINTS_PREFIX" \
    --output none

# Attack Subnet
az network vnet subnet create \
    --resource-group "$RESOURCE_GROUP" \
    --vnet-name "$VNET_NAME" \
    --name "$ATTACK_SUBNET" \
    --address-prefix "$ATTACK_PREFIX" \
    --output none

echo -e "${GREEN}  ✓ VNet: ${VNET_NAME} (${VNET_PREFIX})${NC}"
echo -e "${GREEN}  ✓ Subnet: ${SECURITY_SUBNET} (${SECURITY_PREFIX})${NC}"
echo -e "${GREEN}  ✓ Subnet: ${ENDPOINTS_SUBNET} (${ENDPOINTS_PREFIX})${NC}"
echo -e "${GREEN}  ✓ Subnet: ${ATTACK_SUBNET} (${ATTACK_PREFIX})${NC}"

# ==================== Network Security Groups ====================
echo -e "${YELLOW}[4/7] Creating Network Security Groups...${NC}"

# Security Tools NSG
az network nsg create --resource-group "$RESOURCE_GROUP" --name "security-tools-nsg" --output none

# Allow SSH from internet (restrict to your IP in production)
az network nsg rule create \
    --resource-group "$RESOURCE_GROUP" \
    --nsg-name "security-tools-nsg" \
    --name "AllowSSH" \
    --priority 100 \
    --access Allow \
    --direction Inbound \
    --protocol Tcp \
    --destination-port-ranges 22 \
    --output none

# Allow Wazuh Dashboard (443)
az network nsg rule create \
    --resource-group "$RESOURCE_GROUP" \
    --nsg-name "security-tools-nsg" \
    --name "AllowWazuhDashboard" \
    --priority 110 \
    --access Allow \
    --direction Inbound \
    --protocol Tcp \
    --destination-port-ranges 443 \
    --output none

# Allow Wazuh Agent Communication (1514-1515)
az network nsg rule create \
    --resource-group "$RESOURCE_GROUP" \
    --nsg-name "security-tools-nsg" \
    --name "AllowWazuhAgents" \
    --priority 120 \
    --access Allow \
    --direction Inbound \
    --protocol Tcp \
    --destination-port-ranges 1514-1515 \
    --source-address-prefixes "10.0.0.0/16" \
    --output none

# Endpoints NSG
az network nsg create --resource-group "$RESOURCE_GROUP" --name "endpoints-nsg" --output none

az network nsg rule create \
    --resource-group "$RESOURCE_GROUP" \
    --nsg-name "endpoints-nsg" \
    --name "AllowSSH" \
    --priority 100 \
    --access Allow \
    --direction Inbound \
    --protocol Tcp \
    --destination-port-ranges 22 3389 \
    --output none

# Attack NSG
az network nsg create --resource-group "$RESOURCE_GROUP" --name "attack-nsg" --output none

az network nsg rule create \
    --resource-group "$RESOURCE_GROUP" \
    --nsg-name "attack-nsg" \
    --name "AllowSSH" \
    --priority 100 \
    --access Allow \
    --direction Inbound \
    --protocol Tcp \
    --destination-port-ranges 22 \
    --output none

# Associate NSGs with subnets
az network vnet subnet update \
    --resource-group "$RESOURCE_GROUP" \
    --vnet-name "$VNET_NAME" \
    --name "$SECURITY_SUBNET" \
    --network-security-group "security-tools-nsg" \
    --output none

az network vnet subnet update \
    --resource-group "$RESOURCE_GROUP" \
    --vnet-name "$VNET_NAME" \
    --name "$ENDPOINTS_SUBNET" \
    --network-security-group "endpoints-nsg" \
    --output none

az network vnet subnet update \
    --resource-group "$RESOURCE_GROUP" \
    --vnet-name "$VNET_NAME" \
    --name "$ATTACK_SUBNET" \
    --network-security-group "attack-nsg" \
    --output none

echo -e "${GREEN}  ✓ NSGs created and associated with subnets${NC}"

# ==================== Virtual Machines ====================
echo -e "${YELLOW}[5/7] Creating Virtual Machines (this may take several minutes)...${NC}"

# Wazuh Server
echo -e "  ${CYAN}Creating Wazuh Server VM...${NC}"
az vm create \
    --resource-group "$RESOURCE_GROUP" \
    --name "wazuh-server" \
    --image "Ubuntu2204" \
    --size "Standard_B2ms" \
    --vnet-name "$VNET_NAME" \
    --subnet "$SECURITY_SUBNET" \
    --nsg "security-tools-nsg" \
    --admin-username "$ADMIN_USER" \
    --generate-ssh-keys \
    --os-disk-size-gb 64 \
    --private-ip-address "10.0.1.10" \
    --public-ip-sku Standard \
    --tags role="wazuh-siem" \
    --output none
echo -e "  ${GREEN}✓ wazuh-server${NC}"

# Security Tools VM (MISP, The Hive, DFIR-IRIS, Shuffle)
echo -e "  ${CYAN}Creating Security Tools VM...${NC}"
az vm create \
    --resource-group "$RESOURCE_GROUP" \
    --name "security-tools" \
    --image "Ubuntu2204" \
    --size "Standard_B2ms" \
    --vnet-name "$VNET_NAME" \
    --subnet "$SECURITY_SUBNET" \
    --nsg "security-tools-nsg" \
    --admin-username "$ADMIN_USER" \
    --generate-ssh-keys \
    --os-disk-size-gb 64 \
    --private-ip-address "10.0.1.20" \
    --public-ip-sku Standard \
    --tags role="security-tools" \
    --output none
echo -e "  ${GREEN}✓ security-tools${NC}"

# Suricata NIDS
echo -e "  ${CYAN}Creating Suricata NIDS VM...${NC}"
az vm create \
    --resource-group "$RESOURCE_GROUP" \
    --name "suricata-nids" \
    --image "Ubuntu2204" \
    --size "Standard_B2s" \
    --vnet-name "$VNET_NAME" \
    --subnet "$SECURITY_SUBNET" \
    --nsg "security-tools-nsg" \
    --admin-username "$ADMIN_USER" \
    --generate-ssh-keys \
    --os-disk-size-gb 32 \
    --private-ip-address "10.0.1.30" \
    --public-ip-sku Standard \
    --tags role="nids" \
    --output none
echo -e "  ${GREEN}✓ suricata-nids${NC}"

# Monitoring VM (Prometheus + Grafana)
echo -e "  ${CYAN}Creating Monitoring VM...${NC}"
az vm create \
    --resource-group "$RESOURCE_GROUP" \
    --name "monitoring" \
    --image "Ubuntu2204" \
    --size "Standard_B2s" \
    --vnet-name "$VNET_NAME" \
    --subnet "$SECURITY_SUBNET" \
    --nsg "security-tools-nsg" \
    --admin-username "$ADMIN_USER" \
    --generate-ssh-keys \
    --os-disk-size-gb 32 \
    --private-ip-address "10.0.1.40" \
    --public-ip-sku Standard \
    --tags role="monitoring" \
    --output none
echo -e "  ${GREEN}✓ monitoring${NC}"

# Linux Endpoint
echo -e "  ${CYAN}Creating Linux Endpoint VM...${NC}"
az vm create \
    --resource-group "$RESOURCE_GROUP" \
    --name "linux-endpoint" \
    --image "Ubuntu2204" \
    --size "Standard_B1ms" \
    --vnet-name "$VNET_NAME" \
    --subnet "$ENDPOINTS_SUBNET" \
    --nsg "endpoints-nsg" \
    --admin-username "$ADMIN_USER" \
    --generate-ssh-keys \
    --os-disk-size-gb 32 \
    --private-ip-address "10.0.2.20" \
    --public-ip-sku Standard \
    --tags role="endpoint" \
    --output none
echo -e "  ${GREEN}✓ linux-endpoint${NC}"

# Windows Endpoint
echo -e "  ${CYAN}Creating Windows Endpoint VM...${NC}"
az vm create \
    --resource-group "$RESOURCE_GROUP" \
    --name "win-endpoint" \
    --image "Win2022Datacenter" \
    --size "Standard_B2s" \
    --vnet-name "$VNET_NAME" \
    --subnet "$ENDPOINTS_SUBNET" \
    --nsg "endpoints-nsg" \
    --admin-username "$ADMIN_USER" \
    --admin-password "${WIN_ADMIN_PASSWORD:?Set WIN_ADMIN_PASSWORD env var before running}" \
    --os-disk-size-gb 128 \
    --private-ip-address "10.0.2.10" \
    --public-ip-sku Standard \
    --tags role="endpoint" \
    --output none
echo -e "  ${GREEN}✓ win-endpoint${NC}"

# Kali Linux Attacker
echo -e "  ${CYAN}Creating Kali Linux VM...${NC}"
az vm create \
    --resource-group "$RESOURCE_GROUP" \
    --name "kali-attacker" \
    --image "kali-linux:kali:kali-2024-2:latest" \
    --size "Standard_B2s" \
    --vnet-name "$VNET_NAME" \
    --subnet "$ATTACK_SUBNET" \
    --nsg "attack-nsg" \
    --admin-username "$ADMIN_USER" \
    --generate-ssh-keys \
    --os-disk-size-gb 32 \
    --private-ip-address "10.0.3.10" \
    --public-ip-sku Standard \
    --tags role="attacker" \
    --output none
echo -e "  ${GREEN}✓ kali-attacker${NC}"

# ==================== Summary ====================
echo -e "\n${YELLOW}[6/7] Retrieving VM IP addresses...${NC}"

echo -e "\n${CYAN}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                 VM PUBLIC IP ADDRESSES                     ║${NC}"
echo -e "${CYAN}╠═══════════════════════════════════════════════════════════╣${NC}"

for VM_NAME in wazuh-server security-tools suricata-nids monitoring linux-endpoint win-endpoint kali-attacker; do
    PUBLIC_IP=$(az vm list-ip-addresses \
        --resource-group "$RESOURCE_GROUP" \
        --name "$VM_NAME" \
        --query "[0].virtualMachine.network.publicIpAddresses[0].ipAddress" \
        --output tsv 2>/dev/null || echo "N/A")
    printf "${CYAN}║${NC}  %-20s → %s\n" "$VM_NAME" "$PUBLIC_IP"
done

echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${NC}"

# ==================== Done ====================
echo -e "\n${YELLOW}[7/7] Deployment complete!${NC}"
echo -e "${GREEN}"
echo "Next steps:"
echo "  1. SSH into each VM and install the required software"
echo "  2. Follow the Installation Guide: docs/installation-guide.md"
echo "  3. Follow the Integration Guide: docs/integration-guide.md"
echo "  4. Run attack simulations: docs/testing-guide.md"
echo -e "${NC}"
echo -e "${RED}⚠  IMPORTANT: Change all default passwords before use!${NC}"
echo -e "${RED}⚠  IMPORTANT: Restrict NSG SSH rules to your IP only!${NC}"
