# BEST PRACTICES & CODE IMPROVEMENTS GUIDE

## 🎯 Project Summary

**Current State**: Excellent foundational project (A-/90%)
**Target State**: Production-ready enterprise system (A+/95%+)

This document guides implementation of critical improvements to transform this into a world-class final year project.

---

## 🔐 SECURITY BEST PRACTICES

### 1. Secrets Management

#### ❌ BEFORE: Hardcoded Credentials
```bash
THEHIVE_API_KEY="YOUR_THEHIVE_API_KEY"  # Visible in code!
MISP_API_KEY="YOUR_MISP_API_KEY"        # Committed to Git!
```

#### ✅ AFTER: Environment-Based Secrets
```bash
# .env.local (gitignored)
export THEHIVE_API_KEY="${THEHIVE_API_KEY:?Error: Set THEHIVE_API_KEY}"

# Usage in scripts
echo "Connecting with key: ${THEHIVE_API_KEY}"

# For Docker
# docker-compose.yml
environment:
  - THEHIVE_API_KEY=${THEHIVE_API_KEY}

# .env file for Docker
THEHIVE_API_KEY=your_key_here
```

#### ✅ ADVANCED: Azure Key Vault
```bash
# Retrieve secrets from Azure Key Vault
THEHIVE_API_KEY=$(az keyvault secret show \
  --vault-name soc-lab-vault \
  --name thehive-api-key \
  --query value -o tsv)
```

---

### 2. Input Validation

#### ❌ BEFORE: No Validation
```bash
az group create --name "$RESOURCE_GROUP"  # What if invalid?
curl http://${THEHIVE_IP}:${THEHIVE_PORT}/api  # Unvalidated IPs
```

#### ✅ AFTER: Comprehensive Validation
```bash
validate_resource_group_name() {
    local name="$1"
    
    # Validation rules for Azure resource groups:
    # - 1-90 characters
    # - Alphanumerics, hyphens, underscores, and periods
    # - Case-insensitive
    if ! [[ "$name" =~ ^[a-zA-Z0-9_.-]{1,90}$ ]]; then
        echo "Invalid resource group name: $name" >&2
        return 1
    fi
}

validate_ip_address() {
    local ip="$1"
    
    if ! [[ "$ip" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        echo "Invalid IP address: $ip" >&2
        return 1
    fi
    
    # Validate octets are 0-255
    IFS='.' read -ra OCTETS <<< "$ip"
    for octet in "${OCTETS[@]}"; do
        if ((octet > 255)); then
            echo "Invalid IP address: $ip" >&2
            return 1
        fi
    done
}

validate_api_key_format() {
    local key="$1"
    
    if [[ -z "$key" ]] || [[ ${#key} -lt 10 ]]; then
        echo "Invalid API key format" >&2
        return 1
    fi
}
```

---

### 3. Error Handling

#### ❌ BEFORE: Silent Failures
```bash
sudo systemctl restart wazuh-manager
echo "Done!"  # What if restart failed?
```

#### ✅ AFTER: Proper Error Handling
```bash
#!/bin/bash
set -euo pipefail  # Exit on error, undefined vars, pipe failures

trap 'handle_error $? $LINENO' ERR

handle_error() {
    local exit_code=$1
    local line_num=$2
    echo "Error at line $line_num: Command failed with exit code $exit_code" >&2
    cleanup_on_error
    exit 1
}

cleanup_on_error() {
    # Rollback changes, cleanup temp files, etc.
    if [[ -n "${BACKUP_FILE:-}" ]] && [[ -f "$BACKUP_FILE" ]]; then
        sudo cp "$BACKUP_FILE" "/var/ossec/etc/ossec.conf"
        echo "Configuration rolled back to: $BACKUP_FILE"
    fi
}

restart_wazuh() {
    local max_attempts=3
    local attempt=1
    
    while ((attempt <= max_attempts)); do
        if sudo systemctl restart wazuh-manager 2>&1; then
            sleep 2
            if sudo systemctl is-active --quiet wazuh-manager; then
                echo "✓ Wazuh Manager restarted successfully"
                return 0
            fi
        fi
        
        echo "Attempt $attempt/$max_attempts failed, retrying..."
        ((attempt++))
        sleep 5
    done
    
    echo "Error: Failed to restart Wazuh after $max_attempts attempts" >&2
    return 1
}
```

---

## 📝 CODE QUALITY IMPROVEMENTS

### 1. Logging & Observability

#### ❌ BEFORE: No Logging
```bash
echo "Starting deployment..."
# No way to debug failures later
```

