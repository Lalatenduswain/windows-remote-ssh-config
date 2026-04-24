# Security Guidelines

## ⚠️ Important Security Notes

### SSH Keys
- **Never commit private keys** to version control
- **Never hardcode public keys** in documentation
- Keep private keys encrypted and backed up securely
- Use strong passphrases for key files
- Consider using key rotation schedules

### Credentials
- Do not hardcode passwords or tokens
- Use `.env` files for local development (never commit)
- Use environment variables or secrets management in production
- Store credentials in encrypted password managers

### Deployment Best Practices
1. Restrict SSH access by IP address where possible
2. Disable password authentication (use keys only)
3. Use non-standard SSH ports to reduce noise
4. Enable firewall rules to limit SSH access
5. Monitor SSH logs for suspicious activity
6. Implement key rotation policies

### Infrastructure Details
- Avoid publishing machine names or network topology
- Do not include server IP addresses in public repos
- Be cautious about revealing deployment infrastructure details
- Consider using hostnames instead of IPs where possible

### Code Review
- Have security-conscious team members review deployment scripts
- Use linters for PowerShell scripts (`PSScriptAnalyzer`)
- Test scripts in isolated environments before production use

### Incident Response
If you believe this repository has been compromised:
1. **Immediately rotate all SSH keys**
2. Review access logs on all configured systems
3. Check for unauthorized administrative access
4. Update Windows Firewall rules to restrict SSH
5. Consider re-keying any affected systems

## Reporting Security Issues

If you discover a security vulnerability, please **do not** open a public GitHub issue. Instead:
- Email security concerns to your organization's security team
- Include details of the vulnerability
- Allow time for remediation before any public disclosure

---

**Last Updated:** 2026-04-24
