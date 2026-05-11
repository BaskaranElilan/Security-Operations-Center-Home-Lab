# Testing Guide

> Attack simulation procedures and validation steps for the SOC Home Lab.

---

## Overview

Testing is performed from the **Kali Linux VM** (attack subnet: 10.0.3.0/24) against monitored endpoints in the endpoints subnet (10.0.2.0/24). All attacks are controlled simulations for educational purposes only.

---

## Prerequisites

- Kali Linux VM provisioned and accessible
- Wazuh agents running on all endpoint VMs
- Suricata NIDS active and monitoring traffic
- All integrations configured (see [Integration Guide](integration-guide.md))

---

## Test 1: SSH Brute Force Detection

### Attack (from Kali)

```bash
# Using Hydra for SSH brute force
hydra -l admin -P /usr/share/wordlists/rockyou.txt \
  ssh://<linux-endpoint-ip> -t 4 -V
```

### Expected Detection

| Component | Expected Behavior |
|:---|:---|
| Wazuh Agent | Detects multiple failed SSH attempts (Rule 5710, 5712) |
| Wazuh Server | Generates high-severity alert |
| The Hive | Auto-creates incident case |
| Shuffle | Sends notification to Slack/Discord |

### Verification

1. Check Wazuh Dashboard → **Security Events** → filter by `rule.id: 5710`
2. Check The Hive for new case
3. Check Slack/Discord for alert notification

---

## Test 2: File Integrity Monitoring (Ransomware Simulation)

### Attack (on target endpoint)

```bash
# Create and modify monitored files
echo "test malware content" > /tmp/test_malware.txt
echo "modified" >> /etc/hosts
touch /var/log/suspicious_file.exe
```

### Expected Detection

| Component | Expected Behavior |
|:---|:---|
| Wazuh FIM | Detects file creation/modification in monitored paths |
| Wazuh Server | Generates FIM alert (Rule 550-554) |
| The Hive | Case created with file details |

---

## Test 3: Port Scanning Detection

### Attack (from Kali)

```bash
# Nmap SYN scan
nmap -sS -p 1-1000 <endpoint-ip>

# Aggressive scan
nmap -A -T4 <endpoint-ip>

# Full port scan
nmap -p- <endpoint-ip>
```

### Expected Detection

| Component | Expected Behavior |
|:---|:---|
| Suricata | Detects port scan patterns |
| Wazuh | Correlates Suricata alerts with custom rules |
| Grafana | Spike visible on network events dashboard |

---

## Test 4: Exploit Attempt Detection

### Attack (from Kali)

```bash
# Example: Metasploit SSH exploit attempt
msfconsole
use auxiliary/scanner/ssh/ssh_login
set RHOSTS <endpoint-ip>
set USERNAME admin
set PASS_FILE /usr/share/wordlists/rockyou.txt
run
```

### Expected Detection

| Component | Expected Behavior |
|:---|:---|
| Suricata | Detects exploit signatures |
| Wazuh | Correlated alert from agent + Suricata |
| The Hive | Escalated case with enriched IOCs |
| MISP | Known malicious IP/hash match |

---

## Automated Test Suite

Run all tests automatically:

```bash
chmod +x scripts/attack-simulation.sh
./scripts/attack-simulation.sh <target-ip>
```

---

## End-to-End Validation Checklist

After running all tests, verify:

- [ ] Wazuh Dashboard shows alerts for all attack types
- [ ] Suricata detected network-based attacks
- [ ] Cases created in The Hive with correct severity
- [ ] MISP enrichment data attached to cases
- [ ] DFIR-IRIS cases populated
- [ ] Shuffle workflows executed successfully
- [ ] Notifications received in Slack/Discord/Telegram
- [ ] Grafana dashboards reflect attack events
- [ ] Alert-to-notification latency is acceptable (< 60 seconds)

---

## Clean Up

After testing, reset the environment:

```bash
# Clear test files on endpoints
rm -f /tmp/test_malware.txt
# Restore modified files
# Review and close test cases in The Hive
```
