<div align="center">

# 🛡️ SOC Home Lab — Cloud-Based Threat Intelligence & Security Monitoring

### A Comprehensive Security Operations Center Built on Microsoft Azure

[![Azure](https://img.shields.io/badge/Cloud-Microsoft_Azure-0078D4?style=for-the-badge&logo=microsoftazure&logoColor=white)](https://azure.microsoft.com)
[![Wazuh](https://img.shields.io/badge/SIEM-Wazuh_4.x-00A7E1?style=for-the-badge&logo=wazuh&logoColor=white)](https://wazuh.com)
[![Docker](https://img.shields.io/badge/Container-Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)](https://docker.com)
[![Suricata](https://img.shields.io/badge/NIDS-Suricata-F6A821?style=for-the-badge)](https://suricata.io)
[![Grafana](https://img.shields.io/badge/Viz-Grafana-F46800?style=for-the-badge&logo=grafana&logoColor=white)](https://grafana.com)
[![MISP](https://img.shields.io/badge/Threat_Intel-MISP-003366?style=for-the-badge)](https://www.misp-project.org)
[![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)](LICENSE)

<br>

*An integrated, cloud-hosted security monitoring and incident response environment — built entirely with open-source tools for cybersecurity education, training, and real-world threat detection.*

---

**[📖 Documentation](docs/)** · **[🚀 Quick Start](#-quick-start)** · **[🧪 Attack Simulations](#-attack-simulations--validation)** · **[📊 Screenshots](#-screenshots)** · **[🗺️ Roadmap](#%EF%B8%8F-roadmap--future-enhancements)**

</div>

---

## 📖 Overview

This project implements a **complete Security Operations Center (SOC) home lab** hosted on **Microsoft Azure**, integrating **10+ open-source security tools** into a unified threat detection, analysis, and incident response pipeline. It serves as both a **training platform** and a **functional security monitoring system**.

The lab replicates enterprise-grade SOC capabilities — including **SIEM**, **SOAR**, **Threat Intelligence**, **NIDS**, **DFIR**, and **automated alerting** — making it accessible to students, cybersecurity enthusiasts, and small-to-medium organisations without enterprise budgets.

> **🎓 Academic Project**  
> BSc (Hons) Cyber Security & Digital Forensics — Kingston University  
> **Author:** Baskaran Elilan (E264017 / 2528298)  
> **Supervisor:** Mr. Bhimaja C. Goonatillaka

---

## 🏗️ Architecture

<div align="center">

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        MICROSOFT AZURE CLOUD                           │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  ┌─── Security Tools Subnet ─────────────────────────────────────────┐  │
│  │                                                                    │  │
│  │  ┌──────────────┐  ┌──────────┐  ┌───────────┐  ┌─────────────┐  │  │
│  │  │   Wazuh       │  │  MISP    │  │ The Hive  │  │  DFIR-IRIS  │  │  │
│  │  │ Server Stack  │  │ Threat   │  │ Incident  │  │  Forensics  │  │  │
│  │  │ (Indexer +    │  │ Intel    │  │ Response  │  │  & Case     │  │  │
│  │  │  Manager +    │  │ Platform │  │ Platform  │  │  Management │  │  │
│  │  │  Dashboard)   │  │          │  │           │  │             │  │  │
│  │  └──────┬───────┘  └────┬─────┘  └─────┬─────┘  └──────┬──────┘  │  │
│  │         │               │               │               │         │  │
│  │  ┌──────┴───────┐  ┌────┴─────┐  ┌─────┴─────┐                   │  │
│  │  │  Suricata    │  │ Shuffle  │  │ Prometheus│                   │  │
│  │  │  NIDS        │  │ SOAR     │  │ Metrics   │                   │  │
│  │  └──────────────┘  └────┬─────┘  └─────┬─────┘                   │  │
│  │                         │               │                         │  │
│  │                    ┌────┴───────────────┴────┐                    │  │
│  │                    │       Grafana            │                    │  │
│  │                    │    Visualization         │                    │  │
│  │                    └─────────────────────────┘                    │  │
│  └────────────────────────────────────────────────────────────────────┘  │
│                                                                         │
│  ┌─── Endpoint Subnet ────────────┐  ┌─── Attack Subnet ────────────┐  │
│  │                                 │  │                               │  │
│  │  ┌─────────────┐ ┌───────────┐ │  │  ┌───────────────────────┐   │  │
│  │  │ Windows     │ │ Ubuntu    │ │  │  │     Kali Linux        │   │  │
│  │  │ Server 2022 │ │ Server   │ │  │  │   Attack Simulation   │   │  │
│  │  │ (Agent)     │ │ (Agent)  │ │  │  │        VM             │   │  │
│  │  └─────────────┘ └───────────┘ │  │  └───────────────────────┘   │  │
│  └─────────────────────────────────┘  └───────────────────────────────┘  │
│                                                                         │
│                    ┌──────────────────────────────┐                      │
│                    │  🔔 Slack / Discord / Telegram │                     │
│                    │     Real-time Notifications    │                     │
│                    └──────────────────────────────┘                      │
└─────────────────────────────────────────────────────────────────────────┘
```

</div>

### Data Flow

```
Endpoints (Wazuh Agents) ──→ Wazuh Server ──→ Alert Analysis
                                    │
                    ┌───────────────┼───────────────┐
                    ▼               ▼               ▼
              The Hive          Shuffle          Grafana
            (Case Mgmt)     (Automation)    (Visualization)
                │               │
                ▼               ▼
            DFIR-IRIS    Slack/Discord/Telegram
           (Forensics)    (Notifications)
                │
                ▼
              MISP
        (Threat Intel)
```

---

## 🔧 Technology Stack

| Category | Tool | Version | Purpose |
|:---|:---|:---|:---|
| ☁️ **Cloud Platform** | Microsoft Azure | IaaS | VMs, VNets, NSGs, Storage |
| 🔍 **SIEM** | Wazuh | 4.x | Log analysis, FIM, vulnerability detection |
| 📡 **Endpoint Agents** | Wazuh Agents | 4.x | Windows & Linux endpoint monitoring |
| 🌐 **NIDS** | Suricata | 7.x | Network intrusion detection |
| 🧠 **Threat Intelligence** | MISP | Latest | IOC sharing & malware intelligence |
| 🎫 **Incident Response** | The Hive | 5.x | Case management & collaboration |
| 🔬 **DFIR** | DFIR-IRIS | Latest | Digital forensics & investigation |
| ⚙️ **SOAR** | Shuffle | Latest | Workflow automation & orchestration |
| 📈 **Metrics** | Prometheus | Latest | System & service performance metrics |
| 📊 **Visualization** | Grafana | Latest | Dashboards for security & metrics |
| 🔔 **Notifications** | Slack / Discord / Telegram | — | Real-time alert delivery |
| 🗡️ **Attack Simulation** | Kali Linux | Latest | Controlled penetration testing |
| 🐳 **Containerization** | Docker | Latest | Deployment of MISP, The Hive, DFIR-IRIS, Shuffle |
| 💻 **Endpoints** | Ubuntu Server / Windows Server 2022 | — | Monitored target systems |

---

## ⚡ Key Features

### 🔄 End-to-End SOC Lifecycle
- **Detection** → Wazuh agents collect logs, FIM events, and security data from endpoints
- **Network Monitoring** → Suricata NIDS detects port scans, exploits, and suspicious traffic
- **Correlation** → Wazuh server correlates endpoint + network events with custom rules
- **Triage** → Automated case creation in The Hive via API integration
- **Enrichment** → MISP provides threat intelligence context (IOCs, known malicious indicators)
- **Investigation** → DFIR-IRIS manages forensic artifacts and detailed case analysis
- **Automation** → Shuffle orchestrates workflows for IOC submission, filtering, and notifications
- **Visualization** → Grafana dashboards combine security events + system performance metrics
- **Alerting** → Real-time notifications via Slack, Discord, and Telegram

### 🏗️ Infrastructure
- Segmented Azure Virtual Network with **3 isolated subnets** (Security Tools / Endpoints / Attack)
- Network Security Groups (NSGs) controlling inter-subnet traffic
- Docker containerized deployments for rapid setup and reproducibility

### 🎓 Educational Design
- Step-by-step documentation for learners
- Controlled attack simulation environment
- Replicable setup for academic and training purposes

---

## 📋 Prerequisites

Before deploying the lab, ensure you have:

- [ ] **Microsoft Azure** subscription (free tier or Pay-As-You-Go)
- [ ] **Azure CLI** installed ([install guide](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli))
- [ ] **Docker** and **Docker Compose** knowledge
- [ ] **SSH client** for VM access
- [ ] Basic understanding of **Linux system administration**
- [ ] Minimum **8 GB RAM** per VM (recommended: Standard B2s or B2ms instances)

### Estimated Azure Resources

| VM | OS | Specs | Purpose |
|:---|:---|:---|:---|
| wazuh-server | Ubuntu 22.04 | B2ms (2 vCPU, 8 GB) | Wazuh Indexer + Server + Dashboard |
| security-tools | Ubuntu 22.04 | B2ms (2 vCPU, 8 GB) | MISP, The Hive, DFIR-IRIS, Shuffle |
| monitoring | Ubuntu 22.04 | B2s (2 vCPU, 4 GB) | Prometheus + Grafana |
| suricata-nids | Ubuntu 22.04 | B2s (2 vCPU, 4 GB) | Suricata Network IDS |
| win-endpoint | Windows Server 2022 | B2s (2 vCPU, 4 GB) | Monitored Windows endpoint |
| linux-endpoint | Ubuntu 22.04 | B1ms (1 vCPU, 2 GB) | Monitored Linux endpoint |
| kali-attacker | Kali Linux | B2s (2 vCPU, 4 GB) | Attack simulation |

---

## 🚀 Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/BaskaranElilan/Security-Operations-Center-Home-Lab.git
cd Security-Operations-Center-Home-Lab
```

### 2. Provision Azure Infrastructure

```bash
# Login to Azure
az login

# Run the infrastructure deployment script
chmod +x infrastructure/azure/deploy.sh
./infrastructure/azure/deploy.sh
```

### 3. Deploy Wazuh SIEM

```bash
# SSH into the Wazuh server VM
ssh azureuser@<wazuh-server-ip>

# Install Wazuh using the official installer
curl -sO https://packages.wazuh.com/4.9/wazuh-install.sh
sudo bash wazuh-install.sh -a
```

### 4. Deploy Security Tools (Docker)

```bash
# SSH into the security tools VM
ssh azureuser@<security-tools-ip>

# Deploy MISP
cd configs/misp && docker-compose up -d

# Deploy The Hive
cd ../thehive && docker-compose up -d

# Deploy DFIR-IRIS
cd ../dfir-iris && docker-compose up -d

# Deploy Shuffle
cd ../shuffle && docker-compose up -d
```

### 5. Install Wazuh Agents

```bash
# On each endpoint VM
chmod +x scripts/install-wazuh-agent.sh
./scripts/install-wazuh-agent.sh <wazuh-server-ip>
```

### 6. Configure Integrations

```bash
# Set up API connections between tools
chmod +x scripts/setup-integrations.sh
./scripts/setup-integrations.sh
```

> 📖 **For detailed step-by-step instructions**, see the [Installation Guide](docs/installation-guide.md)

---

## 🧪 Attack Simulations & Validation

The lab was validated using controlled attack simulations from the **Kali Linux VM** against monitored endpoints.

### Simulated Attacks

| # | Attack Type | Tool Used | Detection Method | Result |
|:---|:---|:---|:---|:---|
| 1 | SSH Brute Force | Hydra | Wazuh Agent | ✅ Detected & Alerted |
| 2 | File Modification (Ransomware Sim) | Custom Script | Wazuh FIM | ✅ Detected & Alerted |
| 3 | Port Scanning | Nmap | Suricata NIDS | ✅ Detected & Alerted |
| 4 | Exploit Attempts | Metasploit | Suricata + Wazuh | ✅ Detected & Escalated |

### End-to-End Workflow Verified

```
1. Kali Linux → Launches attack against endpoint
2. Wazuh Agent → Detects suspicious activity on endpoint
3. Suricata → Detects malicious network traffic
4. Wazuh Server → Correlates alerts, triggers rules
5. The Hive → Auto-creates incident case via API
6. MISP → Enriches alerts with IOC matching
7. DFIR-IRIS → Manages forensic investigation
8. Shuffle → Runs automated playbook
9. Slack/Discord → Delivers real-time notification
10. Grafana → Visualizes event on dashboard
```

### Run Your Own Simulation

```bash
# From the Kali Linux VM
chmod +x scripts/attack-simulation.sh
./scripts/attack-simulation.sh <target-endpoint-ip>
```

> 📖 **For detailed testing procedures**, see the [Testing Guide](docs/testing-guide.md)

---

## 📊 Screenshots

<details>
<summary><b>🔍 Wazuh SIEM Dashboard</b> — Security alerts and agent monitoring</summary>
<br>
<i>Shows real-time security events, agent status, and alert severity distribution</i>
</details>

<details>
<summary><b>📈 Grafana Dashboards</b> — Security metrics and system performance</summary>
<br>
<i>Combined visualization of Wazuh security data and Prometheus system metrics</i>
</details>

<details>
<summary><b>🎫 The Hive</b> — Incident case management</summary>
<br>
<i>Auto-generated cases from Wazuh alerts with enriched IOC data</i>
</details>

<details>
<summary><b>🧠 MISP</b> — Threat intelligence platform</summary>
<br>
<i>IOC feeds and threat intelligence correlation</i>
</details>

<details>
<summary><b>⚙️ Shuffle</b> — SOAR workflow automation</summary>
<br>
<i>Automated playbooks for alert triage and notification delivery</i>
</details>

<details>
<summary><b>🔬 DFIR-IRIS</b> — Digital forensics investigation</summary>
<br>
<i>Forensic case management and artifact analysis</i>
</details>

> 💡 **Tip:** Add your own screenshots to the `screenshots/` directory and update the paths above.

---

## 📁 Repository Structure

```
Security-Operations-Center-Home-Lab/
├── 📄 README.md                          # This file
├── 📄 LICENSE                            # MIT License
├── 📄 CHANGELOG.md                       # Version history
├── 📄 CONTRIBUTING.md                    # Contribution guidelines
├── 📄 SECURITY.md                        # Security policy
├── 📄 CODE_OF_CONDUCT.md                 # Community guidelines
├── 📄 .gitignore                         # Git ignore rules
├── 📄 .env.template                      # Environment variable template
│
├── 📁 docs/                              # Documentation
│   ├── 📄 architecture.md               # Detailed system architecture
│   ├── 📄 installation-guide.md         # Step-by-step setup
│   ├── 📄 integration-guide.md          # Tool integration details
│   ├── 📄 testing-guide.md              # Attack simulation guide
│   ├── 📄 BEST_PRACTICES.md             # Security & code best practices
│   ├── 📄 MAINTENANCE_GUIDE.md          # Operations & maintenance
│   └── 📄 PRE_DEPLOYMENT_CHECKLIST.md   # Pre-deployment verification
│
├── 📁 configs/                           # Configuration files
│   ├── 📁 wazuh/                        # Wazuh SIEM configs
│   │   ├── 📄 ossec.conf               # Agent configuration
│   │   ├── 📄 local_decoder.xml        # Custom Suricata decoder
│   │   └── 📄 local_rules.xml          # Custom detection rules
│   ├── 📁 suricata/                     # Suricata NIDS config
│   │   └── 📄 suricata.yaml
│   ├── 📁 misp/                         # MISP deployment
│   │   └── 📄 docker-compose.yml
│   ├── 📁 thehive/                      # The Hive deployment
│   │   └── 📄 docker-compose.yml
│   ├── 📁 dfir-iris/                    # DFIR-IRIS deployment
│   │   └── 📄 docker-compose.yml
│   ├── 📁 shuffle/                      # Shuffle SOAR deployment
│   │   └── 📄 docker-compose.yml
│   ├── 📁 prometheus/                   # Prometheus metrics
│   │   └── 📄 prometheus.yml
│   └── 📁 grafana/                      # Grafana visualization
│       └── 📁 provisioning/
│           └── 📄 dashboards.yml
│
├── 📁 infrastructure/                    # Cloud infrastructure
│   ├── 📄 network-topology.md           # Network layout & IP assignments
│   └── 📁 azure/
│       ├── 📄 deploy.sh                 # Azure CLI deployment
│       └── 📄 nsg-rules.json           # Network security rules
│
├── 📁 scripts/                           # Automation scripts
│   ├── 📄 install-wazuh-agent.sh        # Agent deployment
│   ├── 📄 setup-integrations.sh         # API & webhook setup
│   ├── 📄 attack-simulation.sh          # Attack test suite
│   └── 📄 verify-deployment.sh          # Post-deployment health checks
│
├── 📁 report/                            # Academic report
│   └── 📄 CI6600_Final_Report.pdf
│
└── 📁 screenshots/                       # Dashboard screenshots
    └── 📄 .gitkeep
```

---

## 🗺️ Roadmap & Future Enhancements

- [ ] 🍎 Add macOS and IoT endpoint coverage
- [ ] 🔎 Integrate Zeek alongside Suricata for enhanced network analysis
- [ ] 🤖 Implement machine learning models for anomaly detection
- [ ] 🍯 Deploy honeypot technologies for lateral movement detection
- [ ] 🔄 Enhance Shuffle workflows with complex automated response actions
- [ ] 🐳 Full Kubernetes orchestration for all components
- [ ] 🏋️ Regular blue team exercises for continuous validation
- [ ] 📝 Terraform/Bicep templates for Infrastructure-as-Code
- [ ] 📱 Mobile push notifications for critical alerts

---

## 📚 References

- Alzahrani, S. & Hong, L. (2023). *An Open-Source Security Monitoring Solution for Cloud Environments*. Journal of Cybersecurity Research, 7(2), pp. 45-61.
- García-Teodoro, P. & Díaz-Verdejo, J. (2022). *Open-Source Tools for Security Monitoring: A Comparative Analysis*. IEEE Security & Privacy, 20(3), pp. 24-31.
- Kumar, R. & Mishra, S. (2023). *Integrating Threat Intelligence with SIEM Systems: Challenges and Solutions*. International Journal of Network Security, 25(1), pp. 103-115.
- White, J., & Thompson, A. (2023). *Home Labs for Cybersecurity Education: Design Considerations and Best Practices*. Journal of Information Systems Education, 34(2), pp. 112-125.
- NIST. (2023). *Guide to Security Information and Event Management (SP 800-92r1)*. National Institute of Standards and Technology.
- Rodriguez, M., et al. (2024). *Automation in Security Operations: The Role of SOAR Platforms*. ACM Computing Surveys, 56(4), 1-36.
- Wazuh Documentation. (2024). *Wazuh v4.5: The Open-Source Security Platform*. Wazuh Inc.
- The Hive Project. (2023). *The Hive: A Scalable, Open-Source Security Incident Response Platform*.
- Zimmerman, C. (2023). *The Importance of DFIR Tools in Modern Incident Response*. SANS Institute Reading Room.

---

## 👤 Author

**Baskaran Elilan**  
BSc (Hons) Cyber Security & Digital Forensics  
Kingston University — Faculty of Science, Engineering and Computing  

- 📧 Student ID: E264017 / 2528298  
- 👨‍🏫 Supervisor: Mr. Bhimaja C. Goonatillaka

---

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

---

<div align="center">

**⭐ If you find this project useful, please consider giving it a star! ⭐**

*Built with ❤️ for the cybersecurity community*

</div>
