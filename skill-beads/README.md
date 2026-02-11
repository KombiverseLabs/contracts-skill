# Contracts Skill — Beads-Enforced Variant

This directory contains the **Beads-enforced** variant of the Contracts skill. It adds dependency-blocking enforcement via [Beads](https://github.com/steveyegge/beads) on top of the base contracts system.

## When to Use This Variant

Use `skill-beads/` instead of `skill/` when:
- Beads is already initialized in your project (`.beads/` directory exists)
- You want **hard enforcement**: feature tasks are blocked until contract preflight is closed
- You need an **audit trail** of contract compliance checks

## What's Different from Base

| Aspect | `skill/` (Base) | `skill-beads/` (This) |
|--------|----------------|----------------------|
| Preflight | Advisory — agent should check | **Blocking** — Beads task must be closed |
| Enforcement | Instruction-based | Dependency-based via Beads |
| Audit trail | None | Beads task history |
| Prerequisites | None | Beads CLI + `.beads/` directory |

## Structure

```
skill-beads/
├── SKILL.md                          # Beads-enforced skill definition
├── README.md                         # This file
└── references/
    └── assistant-hooks/
        ├── contract-preflight.md     # Preflight with Beads task lifecycle
        └── init-contracts.md         # Init with Beads setup step
```

Everything else (templates, scripts, AI agent, UI) is shared with `skill/` and referenced via relative paths.

## Installation

When running the installer, choose the Beads variant:

```powershell
# The installer auto-detects Beads and offers the enforced variant
irm https://raw.githubusercontent.com/KombiverseLabs/contracts-skill/main/installers/bootstrap-install.ps1 | iex
```

Or manually copy `skill-beads/` to your project's skill directory instead of `skill/`.
