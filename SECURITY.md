# Security Policy

## Supported Versions

| Version | Supported          |
|---------|--------------------|
| 2.x     | :white_check_mark: |
| < 2.0   | :x:                |

## Reporting a Vulnerability

If you discover a security vulnerability in Contract Skill, please report it responsibly.

**Do NOT open a public GitHub issue for security vulnerabilities.**

### How to Report

1. Email: security@kombify.io
2. Include:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if any)

### What to Expect

- **Acknowledgment**: Within 48 hours of your report
- **Assessment**: We will evaluate the report and determine severity
- **Fix**: Critical issues will be patched as soon as possible
- **Disclosure**: We will coordinate disclosure with you

### Scope

This security policy covers:
- Installer scripts (`installers/`)
- Validation and preflight scripts (`skill/scripts/`)
- UI components (`skill/ui/`)
- AI initialization agent (`skill/ai/`)

### Out of Scope

- Issues in third-party dependencies (report upstream)
- Issues in AI assistant behavior (report to the assistant vendor)
