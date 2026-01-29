# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2026-01-29

### Added

- **AI-Assisted Initialization** - Complete rewrite of the initialization system
  - New `analyzer.js` module performs semantic code analysis
  - Detects project type (Node.js, Python, Go, Rust) automatically
  - Analyzes source structure, exports, and complexity metrics
  - Generates intelligent contract recommendations with reasoning
  - Scores modules by importance (exports, test coverage, dependencies)
  
- **Multi-Agent Installer with Selection**
  - All installers now support agent selection
  - Interactive mode: choose which agents to install to
  - Auto mode: install to all detected agents
  - Specific agents: `--agents copilot,claude,cursor`
  - Supports: GitHub Copilot, Claude, Cursor, Windsurf, Aider, Cline, and local project

- **New Templates**
  - `integration.md` - For external API integrations
  - `utility.md` - For helper/utility modules

### Changed

- **Initialization is now AI-assisted instead of pattern-based**
  - Old: Fixed patterns (`src/features/*`, `src/core/*`)
  - New: Semantic analysis of codebase
  - Old: Simple templates
  - New: Context-aware drafts from actual code exports

- **Updated Documentation**
  - `initialization.md` - Complete rewrite for AI-assisted workflow
  - `assistant-hooks/init-contracts.md` - New implementation guide
  - `SKILL.md` - Updated initialization section

### Fixed

- Agent selection now works in all installer variants
- Missing `init-contracts.ps1` script added
- Installer now adds instruction hooks to `.github/copilot-instructions.md`

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
- Windsurf
- Cline
- Aider
- Any assistant supporting custom instructions
