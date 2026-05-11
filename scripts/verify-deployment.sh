#!/bin/bash
# ============================================================
# Deployment Verification Script
# SOC Home Lab — Post-Deployment Health Checks
# 
# Run this after deployment to verify all services are working
# Usage: ./verify-deployment.sh
# ============================================================

set -euo pipefail

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Tracking
PASSED=0
FAILED=0
WARNINGS=0

# ============================================================
# UTILITY FUNCTIONS
# ============================================================

check_pass() {
    echo -e "${GREEN}✓ PASS${NC}: $*"
    ((PASSED++))
}

check_fail() {
    echo -e "${RED}✗ FAIL${NC}: $*"
    ((FAILED++))
}

check_warn() {
    echo -e "${YELLOW}⚠ WARN${NC}: $*"
    ((WARNINGS++))
}

print_header() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$*${NC}"
    echo -e "${BLUE}========================================${NC}"
}

# ============================================================
# CHECKS
# ============================================================

check_azure_resources() {
    print_header "Azure Infrastructure"
    
    # Check if we're running on Azure (optional)
    if [[ -f /opt/waagent/HostingEnvironmentConfig.xml ]]; then
        check_pass "Running on Azure VM"
    fi
    
    # Check network connectivity
    if ping -c 1 8.8.8.8 &> /dev/null; then
        check_pass "Internet connectivity"
    else
        check_fail "No internet connectivity"
    fi
}

check_wazuh() {
    print_header "Wazuh SIEM"
    
    # Check Wazuh Manager
    if docker ps 2>/dev/null | grep -q "wazuh-manager"; then
        check_pass "Wazuh Manager container running"
    else
        check_fail "Wazuh Manager container not running"
        return 1
    fi
    
    # Check Wazuh Indexer
    if docker ps 2>/dev/null | grep -q "wazuh-indexer"; then
        check_pass "Wazuh Indexer container running"
    else
        check_fail "Wazuh Indexer container not running"
    fi
    
    # Check Wazuh Dashboard
    if docker ps 2>/dev/null | grep -q "wazuh-dashboard"; then
        check_pass "Wazuh Dashboard container running"
    else
        check_fail "Wazuh Dashboard container not running"
    fi
    
    # Test Wazuh API
    if timeout 5 curl -s -k https://localhost:55000/ping > /dev/null 2>&1; then
        check_pass "Wazuh API responding"
    else
        check_warn "Wazuh API not responding (may still be starting)"
    fi
}

check_misp() {
    print_header "MISP Threat Intelligence"
    
    if docker ps 2>/dev/null | grep -q "misp"; then
        check_pass "MISP container running"
    else
        check_fail "MISP container not running"
        return 1
    fi
    
    # Test MISP connectivity
    if timeout 5 curl -s http://localhost:80 > /dev/null 2>&1; then
        check_pass "MISP web interface responding"
    else
        check_warn "MISP web interface not responding"
    fi
}

check_thehive() {
    print_header "The Hive Incident Response"
    
    if docker ps 2>/dev/null | grep -q "thehive"; then
        check_pass "The Hive container running"
    else
        check_fail "The Hive container not running"
        return 1
    fi
    
    # Test The Hive API
    if timeout 5 curl -s http://localhost:9000/api/status > /dev/null 2>&1; then
        check_pass "The Hive API responding"
    else
        check_warn "The Hive API not responding"
    fi
}

check_dfir_iris() {
    print_header "DFIR-IRIS Forensics"
    
    if docker ps 2>/dev/null | grep -q "iris"; then
        check_pass "DFIR-IRIS container running"
    else
        check_fail "DFIR-IRIS container not running"
        return 1
    fi
    
    # Test IRIS
    if timeout 5 curl -s -k https://localhost:8443 > /dev/null 2>&1; then
        check_pass "DFIR-IRIS web interface responding"
    else
        check_warn "DFIR-IRIS web interface not responding"
    fi
}

check_shuffle() {
    print_header "Shuffle SOAR"
    
    if docker ps 2>/dev/null | grep -q "shuffle"; then
        check_pass "Shuffle container running"
    else
        check_fail "Shuffle container not running"
        return 1
    fi
    
    # Test Shuffle
    if timeout 5 curl -s http://localhost:3001 > /dev/null 2>&1; then
        check_pass "Shuffle web interface responding"
    else
        check_warn "Shuffle web interface not responding"
    fi
}

