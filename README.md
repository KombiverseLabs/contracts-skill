# Contracts Skill

> **Spec-driven development with living contracts for AI-assisted coding.**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Version: 2.2.0](https://img.shields.io/badge/Version-2.2.0-blue.svg)](#)
[![Works with: Copilot](https://img.shields.io/badge/Works%20with-GitHub%20Copilot-blue)](https://github.com/features/copilot)
[![Works with: Claude](https://img.shields.io/badge/Works%20with-Claude-orange)](https://claude.ai)
[![Works with: Cursor](https://img.shields.io/badge/Works%20with-Cursor-purple)](https://cursor.sh)

Keep your AI coding assistant aligned with your specifications. Never let implementations drift from requirements again.

---

## Two Variants

| Variant | Directory | Enforcement | Best For |
|---------|-----------|-------------|----------|
| **Base** | `skill/` | Instruction-based (advisory) | Any project, no extra dependencies |
| **Beads-Enforced** | `skill-beads/` | Dependency-blocking via [Beads](https://github.com/steveyegge/beads) | Projects using Beads for task management |

Both variants share the same scripts, templates, AI analyzer, and UI. They differ only in how preflight checks are enforced.

---

## Quick Start

### 1. Install

```powershell
# PowerShell (Windows/macOS/Linux)
irm https://raw.githubusercontent.com/KombiverseLabs/contracts-skill/main/installers/bootstrap-install.ps1 | iex
```

```bash
# Bash
curl -fsSL https://raw.githubusercontent.com/KombiverseLabs/contracts-skill/main/installers/install.sh | bash
```

The installer will:
- Detect your AI assistants (Copilot, Claude, Cursor, Windsurf, Cline, Aider, OpenCode)
- Let you choose which to configure
- Optionally add the Contracts UI
- Auto-detect [Beads](https://github.com/steveyegge/beads) and offer the enforced variant

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
- `CONTRACT.yaml` — AI-maintained metadata (drift detection, feature status, verification tests, attestation)

Your AI will now **check contracts before making changes**, verify alignment, and track implementation health.

---

## How It Works

1. You define requirements in `CONTRACT.md` (constraints, features, success criteria, verification tests)
2. AI generates `CONTRACT.yaml` with a SHA256 hash of your spec
3. Before any code change, the AI reads the contract, checks attestation, and verifies VT status
4. If the spec changed (hash mismatch), AI stops and syncs before proceeding
5. Every feature maps to a test file; missing tests trigger warnings
6. **Verification Tests** prove the module actually works through golden-path assertions
7. **Attestation** tracks which contract version was verified and when re-verification is due

### With Beads (Enforced Variant)

When using `skill-beads/`, the workflow adds structural enforcement:

1. Agent creates a feature task in Beads
2. Feature task depends on a PREFLIGHT task (priority 0)
3. Agent must check contracts and close PREFLIGHT with a summary
4. Only then does the feature task unblock

| Without Beads | With Beads |
|--------------|------------|
| Instructions can be ignored | Preflight task **blocks** feature work |
| No enforcement mechanism | Agent cannot proceed until preflight done |
| Hope-based compliance | Audit trail of contract checks |

---

## Key Features

### Verification Tests (Contract-Level TDD)

Each contract defines 1-3 **Verification Tests (VTs)** — high-leverage tests that prove the module actually works, not just that it compiles. One smart test beats ten shallow tests.

```markdown
## Verification Tests
- [x] **VT-1: Chat produces verified factual response**
  - Scenario: Authenticated user sends a factual question through chat UI
  - Action: Login with test creds → open chat → send "What is the capital of France?"
  - Verify: Response text contains "Paris"
  - Proves: Auth, session, chat UI, message pipeline, LLM integration, response rendering
```

**The philosophy**: Assert on **actual output content** (not just status codes). A single VT implicitly validates every component in the chain. If ANY core feature breaks, the test fails.

| Tier | VTs | Focus |
|------|-----|-------|
| core | 1 | Round-trip correctness |
| standard | 1-2 | Golden path + key edge case |
| complex | 2-3 | Golden path + error resilience + secondary flow |

### Contract Commitment (Long-Term Binding)

Contracts are not session-scoped suggestions — they are **persistent commitments**. The attestation mechanism ensures contracts remain binding across sessions:

- **Attestation**: Records which contract version was implemented against, VT results, and confidence level
- **Confidence Score**: `high` (all VTs passing) / `medium` (some failing) / `low` (VTs not implemented)
- **Re-Verification Cadence**: Stale attestations (>30 days) trigger preflight warnings
- **Binding Rule**: A feature cannot be marked `implemented` without VT-1 passing

---

## What Gets Created

```text
your-project/
├── .contracts/
│   └── registry.yaml          # Central index of all contracts
└── src/
    └── core/
        └── auth/
            ├── CONTRACT.md     # Human-owned spec (features, constraints, VTs)
            ├── CONTRACT.yaml   # AI-maintained metadata (status, attestation)
            └── ...
```

---

## Contracts UI (optional)

If installed into `./contracts-ui/`:

```bash
# Start the UI server (live read/write mode)
./contracts-ui/start.ps1   # or start.sh

# Or open static snapshot (read-only)
open contracts-ui/index.html
```

---

## Validation & CI

```powershell
# Validate all contracts (drift detection, structure, test coverage, VT status)
pwsh .github/skills/contracts/scripts/validate-contracts.ps1 -Path .

# Preflight check for changed files
pwsh .github/skills/contracts/scripts/contract-preflight.ps1 -Path . -Changed

# CI: GitHub Actions
```

```yaml
- name: Validate Contracts
  run: pwsh .github/skills/contracts/scripts/validate-contracts.ps1 -OutputFormat github-actions
```

---

## Repository Structure

```
contracts-skill/
├── skill/                    # Base variant (advisory enforcement)
│   ├── SKILL.md              # Skill definition
│   ├── references/
│   │   ├── assistant-hooks/  # Preflight & init hooks
│   │   └── templates/        # CONTRACT.md templates per tier
│   ├── scripts/              # PowerShell & Bash validation tools
│   ├── ai/init-agent/        # Semantic project analyzer (Node.js)
│   └── ui/                   # Minimal UI & PHP UI
├── skill-beads/              # Beads-enforced variant
│   ├── SKILL.md              # Skill definition with Beads integration
│   └── references/
│       └── assistant-hooks/  # Preflight & init hooks with Beads lifecycle
├── examples/                 # Sample project with contracts
├── installers/               # One-liner installers (PS1, Bash)
└── tests/                    # Playwright-based test suite
```

---

## References

- [Base Skill Specification](skill/SKILL.md)
- [Beads-Enforced Specification](skill-beads/SKILL.md)
- [Contract Templates](skill/references/templates/)
- [Beads](https://github.com/steveyegge/beads) — Persistent task memory for agents

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

---

## License

MIT © KombiverseLabs
