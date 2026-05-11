# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

---

## [1.0.0] - 2025-12-10

### 🎉 Initial Release — Complete SOC Home Lab

#### Added
- **Azure Infrastructure**: Virtual network with 3 segmented subnets (Security Tools, Endpoints, Attack)
- **Wazuh SIEM**: Full server stack (Indexer + Manager + Dashboard) with agent deployment
- **Suricata NIDS**: Network intrusion detection with custom Wazuh decoder integration
- **MISP**: Threat intelligence platform with public IOC feeds configured
- **The Hive**: Incident response platform with automated case creation from Wazuh alerts
- **DFIR-IRIS**: Digital forensics and case management platform
- **Shuffle**: SOAR workflows for alert triage, IOC enrichment, and notifications
- **Prometheus**: System and service metrics collection from all VMs
- **Grafana**: Visualization dashboards for security events and system performance
- **Real-time Alerting**: Slack, Discord, and Telegram notification integration
- **Attack Simulation**: Kali Linux VM with tested scenarios (SSH brute force, file modification, port scanning)
- **Documentation**: Complete installation, integration, and testing guides
- **Configuration Files**: All tool configs, docker-compose files, and custom rules

#### Validated
- End-to-end detection pipeline from attack → alert → case → response → notification
- SSH brute force detection via Wazuh agents
- File integrity monitoring (ransomware simulation)
- Network port scan detection via Suricata NIDS
- Automated workflow execution via Shuffle SOAR
- Real-time notification delivery to messaging platforms

---

## [0.1.0] - 2025-05-01

### 🏁 Project Kickoff

#### Added
- Initial project planning and literature review
- Azure subscription setup
- Architecture design documentation
