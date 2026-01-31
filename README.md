# Contracts Skill

> **Spec-driven development with living contracts for AI-assisted coding.**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Version: 2.0.0](https://img.shields.io/badge/Version-2.0.0-blue.svg)](#)
[![Works with: Copilot](https://img.shields.io/badge/Works%20with-GitHub%20Copilot-blue)](https://github.com/features/copilot)
[![Works with: Claude](https://img.shields.io/badge/Works%20with-Claude-orange)](https://claude.ai)
[![Works with: Cursor](https://img.shields.io/badge/Works%20with-Cursor-purple)](https://cursor.sh)

Keep your AI coding assistant aligned with your specifications. Never let implementations drift from requirements again.

**What's New in v2.0:** AI-assisted initialization that understands your codebase semantically — no more rigid patterns, just intelligent analysis.

---

## Quick Start

### 1. Install

Choose your preferred method:

# Contracts Skill

Spec-driven development with living contracts for AI-assisted coding. The goal is to prevent spec drift by keeping requirements (`CONTRACT.md`) and an AI-maintained technical mirror (`CONTRACT.yaml`) in sync.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Works with: Copilot](https://img.shields.io/badge/Works%20with-GitHub%20Copilot-blue)](https://github.com/features/copilot)

---

## Quick Start

### 1) Install

Recommended (interactive multi-agent installer):

```powershell
# PowerShell
irm https://raw.githubusercontent.com/KombiverseLabs/contracts-skill/main/setup.ps1 | iex
```

```bash
# Bash
curl -fsSL https://raw.githubusercontent.com/KombiverseLabs/contracts-skill/main/setup.sh | bash
```

Install into just the current project:

```powershell
# PowerShell
irm https://raw.githubusercontent.com/KombiverseLabs/contracts-skill/main/installers/install.ps1 | iex
```

```bash
# Bash
curl -fsSL https://raw.githubusercontent.com/KombiverseLabs/contracts-skill/main/installers/install.sh | bash
```

Optional: add the Contracts UI into your repo (copies to `./contracts-ui/`):

```powershell
irm https://raw.githubusercontent.com/KombiverseLabs/contracts-skill/main/installers/install.ps1 | iex -UI minimal-ui
```

### 2) Initialize contracts (AI-assisted)

In your assistant: “Initialize contracts for this project”.

Or run the initializer directly:

```bash
node .github/skills/contracts/ai/init-agent/index.js --path . --analyze
node .github/skills/contracts/ai/init-agent/index.js --path . --dry-run
node .github/skills/contracts/ai/init-agent/index.js --path . --apply --yes
```

Wrapper scripts:

```powershell
pwsh .github/skills/contracts/scripts/init-contracts.ps1 -Path .
```

```bash
./.github/skills/contracts/scripts/init-contracts.sh --path .
```

### 3) Validate

```powershell
pwsh .github/skills/contracts/scripts/validate-contracts.ps1 -Path .
```

### 4) Preflight (before implementing changes)

Summarizes relevant MUST / MUST NOT constraints for your current diff:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .github/skills/contracts/scripts/contract-preflight.ps1 -Path . -Changed
```

---

## What gets created

Each module typically contains:

- `CONTRACT.md` (human-owned requirements; source of truth)
- `CONTRACT.yaml` (AI-maintained mirror/spec + drift metadata)

Example structure:

```text
your-project/
├── .contracts/
│   └── registry.yaml
└── src/
    └── core/
        └── auth/
            ├── CONTRACT.md
            ├── CONTRACT.yaml
            └── ...
```

---

## Contracts UI (optional)

If installed into `./contracts-ui/`:

- minimal-ui (server mode, read/write): `./contracts-ui/start.ps1` or `./contracts-ui/start.sh`
- minimal-ui (static snapshot, read-only): open `contracts-ui/index.html`
- php-ui: `php -S localhost:8080 -t contracts-ui` then open http://localhost:8080

---

## CI / Automation

GitHub Actions step example:

```yaml
- name: Validate Contracts
  run: pwsh .github/skills/contracts/scripts/validate-contracts.ps1 -OutputFormat github-actions
```

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

Install local git hooks:

```bash
sh ./scripts/install-git-hooks.sh
```

```powershell
./scripts/install-git-hooks.ps1
```

---

## License

MIT © KombiverseLabs
## Installation Options
