# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [2.8.1] - 2026-05-09

### Fixed

- Made the skill metadata quality gate tolerant of CRLF checkouts on Windows.

## [2.8.0] - 2026-05-09

### Added

- Added StackKit-standard contract lock scripts in `skill/scripts/` for locking and unlocking approved `CONTRACT.md` files on Bash and PowerShell.
- Added `references/contract-locking.md` with platform semantics for Linux, macOS, and Windows.

### Changed

- Updated skill guidance so locked/read-only `CONTRACT.md` files are treated as human-owned and changed only through explicit approval.

## [2.7.1] - 2026-05-08

### Added

- Added a README thanks note for the Beads framework.

### Changed

- Simplified the README installation section around one PowerShell and one Bash one-liner, with advanced installer flags moved to `INSTALL.md`.
- Clarified contract-review guidance so contract edits remain approval-led and Beads review summaries do not depend on unsupported comment behavior.

## [2.7.0] - 2026-05-08

### Changed

- **Standards-first skill layout** — `skill/SKILL.md` is now shorter and trigger-oriented, detailed workflows live in references, and `skill/agents/openai.yaml` provides current skill metadata.
- **Simplified installation** — Installers now copy `skill/` to an explicit target or compatibility profile without agent auto-detection, UI installation, project setup prompts, or `.contracts/` creation.
- **Instruction hooks** — Installers now write idempotent `AGENTS.md` hooks by default, with `base`, `beads`, `auto`, and `none` modes plus optional legacy hook mirroring.
- **Agent-led initialization** — Init helpers are read-only by default and all write modes require explicit `--apply --yes` approval.
- **Beads mode** — Beads enforcement is now documented as an optional mode of the main `contracts` skill via `references/beads-enforcement.md`.

### Removed

- Removed the separate installable `skill-beads/` variant. Existing users should install `skill/` and use `--hooks beads` or `--hooks auto`.
- Removed skill-internal README files; root docs now cover installation, usage, and contribution guidance.

## [2.6.0] - 2026-05-01

### Added

- **Project reference guide (`CONTRACTS-GUIDE.md`)** — Both installers and "init contracts" now create `.contracts/CONTRACTS-GUIDE.md` in the project repo. This permanent, committable document tells every developer and AI agent where contracts live, how the system is applied, and what conventions the project uses. AI agents read it at the start of each session to avoid re-asking setup questions.
- **Installer project setup phase** — Both `install.ps1` and `install.sh` now include a post-installation "Project Setup" section. After installing the skill, the installer asks: project name (with auto-detection from `package.json`, git remote, or directory name), primary stack/language, contracts owner/team, and any project conventions. Answers are written into `.contracts/CONTRACTS-GUIDE.md` and `.contracts/registry.yaml`.
- **`references/project-guide.md`** — Template for the project-level guide used by both the installer and the "init contracts" AI flow.
- **`references/examples/`** — Three fully filled-in reference contracts at different tiers and module types: `auth-core.md` (core tier), `dashboard-feature.md` (standard tier), `stripe-integration.md` (complex tier). AI agents consult these when drafting new contracts to understand the expected quality level for Purpose, Constraints, and VT assertions.
- **Step 0 in init-contracts.md** — "init contracts" now begins by gathering project context (project name, stack, owner, conventions) before scanning modules. If `.contracts/CONTRACTS-GUIDE.md` already exists, it reads it and skips questions that are already answered.
- **Step 7 in init-contracts.md** — After creating contract files, "init contracts" now creates or updates `.contracts/CONTRACTS-GUIDE.md` with the discovered module table, skill paths, and project context. This step is mandatory.

### Changed

- **SKILL.md** — References section now distinguishes templates (empty scaffolds) from examples (filled-in references). `references/examples/` added alongside `references/templates/`.
- **init-contracts.md Step 5** — Contract generation now explicitly loads `references/examples/` as quality reference before drafting, not just the templates.
- **init-contracts.md** — Post-initialization checklist updated: "Commit `.contracts/CONTRACTS-GUIDE.md` and `registry.yaml` to version control" added as step 4.

## [2.5.0] - 2026-04-11

### Added

- **Bootstrap prompt for agent-driven installation** — Users can paste a short prompt to any AI agent (Copilot, Claude, Cursor, Codex) to install the skill without finding install commands manually
- **INSTALL.md** — Comprehensive agent-readable installation guide with automated (script) and manual (clone + copy) options, verification steps, and troubleshooting
- **Acceptance Test validation in preflight** — Preflight hooks (base + Beads) now verify that contracts define at least one measurable acceptance test
- **Out of Scope validation in preflight** — Preflight hooks now check planned changes against the contract’s Out of Scope section
- **Acceptance tests in init-agent output** — AI-assisted contract generation now includes a default `acceptance_tests` entry ("All VTs pass")

### Changed

- **SKILL.md rewritten** — Both base and Beads variants reduced to ~130 lines with modern frontmatter format, 6 Integrity Rules, mandatory ATs
- **Templates updated** — All 4 templates (core, feature, integration, utility) now include mandatory Acceptance Tests and Out of Scope sections
- **CONTRACT.yaml.template** — `acceptance_tests` section now uncommented with a default entry; previously was commented-out example
- **contract-review.md** — New assistant hook for scope drift detection with Beads integration
- **Preflight steps expanded** — Base: 8→10 steps, Beads: 9→11 steps

