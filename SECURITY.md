# Security Policy

## Important Security Notice

**USE AT YOUR OWN RISK**: This application was built with the assistance of Claude Code, an AI-powered development tool. While efforts have been made to follow security best practices, this software comes with no warranties or guarantees.

### Installation Risk

This application:
- Requires accessibility permissions to intercept media key events
- Runs as a menu bar application with system-level access
- Was developed with AI assistance and may contain undiscovered vulnerabilities

**Install and use this software at your own risk.** We strongly recommend:
- Reviewing the source code before installation
- Testing in a non-production environment first
- Understanding the permissions being granted
- Only installing if you accept the potential security risks

## Reporting a Vulnerability

If you discover a security vulnerability, please help us maintain the security of this project:

### How to Report

1. **DO NOT** create a public GitHub issue for security vulnerabilities
2. Email security concerns to: [Your email address or use GitHub Security Advisories]
3. Include:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if available)

### What to Expect

- Acknowledgment of your report within 48 hours
- Regular updates on the progress of addressing the issue
- Credit for responsible disclosure (if desired)

## Contributing Security Fixes

We welcome security-focused pull requests! Please:

1. Review our [Contributing Guidelines](CONTRIBUTING.md)
2. Clearly describe the security issue being addressed
3. Provide context on why the change improves security
4. Test thoroughly before submitting

## Security Best Practices

When using this application:

- Keep your macOS system updated
- Review app permissions regularly in System Settings
- Monitor for unexpected behavior
- Check for updates regularly
- Consider building from source instead of using pre-built binaries

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| main    | :white_check_mark: |
| < 1.0   | :x:                |

## AI Development Disclosure

This project was developed with assistance from Claude Code. While AI can accelerate development, it may introduce:
- Logic errors not caught by traditional review
- Security patterns that seem correct but have subtle flaws
- Dependency choices that haven't been fully vetted

We encourage community review and welcome security-focused contributions.