#### ✅ AFTER: Comprehensive Logging
```bash
setup_logging() {
    local log_dir="${LOG_DIR:-.}"
    local timestamp=$(date +%Y%m%d-%H%M%S)
    
    LOG_FILE="${log_dir}/deployment-${timestamp}.log"
    
    # Redirect all output
    exec 1> >(tee -a "$LOG_FILE")
    exec 2>&1
    
    # Log system info
    {
        echo "=== Deployment Started: $(date) ==="
        echo "Script: $0"
        echo "User: $(whoami)"
        echo "Host: $(hostname)"
        echo "OS: $(uname -s)"
        echo "Bash version: ${BASH_VERSION}"
        echo "========================================"
    } >> "$LOG_FILE"
}

log_info() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] $*"
}

log_error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] $*" >&2
}

log_debug() {
    if [[ "${DEBUG_MODE:-false}" == "true" ]]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [DEBUG] $*"
    fi
}
```

---

### 2. Idempotency

#### ❌ BEFORE: Not Idempotent
```bash
# Running this twice will fail (duplicates or errors)
az network nsg create --resource-group soc-lab-rg --name security-tools-nsg
az network nsg create --resource-group soc-lab-rg --name security-tools-nsg  # ERROR!
```

#### ✅ AFTER: Idempotent Operations
```bash
create_nsg_if_not_exists() {
    local rg="$1"
    local nsg="$2"
    
    if az network nsg show --resource-group "$rg" --name "$nsg" &> /dev/null; then
        log_info "NSG '$nsg' already exists, skipping"
        return 0
    fi
    
    log_info "Creating NSG '$nsg'"
    az network nsg create \
        --resource-group "$rg" \
        --name "$nsg" \
        --output none
}

# Safe to run multiple times
create_nsg_if_not_exists "soc-lab-rg" "security-tools-nsg"
create_nsg_if_not_exists "soc-lab-rg" "security-tools-nsg"  # Skips silently
```

---

### 3. Configuration Management

#### ❌ BEFORE: Inconsistent Configuration
```bash
# Manual config in each script
WAZUH_PORT="1514"
THEHIVE_PORT="9000"
MISP_PORT="443"
# Repeated in multiple places!
```

#### ✅ AFTER: Centralized Configuration
```bash
# config/defaults.sh
declare -r WAZUH_PORT="1514"
declare -r THEHIVE_PORT="9000"
declare -r MISP_PORT="443"

# config/azure.sh
declare -r RESOURCE_GROUP="${RESOURCE_GROUP:-soc-lab-rg}"
declare -r LOCATION="${LOCATION:-uksouth}"

# Usage in scripts
source "${SCRIPT_DIR}/config/defaults.sh"
source "${SCRIPT_DIR}/config/azure.sh"

# Now use: $WAZUH_PORT (prevents accidental modification)
```

---

### 4. Documentation in Code

#### ❌ BEFORE: Unclear Code
```bash
# Magic number - why 1514?
if nc -zv "$WAZUH_IP" 1514; then
    echo "OK"
fi
```

#### ✅ AFTER: Well-Documented Code
```bash
# Wazuh Manager default port for agent communication (Secure mode)
# This port must be open for agents to connect to the Wazuh manager
# See: https://documentation.wazuh.com/current/installation-guide/wazuh-server/
declare -r WAZUH_AGENT_PORT="1514"

if nc -zv "$WAZUH_IP" "$WAZUH_AGENT_PORT"; then
    log_success "Wazuh Manager accepting agent connections on port $WAZUH_AGENT_PORT"
else
    log_error "Cannot reach Wazuh Manager on port $WAZUH_AGENT_PORT"
fi
```

---

## 🐳 DOCKER BEST PRACTICES

### 1. Version Pinning

#### ❌ BEFORE: Latest Tags (Unpredictable)
```yaml
services:
  wazuh-indexer:
    image: wazuh/wazuh-indexer:latest  # ⚠️ Can break!
    
  postgres:
    image: postgres  # Even worse!
```

#### ✅ AFTER: Specific Versions
```yaml
services:
  wazuh-indexer:
    image: wazuh/wazuh-indexer:4.9.0  # ✓ Reproducible
    
  postgres:
    image: postgres:15-alpine  # ✓ Specific version
    
  iris-db:
    image: postgres:15-alpine  # ✓ Same version across environments
```

---

### 2. Health Checks

#### ❌ BEFORE: No Health Checks
```yaml
services:
  wazuh-manager:
    image: wazuh/wazuh:4.9.0
    # Container may appear running but service failing
```

#### ✅ AFTER: Health Checks Configured
```yaml
services:
  wazuh-manager:
    image: wazuh/wazuh:4.9.0
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:55000/ping"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s
    
  postgres:
    image: postgres:15-alpine
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 20s
```

---

### 3. Resource Limits

#### ❌ BEFORE: No Limits (Container can consume all resources)
```yaml
services:
  elasticsearch:
    image: wazuh/wazuh-indexer:4.9.0
    # Can use all available CPU/memory!
```

#### ✅ AFTER: Resource Constraints
```yaml
services:
  elasticsearch:
    image: wazuh/wazuh-indexer:4.9.0
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 4G
        reservations:
          cpus: '1.0'
          memory: 2G
    environment:
      - ES_JAVA_OPTS=-Xms2g -Xmx2g
```

