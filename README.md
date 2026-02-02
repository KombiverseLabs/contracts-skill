# Contracts Skill

> **Spec-driven development with living contracts for AI-assisted coding.**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Version: 2.0.0](https://img.shields.io/badge/Version-2.0.0-blue.svg)](#)
[![Works with: Copilot](https://img.shields.io/badge/Works%20with-GitHub%20Copilot-blue)](https://github.com/features/copilot)
[![Works with: Claude](https://img.shields.io/badge/Works%20with-Claude-orange)](https://claude.ai)
[![Works with: Cursor](https://img.shields.io/badge/Works%20with-Cursor-purple)](https://cursor.sh)

Keep your AI coding assistant aligned with your specifications. Never let implementations drift from requirements again.

---

## Quick Start

### 1. Install

```powershell
# PowerShell (Windows/macOS/Linux)
irm https://raw.githubusercontent.com/KombiverseLabs/contracts-skill/main/installers/bootstrap-install.ps1 | iex
```

```bash
# Bash
curl -fsSL https://raw.githubusercontent.com/KombiverseLabs/contracts-skill/main/setup.sh | bash
```

The installer will:
- Detect your AI assistants (Copilot, Claude, Cursor, etc.)
- Let you choose which to configure
- Optionally add the Contracts UI
- **Detect [Beads](https://github.com/steveyegge/beads)** and offer enhanced enforcement

### 2. Initialize contracts

Ask your AI assistant:
> "Initialize contracts for this project"

Or run directly:
```bash
node .github/skills/contracts/ai/init-agent/index.js --path . --analyze
```

### 3. Use contracts

Each module gets:
- `CONTRACT.md` — Human-owned specification (you write this)
- `CONTRACT.yaml` — AI-maintained metadata (drift detection)

Your AI will now **check contracts before making changes** and summarize constraints.

---

## Recommended: Use with Beads

For **stronger enforcement**, combine with [Beads](https://github.com/steveyegge/beads) — a persistent task memory for AI agents:

```bash
# Install Beads (one-time)
npm install -g @beads/bd

# Initialize in your project
bd init
```

**Why Beads + Contracts?**

| Without Beads | With Beads |
|--------------|------------|
| Instructions can be ignored | Tasks create **dependency blocking** |
| No enforcement mechanism | Agent cannot proceed until preflight done |
| Hope-based compliance | Audit trail of contract checks |

The installer auto-detects Beads and creates a preflight task that blocks feature work until contracts are checked.

---

## What gets created

Example structure:

```text
your-project/
├── .contracts/
│   └── registry.yaml
└── src/
    └── core/
        └── auth/
            ├── CONTRACT.md      # Human-owned spec
            ├── CONTRACT.yaml    # AI-maintained metadata
            └── ...
```

---

## Contracts UI (optional)

If installed into `./contracts-ui/`:

```bash
# Start the UI server
./contracts-ui/start.ps1   # or start.sh

# Or open static snapshot (read-only)
open contracts-ui/index.html
```

---

## Advanced Installation Options

<details>
<summary>Click to expand</summary>

**With specific agents:**
```powershell
$script = irm https://raw.githubusercontent.com/KombiverseLabs/contracts-skill/main/installers/install.ps1
& ([scriptblock]::Create($script)) -Agents "copilot,claude" -UI minimal-ui
```

**Project-local only:**
```powershell
irm https://raw.githubusercontent.com/KombiverseLabs/contracts-skill/main/installers/install.ps1 | iex
```

**Validate contracts:**
```powershell
pwsh .github/skills/contracts/scripts/validate-contracts.ps1 -Path .
```

**Preflight check (before implementing):**
```powershell
pwsh .github/skills/contracts/scripts/contract-preflight.ps1 -Path . -Changed
```

</details>

---

## CI / Automation

GitHub Actions example:

```yaml
- name: Validate Contracts
  run: pwsh .github/skills/contracts/scripts/validate-contracts.ps1 -OutputFormat github-actions
```

---

## References

- [SKILL.md](skill/SKILL.md) — Detailed skill specification
- [Contract Templates](skill/references/templates/) — MODULE.md templates
- [Preflight Hook](skill/references/assistant-hooks/contract-preflight.md) — How preflight works
- [Beads](https://github.com/steveyegge/beads) — Persistent task memory for agents

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

---

## License

MIT © KombiverseLabs
