# MAINTENANCE & OPERATIONS GUIDE

## 📅 Regular Maintenance Schedule

### Daily Tasks (Automated)
- ✅ Monitoring dashboards check (Grafana)
- ✅ Alert review in Wazuh
- ✅ System log rotation
- ✅ Database maintenance

### Weekly Tasks
- [ ] **Monday**: Review security alerts from past week
- [ ] **Wednesday**: Check system resources and disk usage
- [ ] **Friday**: Update threat intelligence feeds
  ```bash
  # SSH to MISP server and update feeds
  ssh azureuser@<misp-ip>
  cd /var/www/MISP
  sudo ./app/Console/cake Admin updateGalaxies
  ```

### Monthly Tasks
- [ ] Review and optimize Azure costs
- [ ] Audit NSG rules and update if needed
- [ ] Update all threat intelligence data
- [ ] Backup critical configurations
- [ ] Review user access and permissions
- [ ] Security patches assessment

### Quarterly Tasks
- [ ] Full system security audit
- [ ] Disaster recovery drill
- [ ] Performance baseline review
- [ ] Capacity planning review
- [ ] Tool version update assessment

### Annually
- [ ] Complete security audit
- [ ] Certificate renewal (if using real certs)
- [ ] Disaster recovery plan review
- [ ] Vendor security updates assessment

---

## 🛡️ Security Maintenance

### Credential Rotation
**Every 90 days** - Rotate all credentials:

1. **Wazuh Admin Password**
   ```bash
   # SSH to Wazuh server
   ssh azureuser@<wazuh-ip>
   sudo /var/ossec/bin/wazuh-control stop
   # Use Wazuh installation tool to reset password
   sudo /var/ossec/bin/wazuh-user-manager.py -u admin -c /var/ossec/api/configuration
   sudo /var/ossec/bin/wazuh-control start
   ```

2. **The Hive Admin Password**
   ```bash
   ssh azureuser@<thehive-ip>
   # Use The Hive admin interface to reset
   ```

3. **Database Passwords**
   ```bash
   # Update .env.local with new passwords
   # Update docker-compose files
   # Restart affected containers
   docker-compose restart iris-db
   ```

4. **API Keys**
   - Regenerate in each service dashboard
   - Update integration scripts
   - Test integrations after change

### Firewall Rules Audit
**Monthly** - Review NSG rules:

```bash
# List all NSG rules
az network nsg rule list \
  --resource-group soc-lab-rg \
  --nsg-name security-tools-nsg \
  --output table

# Restrict to specific IP if possible
ADMIN_IP="203.0.113.42"
az network nsg rule update \
  --resource-group soc-lab-rg \
  --nsg-name security-tools-nsg \
  --name "AllowSSH" \
  --source-address-prefixes "$ADMIN_IP" \
  --output none
```

### SSL/TLS Certificate Management
**60 days before expiry** - Renew certificates:

```bash
# Check certificate expiry
openssl x509 -enddate -noout -in /etc/ssl/certs/soc-lab.crt

# For production, use Let's Encrypt
sudo apt-get install certbot
sudo certbot renew
```

---

## 📊 Performance Optimization

### Monitor System Metrics
```bash
# SSH to each VM and check
ssh azureuser@<vm-ip>

# Check CPU usage
top -b -n 1 | head -20

# Check memory
free -h

# Check disk
df -h

# Check network
ifstat
```

### Grafana Dashboard Insights
- Monitor CPU utilization trends
- Check memory usage patterns
- Review disk I/O patterns
- Monitor network traffic

### Optimization Steps
1. **CPU High**: Upgrade VM size or optimize Elasticsearch queries
2. **Memory High**: Increase VM RAM or adjust service heap sizes
3. **Disk High**: Clean old logs, reduce retention, upgrade storage
4. **Network High**: Review data ingestion rates, optimize agent filtering

### Database Maintenance
```bash
# PostgreSQL (The Hive, DFIR-IRIS)
docker exec iris-db vacuumdb -U iris -d iris_db
docker exec iris-db analyzedb -U iris -d iris_db

# OpenSearch (Wazuh Indexer)
# Use Wazuh API to optimize indices
curl -X POST "https://localhost:9200/_all/_forcemerge?max_num_segments=1"
```

---

## 🔧 Troubleshooting Guide

### Issue: High Disk Usage

**Symptoms**: Disk usage > 85%, services failing

**Solution**:
```bash
# Find large files/directories
du -sh /* | sort -rh | head -10

# Check old logs
find /var/log -type f -name "*.log" -mtime +30 -delete

# Clean Docker
docker system prune -a

# Check database sizes
docker exec wazuh-indexer curl -s http://localhost:9200/_cat/indices?h=index,store.size | sort -k2 -h
```

### Issue: Wazuh Agent Not Connecting

**Symptoms**: Red status in Wazuh dashboard, no agent alerts

**Solution**:
```bash
# SSH to Wazuh server
ssh azureuser@<wazuh-ip>

# Check Wazuh manager
sudo systemctl status wazuh-manager
sudo systemctl restart wazuh-manager

# Check manager logs
tail -f /var/ossec/logs/ossec.log | grep agent

# Check agent logs (on agent machine)
tail -f /var/ossec/logs/ossec.log | grep "agentd"

# Verify port 1514 is open
sudo netstat -tlnp | grep 1514

# SSH to agent and restart
ssh azureuser@<agent-ip>
sudo systemctl restart wazuh-agent
```

