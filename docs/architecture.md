# System Architecture

## Overview

The SOC Home Lab is deployed on **Microsoft Azure** using a segmented virtual network architecture with three distinct subnets. This design isolates security tools, monitored endpoints, and attack infrastructure to simulate a realistic enterprise network topology.

---

## Network Architecture

### Azure Virtual Network: `soc-lab-vnet` (10.0.0.0/16)

| Subnet | CIDR | Purpose | VMs |
|:---|:---|:---|:---|
| `security-tools-subnet` | 10.0.1.0/24 | Core security infrastructure | Wazuh, MISP, The Hive, DFIR-IRIS, Shuffle, Suricata, Prometheus, Grafana |
| `endpoints-subnet` | 10.0.2.0/24 | Monitored target systems | Windows Server 2022, Ubuntu Server |
| `attack-subnet` | 10.0.3.0/24 | Attack simulation (isolated) | Kali Linux |

### Network Security Groups (NSGs)

NSGs control traffic flow between subnets:

- **Security Tools NSG**: Allows inbound from endpoints subnet (agent communication), restricts attack subnet access
- **Endpoints NSG**: Allows outbound to security tools (Wazuh agent), allows inbound from attack subnet (for controlled testing)
- **Attack NSG**: Allows outbound to endpoints subnet only, no direct access to security tools

---

## Component Architecture

### Tier 1: Detection & Collection

```
┌─────────────────────────────────────────────────┐
│                DETECTION LAYER                   │
├─────────────────────────────────────────────────┤
│                                                  │
│  Wazuh Agents (Endpoints)                       │
│  ├── Log Collection (syslog, Windows Events)    │
│  ├── File Integrity Monitoring (FIM)            │
│  ├── Vulnerability Detection                    │
│  └── Security Configuration Assessment (SCA)   │
│                                                  │
│  Suricata NIDS (Network)                        │
│  ├── Protocol Analysis                          │
│  ├── Signature-based Detection (ET Open rules)  │
│  └── JSON Alert Logging (eve.json)              │
│                                                  │
│  Prometheus Exporters (All VMs)                 │
│  ├── Node Exporter (system metrics)             │
│  └── Custom exporters (service health)          │
│                                                  │
└─────────────────────────────────────────────────┘
```

### Tier 2: Analysis & Correlation

```
┌─────────────────────────────────────────────────┐
│              ANALYSIS LAYER                      │
├─────────────────────────────────────────────────┤
│                                                  │
│  Wazuh Server (SIEM Core)                       │
│  ├── Wazuh Manager: Rule-based alert engine     │
│  ├── Wazuh Indexer: OpenSearch for data storage  │
│  └── Wazuh Dashboard: Web UI for visualization  │
│                                                  │
│  MISP (Threat Intelligence)                     │
│  ├── Public IOC feeds (CIRCL, abuse.ch)         │
│  ├── IOC matching against incoming alerts       │
│  └── Indicator sharing & correlation            │
│                                                  │
└─────────────────────────────────────────────────┘
```

### Tier 3: Response & Automation

```
┌─────────────────────────────────────────────────┐
│              RESPONSE LAYER                      │
├─────────────────────────────────────────────────┤
│                                                  │
│  The Hive (Incident Response)                   │
│  ├── Automated case creation from Wazuh alerts  │
│  ├── Case assignment & collaboration            │
│  └── Observable enrichment via MISP             │
│                                                  │
│  DFIR-IRIS (Digital Forensics)                  │
│  ├── Forensic artifact management               │
│  ├── Timeline analysis                          │
│  └── Evidence chain documentation               │
│                                                  │
│  Shuffle (SOAR)                                 │
│  ├── Automated playbooks                        │
│  ├── IOC submission to MISP                     │
│  └── Notification routing                       │
│                                                  │
└─────────────────────────────────────────────────┘
```

### Tier 4: Visualization & Notification

```
┌─────────────────────────────────────────────────┐
│          VISUALIZATION LAYER                     │
├─────────────────────────────────────────────────┤
│                                                  │
│  Grafana                                        │
│  ├── Security event dashboards (Wazuh data)     │
│  ├── System performance dashboards (Prometheus) │
│  └── Custom alerting rules                      │
│                                                  │
│  Slack / Discord / Telegram                     │
│  ├── Real-time high-severity alerts             │
│  ├── Shuffle workflow notifications             │
│  └── System health alerts                       │
│                                                  │
└─────────────────────────────────────────────────┘
```

---

## Data Flow Diagram

```
[Windows Endpoint]──┐                              ┌──[Slack]
  (Wazuh Agent)      │                              │
                     ▼                              │
[Linux Endpoint]───►[Wazuh Server]──►[Shuffle]──────┼──[Discord]
  (Wazuh Agent)      │     │          (SOAR)        │
                     │     │            │           └──[Telegram]
[Suricata NIDS]──────┘     │            │
  (eve.json)               │            ▼
                           │         [MISP]
                           │      (Threat Intel)
                           │            │
                           ▼            ▼
                      [The Hive]◄───────┘
                    (Case Management)
                           │
                           ▼
                      [DFIR-IRIS]
                     (Forensics)

[All VMs]──►[Prometheus]──►[Grafana]
 (Exporters)   (Metrics)   (Dashboards)
```

---

## Port Reference

| Service | Port | Protocol | Notes |
|:---|:---|:---|:---|
| Wazuh Dashboard | 443 | HTTPS | Web UI |
| Wazuh Manager | 1514 | TCP | Agent communication |
| Wazuh Manager | 1515 | TCP | Agent enrollment |
| Wazuh Indexer | 9200 | HTTPS | OpenSearch API |
| The Hive | 9000 | HTTP | Web UI |
| DFIR-IRIS | 8443 | HTTPS | Web UI |
| MISP | 443 | HTTPS | Web UI & API |
| Grafana | 3000 | HTTP | Web UI |
| Prometheus | 9090 | HTTP | Web UI & API |
| Shuffle | 3001 | HTTP | Web UI |
| Suricata | — | — | Passive monitoring (no listening port) |
| Node Exporter | 9100 | HTTP | Prometheus metrics |
