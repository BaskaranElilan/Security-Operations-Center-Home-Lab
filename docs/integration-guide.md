# Integration Guide

> How to connect all SOC Home Lab components into a unified detection-response pipeline.

---

## Integration Overview

```
Wazuh ──API──► The Hive ──Webhook──► DFIR-IRIS
  │                │
  │                └──API──► MISP
  │
  └──Webhook──► Shuffle ──API──► MISP
                   │
                   └──Webhook──► Slack/Discord/Telegram
```

---

## 1. Wazuh → The Hive Integration

Automatically create incident cases in The Hive when Wazuh generates high-severity alerts.

### Configure Wazuh Integration

Edit `/var/ossec/etc/ossec.conf` on the Wazuh server:

```xml
<integration>
  <name>custom-thehive</name>
  <hook_url>http://<thehive-ip>:9000/api/alert</hook_url>
  <api_key>YOUR_THEHIVE_API_KEY</api_key>
  <level>10</level>
  <alert_format>json</alert_format>
</integration>
```

### Generate The Hive API Key

1. Login to The Hive → **Admin** → **Users**
2. Create a service account for Wazuh
3. Generate an API key and copy it to the Wazuh config

### Restart Wazuh

```bash
sudo systemctl restart wazuh-manager
```

---

## 2. The Hive → MISP Integration

Enrich incident cases with threat intelligence from MISP.

### Configure MISP in The Hive

1. Login to The Hive → **Admin** → **Platform Management**
2. Add MISP server:
   - **URL**: `https://<misp-ip>`
   - **API Key**: Your MISP automation key
   - **Purpose**: `ImportAndExport`

### Generate MISP API Key

1. Login to MISP → **Administration** → **Auth Keys**
2. Create a new key with appropriate permissions

---

## 3. The Hive → DFIR-IRIS Integration

Transfer case data and forensic artifacts between platforms.

### Webhook Configuration

1. In The Hive, configure a webhook notification to DFIR-IRIS
2. In DFIR-IRIS, configure The Hive as an external source
3. Map case fields between platforms

---

## 4. Shuffle SOAR Workflows

### Workflow 1: Alert Triage & Notification

```
Trigger: Wazuh Webhook (alert level >= 10)
    │
    ├── Step 1: Parse alert JSON
    ├── Step 2: Check severity level
    ├── Step 3: Query MISP for IOC matches
    ├── Step 4: Create case in The Hive (if confirmed threat)
    └── Step 5: Send notification to Slack/Discord
```

### Workflow 2: IOC Enrichment

```
Trigger: New observable in The Hive
    │
    ├── Step 1: Extract observable value (IP, hash, domain)
    ├── Step 2: Query MISP for matching indicators
    ├── Step 3: Update observable with MISP tags
    └── Step 4: Add enrichment report to case
```

### Configure Wazuh Webhook in Shuffle

1. In Shuffle, create a new workflow with **Webhook** trigger
2. Copy the webhook URL
3. Add to Wazuh's `ossec.conf`:

```xml
<integration>
  <name>custom-shuffle</name>
  <hook_url>http://<shuffle-ip>:3001/api/v1/hooks/<webhook-id></hook_url>
  <level>8</level>
  <alert_format>json</alert_format>
</integration>
```

---

## 5. Suricata → Wazuh Integration

Wazuh processes Suricata alerts by reading the `eve.json` log file.

### On the Suricata VM (Wazuh Agent)

Ensure the Wazuh agent monitors Suricata's output:

```xml
<!-- In /var/ossec/etc/ossec.conf on the Suricata VM -->
<localfile>
  <log_format>json</log_format>
  <location>/var/log/suricata/eve.json</location>
</localfile>
```

### On the Wazuh Server

The custom decoder (`local_decoder.xml`) and rules (`local_rules.xml`) in the `configs/wazuh/` directory handle Suricata alert parsing. See those files for details.

---

## 6. Prometheus → Grafana Integration

### Add Prometheus Data Source in Grafana

1. Login to Grafana → **Configuration** → **Data Sources**
2. Add **Prometheus**:
   - URL: `http://localhost:9090`
   - Access: `Server`

### Add Wazuh/OpenSearch Data Source

1. Add **OpenSearch** data source:
   - URL: `https://<wazuh-server-ip>:9200`
   - Auth: Basic (use Wazuh indexer credentials)
   - Index: `wazuh-alerts-*`

---

## 7. Notification Channel Setup

### Slack

```
Shuffle → HTTP Node → POST https://hooks.slack.com/services/YOUR/WEBHOOK/URL
Headers: Content-Type: application/json
Body: {"text": "🚨 Security Alert: {{alert.description}}"}
```

### Discord

```
Shuffle → HTTP Node → POST https://discord.com/api/webhooks/YOUR/WEBHOOK
Headers: Content-Type: application/json
Body: {"content": "🚨 Security Alert: {{alert.description}}"}
```

### Telegram

```
Shuffle → HTTP Node → POST https://api.telegram.org/bot<TOKEN>/sendMessage
Body: {"chat_id": "YOUR_CHAT_ID", "text": "🚨 Alert: {{alert.description}}"}
```

---

## Verification

Test the full integration chain:

1. Trigger a test alert on a monitored endpoint (e.g., failed SSH login)
2. Verify the alert appears in Wazuh Dashboard
3. Verify a case is created in The Hive
4. Verify MISP enrichment data is attached
5. Verify Shuffle workflow executed
6. Verify notification received in Slack/Discord/Telegram
7. Verify the event appears on Grafana dashboards
