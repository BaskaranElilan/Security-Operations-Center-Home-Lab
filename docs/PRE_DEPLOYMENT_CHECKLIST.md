# Pre-Deployment Checklist

## 📋 Pre-Deployment Requirements

### Azure Account & CLI Setup
- [ ] Azure subscription created (free tier or Pay-As-You-Go)
- [ ] Azure CLI installed (`az --version` confirms)
- [ ] Logged into Azure (`az login` completed)
- [ ] Default subscription set (`az account set --subscription <name>`)
- [ ] Sufficient quota verified in target region
  - [ ] Compute cores available (min 20 vCPUs recommended)
  - [ ] Storage quota available (min 500GB)
  - [ ] Network quota verified

### SSH & Local Setup
- [ ] SSH key pair generated (`ssh-keygen -t rsa -b 4096`)
- [ ] SSH public key available (`~/.ssh/id_rsa.pub`)
- [ ] SSH private key permissions set correctly (`chmod 600 ~/.ssh/id_rsa`)
- [ ] SSH client installed and working

### Environment Configuration
- [ ] `.env.template` copied to `.env.local`
- [ ] `.env.local` file permissions restricted (`chmod 600 .env.local`)
- [ ] All required credentials filled in `.env.local`:
  - [ ] THEHIVE_API_KEY set (or will generate post-deployment)
  - [ ] MISP_API_KEY set (or will generate post-deployment)
  - [ ] SHUFFLE_WEBHOOK_ID set (or will generate post-deployment)
  - [ ] All passwords changed from defaults
- [ ] `.env.local` added to `.gitignore` (verify with `git check-ignore .env.local`)
- [ ] No credentials in `.env` (template only)

### Networking & Firewall
- [ ] Determine your public IP address (`curl https://checkip.amazonaws.com`)
- [ ] Update `ADMIN_SOURCE_IPS` in `.env.local` (restrict to your IP for security)
- [ ] Verify firewall/corporate proxy won't block Azure access
- [ ] Note required ports for notifications:
  - [ ] Slack webhook access (HTTPS)
  - [ ] Discord webhook access (HTTPS)
  - [ ] Telegram API access (HTTPS)

### Third-Party Integrations
- [ ] Slack workspace created (or use existing)
  - [ ] Slack webhook URL generated (`SLACK_WEBHOOK_URL`)
  - [ ] Test channel created (`#soc-alerts`)
- [ ] Discord server created (optional)
  - [ ] Discord webhook URL generated (`DISCORD_WEBHOOK_URL`)
- [ ] Telegram bot created (optional)
  - [ ] Bot token obtained (`TELEGRAM_BOT_TOKEN`)
  - [ ] Chat ID obtained (`TELEGRAM_CHAT_ID`)

### Local Tools & Dependencies
- [ ] Docker Desktop installed (if using Docker locally for testing)
- [ ] Git installed (`git --version` confirms)
- [ ] Basic networking tools available:
  - [ ] `curl` or `wget` installed
  - [ ] `ping` command available
  - [ ] `telnet` or `nc` (netcat) available
- [ ] Text editor/IDE ready
- [ ] Terminal/shell configured
  - [ ] bash 4.0+ (`bash --version`)
  - [ ] Supports color output

### Documentation & Knowledge
- [ ] Project README.md reviewed
- [ ] Architecture documentation read and understood
- [ ] Installation guide reviewed
- [ ] Integration guide reviewed
- [ ] Testing guide reviewed
- [ ] Familiar with basic Azure concepts:
  - [ ] Resource Groups
  - [ ] Virtual Networks & Subnets
  - [ ] Network Security Groups (NSGs)
  - [ ] Virtual Machines

### Project Files & Scripts
- [ ] All script files are present:
  - [ ] `infrastructure/azure/deploy.sh`
  - [ ] `scripts/setup-integrations.sh` (or improved version)
  - [ ] `scripts/verify-deployment.sh`
- [ ] Script files are executable:
  ```bash
  chmod +x infrastructure/azure/deploy.sh
  chmod +x scripts/*.sh
  ```
- [ ] All docker-compose.yml files present and valid:
  ```bash
  for f in configs/*/docker-compose.yml; do
    docker-compose -f "$f" config > /dev/null && echo "✓ $f" || echo "✗ $f"
  done
  ```