### Issue: The Hive Slow or Unresponsive

**Symptoms**: The Hive dashboard slow, timeouts

**Solution**:
```bash
# Check container
docker ps | grep thehive

# Check logs
docker logs thehive | tail -50

# Restart container
docker restart thehive

# Check database
docker logs iris-db

# Increase resources (if needed)
# Update docker-compose.yml mem_limit
docker-compose up -d iris-db
```

### Issue: Integration Not Working (Wazuh → The Hive)

**Symptoms**: Alerts not creating cases in The Hive

**Solution**:
```bash
# Verify integration config
sudo grep -A5 "custom-thehive" /var/ossec/etc/ossec.conf

# Test API connectivity
curl -v -X POST \
  -H "Authorization: Bearer $THEHIVE_API_KEY" \
  http://<thehive-ip>:9000/api/alert

# Check Wazuh logs for errors
tail -f /var/ossec/logs/integration.log

# Restart integration
sudo systemctl restart wazuh-manager
```

### Issue: Shuffle Webhook Not Triggering

**Symptoms**: Alerts not flowing to Shuffle

**Solution**:
```bash
# Check Wazuh integration config
grep -A5 "custom-shuffle" /var/ossec/etc/ossec.conf

# Test webhook
curl -X POST http://<shuffle-ip>:3001/api/v1/hooks/<webhook-id> \
  -H "Content-Type: application/json" \
  -d '{"test": "data"}'

# Check Shuffle logs
docker logs shuffle | tail -100

# Verify Shuffle is running
docker ps | grep shuffle
```

### Issue: Low Memory/Container Crashes

**Symptoms**: Container killed, OOMKilled errors

**Solution**:
```bash
# Check memory pressure
free -h

# Check container memory limits
docker stats

# Check if out-of-memory
docker inspect <container> | grep -A10 "State"

# Increase VM size in Azure
az vm resize --resource-group soc-lab-rg --name <vm-name> --size Standard_D2s_v3

# Or increase container memory limit
# Edit docker-compose.yml:
# services:
#   container_name:
#     mem_limit: 4g
```

### Issue: Network Connectivity Issues

**Symptoms**: Cannot reach services, timeouts

**Solution**:
```bash
# Check NSG rules
az network nsg rule list --resource-group soc-lab-rg --nsg-name security-tools-nsg

# Test port connectivity
nc -zv <ip> <port>

# Check route tables
ip route show

# Check DNS
nslookup 8.8.8.8

# Check firewall on VM
sudo ufw status

# Test service port directly
curl -v http://localhost:9000  # The Hive
curl -v http://localhost:3001  # Shuffle
```

### Issue: Failed Deployment

**Symptoms**: Deploy script fails at step X

**Solution**:
```bash
# Check logs
cat deployment_*.log | tail -100

# Check Azure resource group
az group show --name soc-lab-rg

# Clean up failed resources (careful!)
az group delete --name soc-lab-rg --yes

# Or delete specific resources
az vm delete --resource-group soc-lab-rg --name <vm-name> --yes

# Re-run deployment
./infrastructure/azure/deploy.sh
```

---

## 🔄 Backup & Disaster Recovery

### Create Backups
```bash
# Database backups
docker exec iris-db pg_dump -U iris iris_db > iris_backup_$(date +%Y%m%d).sql

# Configuration backups
tar czf configs_backup_$(date +%Y%m%d).tar.gz configs/

# VM snapshots (via Azure Portal or CLI)
az snapshot create \
  --resource-group soc-lab-rg \
  --source <vm-disk-id> \
  --name backup-$(date +%Y%m%d)
```

### Restore from Backup
```bash
# Restore database
docker exec -i iris-db psql -U iris iris_db < iris_backup_20240101.sql

# Restore configs
tar xzf configs_backup_20240101.tar.gz

# Restore VM from snapshot
# Use Azure Portal Disk → Create VM
```

---

## 📈 Scaling & Capacity Planning

### Signs You Need to Scale
- Disk usage consistently > 80%
- CPU usage consistently > 70%
- Memory usage consistently > 75%
- Response times increasing
- Alert volume exceeding processing capacity

### Scaling Options

1. **Vertical Scaling** (increase VM size)
   ```bash
   az vm resize --resource-group soc-lab-rg --name wazuh-server --size Standard_D4s_v3
   ```

2. **Horizontal Scaling** (add more VMs)
   - Add more agents
   - Deploy Wazuh cluster
   - Add redundant services

3. **Storage Scaling**
   - Increase disk size
   - Archive old indices
   - Use external storage

### Capacity Planning
- **Agents**: 1 Wazuh manager per 50-100 agents
- **Storage**: ~500MB per agent per day
- **Network**: Plan for peak bandwidth
- **CPU/Memory**: Monitor and scale based on usage

---

## 📝 Documentation & Runbooks

### Keep Updated
- VM IP addresses and access methods
- Generated credentials (in secure location)
- Integration details and API keys
- Backup locations and restore procedures
- Contact information for vendors/support

### Incident Response
Create runbooks for:
- [ ] Security incident detection
- [ ] False positive handling
- [ ] Service failure recovery
- [ ] Data breach response
- [ ] Compliance reporting

---

## ✅ Health Check Script

Run weekly to verify all systems:
```bash
./scripts/verify-deployment.sh
```

---

**Last Updated**: May 2026
**Maintained By**: SOC Operations Team