check_suricata() {
    print_header "Suricata NIDS"
    
    if docker ps 2>/dev/null | grep -q "suricata"; then
        check_pass "Suricata container running"
    else
        check_warn "Suricata container not running (may not be deployed)"
    fi
    
    # Check suricata logs
    if [[ -f /var/log/suricata/eve.json ]]; then
        check_pass "Suricata eve.json log file exists"
    else
        check_warn "Suricata eve.json not found"
    fi
}

check_monitoring() {
    print_header "Prometheus & Grafana"
    
    if docker ps 2>/dev/null | grep -q "prometheus"; then
        check_pass "Prometheus container running"
    else
        check_warn "Prometheus container not running"
    fi
    
    if docker ps 2>/dev/null | grep -q "grafana"; then
        check_pass "Grafana container running"
    else
        check_warn "Grafana container not running"
    fi
    
    # Test Prometheus
    if timeout 5 curl -s http://localhost:9090/-/healthy > /dev/null 2>&1; then
        check_pass "Prometheus responding"
    else
        check_warn "Prometheus not responding"
    fi
    
    # Test Grafana
    if timeout 5 curl -s http://localhost:3000/api/health > /dev/null 2>&1; then
        check_pass "Grafana responding"
    else
        check_warn "Grafana not responding"
    fi
}

check_docker_resources() {
    print_header "Docker Container Resources"
    
    if ! command -v docker &> /dev/null; then
        check_warn "Docker not installed"
        return
    fi
    
    # Check disk space
    local disk_usage=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
    if [[ $disk_usage -lt 80 ]]; then
        check_pass "Disk usage: ${disk_usage}%"
    else
        check_fail "High disk usage: ${disk_usage}%"
    fi
    
    # Check Docker daemon
    if docker ps > /dev/null 2>&1; then
        check_pass "Docker daemon running"
    else
        check_fail "Docker daemon not responding"
    fi
    
    # Count running containers
    local container_count=$(docker ps -q 2>/dev/null | wc -l)
    echo -e "${BLUE}Running containers: ${container_count}${NC}"
}

check_integrations() {
    print_header "Service Integrations"
    
    # Check Wazuh config for integrations
    if [[ -f /var/ossec/etc/ossec.conf ]]; then
        if grep -q "custom-thehive" /var/ossec/etc/ossec.conf 2>/dev/null; then
            check_pass "Wazuh → The Hive integration configured"
        else
            check_warn "Wazuh → The Hive integration not found"
        fi
        
        if grep -q "custom-shuffle" /var/ossec/etc/ossec.conf 2>/dev/null; then
            check_pass "Wazuh → Shuffle integration configured"
        else
            check_warn "Wazuh → Shuffle integration not found"
        fi
    fi
}

check_security() {
    print_header "Security Checks"
    
    # Check if running as root (not ideal)
    if [[ $EUID -eq 0 ]]; then
        check_warn "Script running as root"
    else
        check_pass "Running with normal user privileges"
    fi
    
    # Check SSH is accessible
    if [[ -S /var/run/docker.sock ]]; then
        check_pass "Docker socket accessible"
    else
        check_warn "Docker socket not found"
    fi
    
    # Check firewall status (if applicable)
    if command -v ufw &> /dev/null; then
        if sudo ufw status | grep -q "active"; then
            check_pass "UFW firewall active"
        else
            check_warn "UFW firewall not active"
        fi
    fi
}

print_summary() {
    print_header "Verification Summary"
    
    echo -e "${GREEN}Passed:  $PASSED${NC}"
    echo -e "${RED}Failed:  $FAILED${NC}"
    echo -e "${YELLOW}Warnings: $WARNINGS${NC}"
    
    if [[ $FAILED -eq 0 ]]; then
        echo ""
        echo -e "${GREEN}✓ All critical checks passed!${NC}"
        return 0
    else
        echo ""
        echo -e "${RED}✗ $FAILED checks failed. Review above for details.${NC}"
        return 1
    fi
}

# ============================================================
# MAIN
# ============================================================

main() {
    echo -e "${BLUE}"
    echo "╔═════════════════════════════════════════════════╗"
    echo "║   SOC Home Lab — Deployment Verification       ║"
    echo "║   Timestamp: $(date '+%Y-%m-%d %H:%M:%S')         ║"
    echo "╚═════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    check_azure_resources
    check_wazuh
    check_misp
    check_thehive
    check_dfir_iris
    check_shuffle
    check_suricata
    check_monitoring
    check_docker_resources
    check_integrations
    check_security
    
    print_summary
}

main "$@"
