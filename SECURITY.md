# Security Policy

## Reporting Security Vulnerabilities

⚠️ **IMPORTANT**: If you discover a security vulnerability, **please do NOT open a public GitHub Issue**.

Instead, please follow responsible disclosure:

### Reporting Process

1. **Email**: baskaran.elilan@example.com (replace with your actual email)
2. **Subject**: "[SECURITY] SOC Home Lab Vulnerability"
3. **Include**:
   - Description of vulnerability
   - Steps to reproduce
   - Potential impact
   - Any proof of concept (if safe to share)

4. **Timeline**: I will respond within 48 hours and aim to:
   - Confirm/deny the vulnerability
   - Assess severity
   - Develop and test a fix
   - Provide an estimated patch timeline

5. **Public Disclosure**: Once fixed, I will:
   - Credit the reporter (unless you prefer anonymity)
   - Add security advisory to GitHub
   - Document the fix in CHANGELOG.md

---

## Security Considerations

### This Project Is A Lab Environment

✅ **Designed For**:
- Educational purposes
- Security training and practice
- Learning SOC operations
- Testing in isolated networks
- Cybersecurity student projects

❌ **NOT Recommended For**:
- Production environments without hardening
- Monitoring real sensitive data
- Public-facing deployments
- Replacing enterprise security infrastructure
- Unattended automated deployments

### Before Production Use

If deploying to a production or semi-production environment, implement:

- [ ] **Network Segmentation**: Isolate lab from production networks
- [ ] **Access Control**: Restrict to authorized personnel only
- [ ] **Encryption**: Use proper TLS certificates (not self-signed)
- [ ] **Authentication**: Enforce strong passwords and MFA
- [ ] **Monitoring**: Setup comprehensive audit logging
- [ ] **Backups**: Regular backups with encryption
- [ ] **Updates**: Keep all tools updated with security patches
- [ ] **Compliance**: Map to relevant standards (PCI-DSS, NIST, etc.)

See [docs/BEST_PRACTICES.md](docs/BEST_PRACTICES.md) and [docs/MAINTENANCE_GUIDE.md](docs/MAINTENANCE_GUIDE.md) for detailed production hardening steps.

---

## Known Security Limitations

### Design Limitations
1. **Default Credentials**: Many tools ship with default credentials (required for installation)
   - ✅ These MUST be changed immediately after deployment
   - ✅ Use strong, unique passwords for each service

2. **Self-Signed Certificates**: By default uses self-signed HTTPS certificates
   - ✅ Acceptable for lab environments
   - ❌ NOT acceptable for production
   - ✅ Use Let's Encrypt or proper CA for production

3. **Network Security Groups**: NSG rules are configured for lab access
   - ✅ Appropriate for isolated lab environments
   - ❌ Too permissive for production
   - ✅ Restrict to specific IPs in production

4. **Data Storage**: Persistent data stored in local Docker volumes
   - ✅ Fine for lab testing
   - ❌ Not suitable for production data
   - ✅ Use managed databases and encryption for production

### Dependency Security

This project uses several third-party components. Security advisories may be issued for:
- **Wazuh**: Check https://wazuh.com/security-advisories
- **MISP**: Check https://www.misp-project.org/security
- **The Hive**: Check https://github.com/TheHive-Project/TheHive/security/advisories
- **DFIR-IRIS**: Check https://github.com/dfir-iris/iris-web/security/advisories
- **Shuffle**: Check https://github.com/frikky/Shuffle/security/advisories

Regularly update all tools to latest versions for security patches.

---

## Security Best Practices

### Access Control
```bash
# Keep SSH keys secure
chmod 600 ~/.ssh/id_rsa

# Use SSH key authentication (not passwords)
# Enable MFA on Azure accounts

# Limit access to specific IP addresses
# Use VPN for remote access
```

### Secrets Management
```bash
# NEVER commit .env files to Git
# Use .env.template for documentation only

# Store .env.local securely
chmod 600 .env.local

# Consider using Azure Key Vault for production
az keyvault secret set --vault-name your-vault --name api-key --value "your-secret"
```

### Network Security
```bash
# Review NSG rules regularly
az network nsg rule list --resource-group your-rg --nsg-name your-nsg

# Restrict to specific IP addresses
# Use Network Watcher to monitor traffic
# Enable DDoS protection (if budget allows)
```

### Data Security
```bash
# Enable encryption at rest
# Enable encryption in transit (TLS/SSL)
# Regular backups with encryption
# Retention policies for logs

# Consider: Data classification levels
# Implement: Proper access controls per level
```

### Monitoring & Logging
```bash
# Enable comprehensive audit logging
# Forward logs to central location
# Setup alerts for suspicious activity
# Regular log review and analysis

# Monitor:
# - Authentication attempts
# - Configuration changes
# - Data access patterns
# - System errors
```

### Updates & Patch Management
```bash
# Keep all tools updated
# Subscribe to security advisories
# Test patches in lab first
# Document all updates

# Regular schedule:
# - Weekly: Check for critical patches
# - Monthly: Apply available patches
# - Quarterly: Major version updates
```

---

## Incident Response

If you discover suspicious activity or potential compromise:

1. **Isolate**: Disconnect from network if needed
2. **Document**: Take screenshots, save logs
3. **Report**: Contact security team immediately
4. **Investigate**: Use DFIR-IRIS for forensic analysis
5. **Report Externally**: If needed, report to relevant authorities

---

## Security Acknowledgments

Thank you to the following projects for excellent security:
- **Wazuh**: Enterprise-grade SIEM platform
- **MISP**: Collaborative threat intelligence
- **The Hive**: Open-source incident response
- **DFIR-IRIS**: Digital forensics and response
- **Shuffle**: Automation and orchestration
- **Suricata**: Network threat detection

---

## References

- [OWASP Security Best Practices](https://cheatsheetseries.owasp.org/)
- [CIS Benchmarks](https://www.cisecurity.org/benchmarks)
- [NIST Cybersecurity Framework](https://www.nist.gov/cyberframework)
- [Azure Security Documentation](https://docs.microsoft.com/azure/security)

---

## Questions?

For security questions (non-vulnerability):
- Open a GitHub Issue with label `security-question`
- Check existing security documentation
- Review threat models and risk assessments

---

**Last Updated**: May 2026  
**Status**: Lab Environment - Educational Use  
**Support**: Community-driven, best effort