### Security & Compliance
- [ ] `.env.local` secured (not world-readable)
- [ ] Passwords reviewed and changed from defaults
- [ ] SSH keys properly secured
- [ ] No credentials in code or documentation
- [ ] Understand security implications:
  - [ ] NSG rules understand
  - [ ] Public vs private IPs understand
  - [ ] Firewall whitelist understand

### Testing & Validation
- [ ] Azure CLI commands tested:
  ```bash
  az account show  # Should succeed
  az group list    # Should list groups
  ```
- [ ] Network connectivity verified:
  ```bash
  ping 8.8.8.8          # Internet access
  nslookup microsoft.com # DNS resolution
  ```
- [ ] Credentials validated (no typos)

### Documentation & Backups
- [ ] Project code backed up (git push)
- [ ] Configuration backed up
- [ ] `.env.local` backed up separately (NOT in git)
- [ ] Documentation printed or saved locally
- [ ] Screenshots taken of `.env.local` structure (for reference)

### Stakeholder Communication
- [ ] Project supervisor/advisor notified of deployment
- [ ] Expected deployment time: **30-45 minutes**
- [ ] Know who to contact if issues arise
- [ ] Have support contact information ready

---

## 📝 During Deployment

### Monitor Deployment Progress
- [ ] Watch console output for any errors
- [ ] Keep Azure Portal tab open for resource monitoring
- [ ] Note any warnings or issues
- [ ] Take screenshots of any errors for documentation

### Key Milestones to Verify
1. [ ] **Step 1**: Resource Group created
2. [ ] **Step 2**: Virtual Network created with all subnets
3. [ ] **Step 3**: Network Security Groups created
4. [ ] **Step 4**: Virtual Machines provisioned (7 total)
5. [ ] **Step 5**: Wazuh stack deployed
6. [ ] **Step 6**: Other security tools deployed (MISP, The Hive, etc.)
7. [ ] **Step 7**: Integrations configured
8. [ ] **Step 8**: Verification checks pass

---

## ✅ Post-Deployment

### Immediate Actions
- [ ] Run deployment verification script:
  ```bash
  ./scripts/verify-deployment.sh
  ```
- [ ] Verify all containers are running:
  ```bash
  docker ps
  ```
- [ ] Test Wazuh Dashboard accessibility
- [ ] Test The Hive accessibility
- [ ] Test Grafana dashboard

### Credential Management
- [ ] Change all default passwords
- [ ] Document new passwords securely (password manager)
- [ ] Generate API keys where needed
- [ ] Test authentication on each platform

### Integration Testing
- [ ] Test Wazuh → The Hive alert creation
- [ ] Test The Hive → MISP enrichment
- [ ] Test Wazuh → Shuffle workflow execution
- [ ] Test Shuffle → Slack notification
- [ ] Run attack simulation tests

### Backup & Security
- [ ] Create snapshot/backup of deployment
- [ ] Enable backups for persistent data
- [ ] Review and restrict NSG rules to your IP only
- [ ] Enable monitoring and alerting

### Documentation Update
- [ ] Document actual IP addresses assigned
- [ ] Document all generated credentials
- [ ] Note any customizations made
- [ ] Record deployment completion time

### Cost Optimization
- [ ] Review Azure Cost Management
- [ ] Note estimated monthly costs
- [ ] Set up budget alerts
- [ ] Consider auto-shutdown for dev/test VMs

---

## ⚠️ Common Issues & Troubleshooting

### Authentication Failures
```bash
# If "az login" fails
az login --use-device-code

# If subscription not set
az account list --output table
az account set --subscription "subscription-id"
```

### Script Permission Issues
```bash
# Make scripts executable
chmod +x infrastructure/azure/deploy.sh
chmod +x scripts/*.sh
```

### Container Not Starting
```bash
# Check container logs
docker logs <container-name>

# Check Docker daemon
docker ps
```

### Network Connectivity Issues
```bash
# Test connectivity to service
curl -v http://<service-ip>:<port>

# Check NSG rules
az network nsg rule list --resource-group <rg> --nsg-name <nsg-name>
```

---

## 📞 Support Resources

- **Azure Documentation**: https://docs.microsoft.com/azure
- **Wazuh Documentation**: https://documentation.wazuh.com
- **The Hive Documentation**: https://docs.thehive-project.org
- **MISP Documentation**: https://misp.github.io/MISP
- **Project Issues**: Check GitHub Issues tab

---

**Estimated Time**: 2-3 hours (including pre-deployment setup, deployment, and verification)
