# Installation Guide

> Step-by-step deployment guide for the SOC Home Lab on Microsoft Azure.

## Table of Contents
1. [Prerequisites](#1-prerequisites)
2. [Azure Infrastructure](#2-azure-infrastructure)
3. [Wazuh SIEM](#3-wazuh-siem)
4. [Suricata NIDS](#4-suricata-nids)
5. [MISP](#5-misp)
6. [The Hive & DFIR-IRIS](#6-the-hive--dfir-iris)
7. [Shuffle SOAR](#7-shuffle-soar)
8. [Prometheus & Grafana](#8-prometheus--grafana)
9. [Wazuh Agents](#9-wazuh-agents)
10. [Notifications](#10-notifications)

---

## 1. Prerequisites

- Microsoft Azure subscription (free tier or Pay-As-You-Go)
- Azure CLI installed locally
- SSH client
- Slack/Discord/Telegram workspace for notifications

### VM Sizing Reference

| VM Role | Azure Size | RAM | Storage |
|:---|:---|:---|:---|
| Wazuh Server | Standard_B2ms | 8 GB | 64 GB SSD |
| Security Tools | Standard_B2ms | 8 GB | 64 GB SSD |
| Monitoring | Standard_B2s | 4 GB | 32 GB SSD |
| Suricata NIDS | Standard_B2s | 4 GB | 32 GB SSD |
| Windows Endpoint | Standard_B2s | 4 GB | 128 GB SSD |
| Linux Endpoint | Standard_B1ms | 2 GB | 32 GB SSD |
| Kali Attacker | Standard_B2s | 4 GB | 32 GB SSD |

---

## 2. Azure Infrastructure

### Automated
```bash
az login
chmod +x infrastructure/azure/deploy.sh
./infrastructure/azure/deploy.sh
```

### Manual
```bash
# Resource Group
az group create --name soc-lab-rg --location uksouth

# Virtual Network
az network vnet create --resource-group soc-lab-rg --name soc-lab-vnet --address-prefix 10.0.0.0/16

# Subnets
az network vnet subnet create --resource-group soc-lab-rg --vnet-name soc-lab-vnet \
  --name security-tools-subnet --address-prefix 10.0.1.0/24
az network vnet subnet create --resource-group soc-lab-rg --vnet-name soc-lab-vnet \
  --name endpoints-subnet --address-prefix 10.0.2.0/24
az network vnet subnet create --resource-group soc-lab-rg --vnet-name soc-lab-vnet \
  --name attack-subnet --address-prefix 10.0.3.0/24

# NSGs
az network nsg create --resource-group soc-lab-rg --name security-tools-nsg
az network nsg create --resource-group soc-lab-rg --name endpoints-nsg
az network nsg create --resource-group soc-lab-rg --name attack-nsg
```

---

## 3. Wazuh SIEM

```bash
ssh azureuser@<wazuh-server-ip>
curl -sO https://packages.wazuh.com/4.9/wazuh-install.sh
sudo bash wazuh-install.sh -a
```

Access: `https://<wazuh-server-ip>` with generated credentials.

Add custom rules:
```bash
sudo cp configs/wazuh/local_decoder.xml /var/ossec/etc/decoders/local_decoder.xml
sudo cp configs/wazuh/local_rules.xml /var/ossec/etc/rules/local_rules.xml
sudo systemctl restart wazuh-manager
```

---

## 4. Suricata NIDS

```bash
ssh azureuser@<suricata-vm-ip>
sudo add-apt-repository -y ppa:oisf/suricata-stable
sudo apt-get update && sudo apt-get install -y suricata
sudo suricata-update
sudo systemctl enable suricata && sudo systemctl start suricata
```

---

## 5. MISP

```bash
cd configs/misp && docker-compose up -d
```
Access: `https://<security-tools-ip>` — Default: `admin@admin.test` / `admin`

---

## 6. The Hive & DFIR-IRIS

```bash
cd configs/thehive && docker-compose up -d
cd ../dfir-iris && docker-compose up -d
```
- The Hive: `http://<ip>:9000` — `admin@thehive.local` / `secret`
- DFIR-IRIS: `https://<ip>:8443` — `administrator` / `administrator`

---

## 7. Shuffle SOAR

```bash
cd configs/shuffle && docker-compose up -d
```
Access: `http://<ip>:3001`

---

## 8. Prometheus & Grafana

```bash
# Prometheus
sudo apt-get install -y prometheus
sudo cp configs/prometheus/prometheus.yml /etc/prometheus/prometheus.yml
sudo systemctl restart prometheus

# Node Exporter (on ALL VMs)
sudo apt-get install -y prometheus-node-exporter
sudo systemctl enable prometheus-node-exporter

# Grafana
wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -
echo "deb https://packages.grafana.com/oss/deb stable main" | sudo tee /etc/apt/sources.list.d/grafana.list
sudo apt-get update && sudo apt-get install -y grafana
sudo systemctl enable grafana-server && sudo systemctl start grafana-server
```
Access: `http://<ip>:3000` — `admin` / `admin`

---

## 9. Wazuh Agents

### Linux
```bash
chmod +x scripts/install-wazuh-agent.sh
./scripts/install-wazuh-agent.sh <wazuh-server-ip>
```

### Windows
```powershell
wazuh-agent-4.9.0-1.msi /q WAZUH_MANAGER="<wazuh-server-ip>"
net start WazuhSvc
```

---

## 10. Notifications

- **Slack**: Create Incoming Webhook → configure URL in Shuffle
- **Discord**: Create webhook in channel settings → add to Shuffle
- **Telegram**: Create bot via @BotFather → use bot token + chat ID in Shuffle

---

## Verification Checklist

- [ ] Wazuh Dashboard accessible with active agents
- [ ] Suricata logging to `/var/log/suricata/eve.json`
- [ ] MISP accessible with threat feeds synced
- [ ] The Hive & DFIR-IRIS accessible
- [ ] Shuffle workflows activated
- [ ] Grafana showing Prometheus data
- [ ] Notifications working

> Next: [Integration Guide](integration-guide.md) → [Testing Guide](testing-guide.md)
