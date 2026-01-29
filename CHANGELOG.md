# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-01-29

### Added

- Initial release of Contracts Skill
- `CONTRACT.md` template for user-owned specifications
- `CONTRACT.yaml` schema for AI-maintained technical mapping
- Hash-based drift detection
- Tier system (core/standard/complex) with line limits
- Cross-contract dependency tracking
- Changelog tracking in YAML files
- Central registry (`.contracts/registry.yaml`)
- PowerShell scripts:
  - `init-contracts.ps1` - Project initialization
  - `validate-contracts.ps1` - CI/CD validation
  - `compute-hash.ps1` - Hash utility
- One-liner installers for PowerShell and Bash
- Templates for feature, core, and integration modules
- Documentation and quick reference cheatsheet

### Supported Platforms

- Windows PowerShell 5.1+
- PowerShell Core 7+
- Bash/Zsh (via install.sh)

### Supported AI Assistants

- GitHub Copilot
- Claude (Claude Code, Claude Desktop)
- Cursor
- Any assistant supporting custom instructions