### Fixed

- **Missing acceptance_tests in generated YAML** — init-agent `makeYaml()` now emits `acceptance_tests` section
- **Preflight gap** — Previously skipped AT and Out of Scope validation, now enforced

## [2.4.0] - 2026-04-11

### Changed

- **Public repository is now a consistent slim distribution**
  - Public CI skips the internal npm/Playwright harness when those dev files are intentionally absent
  - Public README and CONTRIBUTING now describe the slim distribution model instead of the maintainer source repo
  - Public release naming is consistent as `Contracts Skill`

### Fixed

- **Public re-publish behavior** — The OSS publish workflow now force-updates the public release tag so repeated publishes of the same version also refresh the public release pipeline
- **PowerShell installer portability** — Home-directory resolution, relative path handling, temp-directory usage, and generated instruction files now work more reliably across Windows, macOS, and Linux
- **Bash installer ZIP fallback** — Downloaded archive extraction now falls back to `python3` when `unzip` is unavailable and emits clearer dependency errors
- **UI documentation** — Static UI opening instructions now cover Windows, macOS, and Linux instead of only `open`

## [2.3.0] - 2025-07-12

### Changed

- **Simplified installer** — Reduced from ~2000 to ~350 lines per script
  - 5 agents (Copilot, Claude, Cursor, Codex, Project Local) instead of 8
  - 6 parameters instead of 20+
  - Simple numbered list selection instead of checkbox UI
  - Instruction hooks always injected (no opt-out flag)

### Removed

- `setup.ps1`, `setup.sh` — Redundant auto-installer wrappers
- `installers/bootstrap-install.ps1` — Unnecessary download-and-execute wrapper
- PHP UI (`skill/ui/contracts-ui/`) — Redundant with minimal-ui
- Beads integration in installer
- Cline, Aider, OpenCode agent targets

## [2.2.0] - 2026-02-28

### Added

- **Verification Tests (Contract-Level TDD)** — Each contract now defines 1-3 high-leverage tests
  - VTs test the golden path through a module with content-level assertions
  - Chain-Verification Principle: one smart test implicitly validates multiple features
  - Tier-based VT count: core (1), standard (1-2), complex (2-3)
  - All 4 templates (core, feature, integration, utility) include `## Verification Tests` with examples
  - Decision framework and quality gates for choosing effective VTs
  - VT status tracking in CONTRACT.yaml: `defined` | `implemented` | `passing` | `failing`

- **Contract Commitment & Attestation** — Long-term binding across sessions
  - Attestation block in CONTRACT.yaml tracks contract version, VT results, and confidence
  - Confidence scoring: `high` (all VTs passing) / `medium` (some failing) / `low` (not implemented)
  - Re-verification cadence: stale attestations (>30 days) trigger preflight warnings
  - Binding rule: features cannot be marked `implemented` without VT-1 passing
  - Contract changes reset attestation confidence to `low`

### Changed

- **Preflight checks expanded** — Now includes attestation check (Step 4), VT status check (Step 5), and post-implementation attestation update
- **CONTRACT.yaml schema extended** — New `verification_tests` and `attestation` sections
- **CONTRACT.yaml.template updated** — Includes VT and attestation fields out of the box
- **SKILL.md expanded** — All 3 variants now include Contract Commitment and Verification Tests sections
- **Init-contracts workflow** — Step 5b added for VT generation with chain-verification principle, decision framework, and quality gates
- **Preflight summary** — Increased from max 5 to max 7 sentences to include attestation and VT status
- **NEVER/ALWAYS constraints** — Added VT and attestation enforcement rules
- **Sample project updated** — Example contracts include VT sections and attestation fields

## [2.1.0] - 2026-02-11

### Added

- **Two-Variant Architecture** — Base and Beads-enforced skills from the same repo
  - `skill/` — Base variant with instruction-based (advisory) enforcement
  - `skill-beads/` — Beads-enforced variant with dependency-blocking preflight tasks
  - Shared scripts, templates, AI analyzer, and UI between variants

- **Beads-Enforced Variant** (`skill-beads/`)
  - `SKILL.md` with Beads prerequisites and enforced preflight workflow
  - `contract-preflight.md` with Beads task lifecycle (`bd create`, `bd close`)
  - `init-contracts.md` with Beads setup and standing preflight task creation

- **Hash Recovery** — New section in both SKILL.md variants for recovering from corrupted `source_hash`

- **Meta-Contracts Suggestions** — Init agent now suggests project-level contracts

### Changed

- **All UI text translated to English** — Replaced German strings in `index.php`, `minimal-ui/README.md`, `contracts-ui/README.md`
- **YAML parsing improved** — Line-anchored regex for key detection, multi-quote support for hash extraction in `validate-contracts.ps1` and `contract-preflight.ps1`
- **UI startup logic simplified** — `Start-UiIfAvailable` in `init-contracts.ps1` reduced from ~87 to ~40 lines
- **README.md rewritten** — Documents both variants with comparison tables
- **skill/README.md updated** — Reflects current structure and cross-references Beads variant
- **CONTRIBUTING.md updated** — Current project structure and automated test instructions

### Fixed

- **Interactive Installer** — Enter key confirmation loop fixed
- **Agent Instructions** — Reduced from 5-13 lines to 1 line each

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
- OpenAI Codex
- Any assistant supporting custom instructions
