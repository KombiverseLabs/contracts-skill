# Contributing to Contracts Skill

Thank you for your interest in contributing! This document provides guidelines for contributing to the Contracts Skill project.

## Reporting Bugs

1. Check existing issues first
2. Use the bug report template
3. Include:
   - OS and PowerShell version
   - AI assistant being used (Copilot, Claude, Cursor, etc.)
   - Steps to reproduce
   - Expected vs actual behavior

## Suggesting Features

1. Open an issue with the feature request template
2. Describe the use case
3. Explain how it improves the skill

## Pull Requests

### Setup

```bash
# Fork and clone
git clone https://github.com/KombiverseLabs/contracts-skill.git
cd contracts-skill

# Create a branch
git checkout -b feature/your-feature-name
```

### Guidelines

- **Keep changes focused** — one feature/fix per PR
- **Follow existing patterns** — match the code style
- **Update documentation** — if you change behavior, update docs
- **Test your changes** — run the validation scripts

### Commit Messages

Use conventional commits:

```
feat: add support for Python projects
fix: correct hash computation on Windows
docs: update installation instructions
chore: update dependencies
```

### PR Checklist

- [ ] I've read the CONTRIBUTING.md
- [ ] My code follows the existing style
- [ ] I've updated relevant documentation
- [ ] I've tested on Windows PowerShell
- [ ] I've tested on Bash (if applicable)

## Project Structure

```
contracts-skill/
├── README.md              # Main documentation
├── install.ps1            # PowerShell installer
├── install.sh             # Bash installer
├── LICENSE                # MIT license
├── CONTRIBUTING.md        # This file
│
├── skill/                 # The actual skill (copy this to .agent/skills/)
│   ├── SKILL.md          # Main skill definition
│   ├── README.md         # Skill documentation
│   ├── references/       # Templates and guides
│   └── scripts/          # PowerShell utilities
│
└── examples/              # Example projects with contracts
```

## Testing

### Manual Testing

1. Install the skill to a test project
2. Run initialization
3. Create/modify contracts
4. Verify sync behavior with your AI assistant

### Script Testing

```powershell
# Validate contract structure
.\skill\scripts\validate-contracts.ps1 -Path "examples/sample-project"

# Test hash computation
.\skill\scripts\compute-hash.ps1 -FilePath "examples/sample-project/src/auth/CONTRACT.md"
```

## Code of Conduct

- Be respectful and inclusive
- Focus on constructive feedback
- Help others learn

## 🙏 Thank You!

Your contributions make this project better for everyone.