---

## 📊 TESTING & VALIDATION

### 1. Pre-Deployment Checks

```bash
# scripts/pre-deploy-checks.sh
pre_deploy_validation() {
    local checks_passed=0
    local checks_total=0
    
    # Check 1: Azure CLI
    ((checks_total++))
    if command -v az &> /dev/null; then
        log_success "Azure CLI installed"
        ((checks_passed++))
    else
        log_error "Azure CLI not found"
    fi
    
    # Check 2: SSH key
    ((checks_total++))
    if [[ -f ~/.ssh/id_rsa ]]; then
        log_success "SSH key found"
        ((checks_passed++))
    else
        log_error "SSH key not found"
    fi
    
    # Check 3: Environment variables
    ((checks_total++))
    if [[ -f .env.local ]]; then
        log_success ".env.local found"
        ((checks_passed++))
    else
        log_error ".env.local not found - create from .env.template"
    fi
    
    # Report
    log_info "Pre-deployment validation: $checks_passed/$checks_total passed"
    [[ $checks_passed -eq $checks_total ]] && return 0 || return 1
}
```

---

### 2. Integration Tests

```bash
# tests/integration-tests.sh
test_alert_detection() {
    log_info "Testing alert detection pipeline..."
    
    # Trigger test event
    local test_event="SSH brute force test"
    log_info "  Triggering test attack: $test_event"
    
    # Simulate SSH brute force
    for i in {1..5}; do
        ssh -o ConnectTimeout=1 baduser@<endpoint-ip> 2>/dev/null || true
    done
    
    # Wait for alert
    sleep 10
    
    # Check if alert created in Wazuh
    local alert_count=$(curl -s -u "admin:$WAZUH_PASSWORD" \
        https://<wazuh-ip>:55000/security/events \
        | grep -c "SSH brute force" || true)
    
    if [[ $alert_count -gt 0 ]]; then
        log_success "Alert detection working (found $alert_count alerts)"
        return 0
    else
        log_error "Alert not detected"
        return 1
    fi
}
```

---

## 📈 MONITORING & METRICS

### 1. Key Performance Indicators (KPIs)

Create dashboard to track:
- **Detection**: Alerts per hour, detection accuracy
- **Response**: Mean time to create incident, mean time to resolve
- **Infrastructure**: CPU/memory usage, disk I/O, network throughput
- **Availability**: Service uptime, false positive rate

### 2. Custom Prometheus Metrics

```yaml
# prometheus/prometheus.yml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'wazuh-metrics'
    static_configs:
      - targets: ['<wazuh-ip>:9092']
    
  - job_name: 'node-exporter'
    static_configs:
      - targets: ['<vm-ip>:9100']
    
  - job_name: 'docker'
    static_configs:
      - targets: ['localhost:9323']
```

---

## 🚀 DEPLOYMENT AUTOMATION

### 1. Infrastructure as Code

Convert shell scripts to **Terraform**:

```hcl
# infrastructure/terraform/main.tf
resource "azurerm_resource_group" "soc_lab" {
  name     = var.resource_group_name
  location = var.location
  
  tags = {
    project     = "SOC-Home-Lab"
    environment = "lab"
    created_at  = timestamp()
  }
}

resource "azurerm_virtual_network" "soc_lab" {
  name                = var.vnet_name
  address_space       = [var.vnet_prefix]
  resource_group_name = azurerm_resource_group.soc_lab.name
  location            = azurerm_resource_group.soc_lab.location
}

# Benefits:
# ✓ Version control
# ✓ Reproducible deployments
# ✓ State management
# ✓ Easy rollback
```

---

## ✅ IMPLEMENTATION CHECKLIST

Priority implementation order:

### Phase 1: Security (Week 1)
- [ ] Move secrets to .env.local
- [ ] Add .gitignore
- [ ] Implement credential validation
- [ ] Add error handling with rollback

### Phase 2: Quality (Week 2)
- [ ] Add comprehensive logging
- [ ] Implement idempotency checks
- [ ] Create configuration files
- [ ] Add inline documentation

### Phase 3: Operations (Week 3)
- [ ] Create health check script
- [ ] Add integration tests
- [ ] Create verification script
- [ ] Setup monitoring dashboards

### Phase 4: Advanced (Week 4)
- [ ] Migrate to Terraform
- [ ] Add CI/CD pipeline
- [ ] Setup automated backups
- [ ] Add disaster recovery procedures

---

## 📚 FURTHER READING

- **Shell Scripting**: https://mywiki.wooledge.org/BashGuide
- **Docker Best Practices**: https://docs.docker.com/develop/dev-best-practices
- **Azure**: https://learn.microsoft.com/azure
- **DevOps**: https://www.atlassian.com/devops
- **Security**: https://cheatsheetseries.owasp.org

---

**Total Implementation Time**: 3-4 weeks
**Expected Outcome**: A+ Grade Project (95%+)
**Date**: May 2026
