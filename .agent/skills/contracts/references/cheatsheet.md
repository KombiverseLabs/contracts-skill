# Contracts Quick Reference

## File Locations

| File | Location | Owner | Max Lines |
|------|----------|-------|-----------|
| `CONTRACT.md` | Module root | User only | 50 (tier-dependent) |
| `CONTRACT.yaml` | Module root | AI + User | 100 (tier-dependent) |
| `registry.yaml` | `.contracts/` | AI | No limit |

## Tiers

| Tier | MD Lines | YAML Lines | Use Case |
|------|----------|------------|----------|
| `core` | 30 | 60 | Single-responsibility utilities |
| `standard` | 50 | 100 | Typical features |
| `complex` | 80 | 150 | Integrations, orchestration |

## CONTRACT.md Structure

```markdown
# [Name]
## Purpose        → 1-3 sentences
## Core Features  → Checkbox list
## Constraints    → MUST / MUST NOT rules
## Success Criteria → How to verify
```

## CONTRACT.yaml Structure

```yaml
meta:           → Hash, sync time, tier, version
module:         → Name, type, path
features:       → List with status, entry_point, tests
constraints:    → must[], must_not[]
relationships:  → depends_on[], consumed_by[]
validation:     → exports[], test_pattern, custom_script
changelog:      → History of changes
```

## Feature Status Values

| Status | Meaning |
|--------|---------|
| `planned` | Defined but not started |
| `in-progress` | Currently being implemented |
| `implemented` | Complete and tested |
| `deprecated` | Will be removed |

## Commands

| Phrase | Action |
|--------|--------|
| "init contracts" | Full initialization |
| "check contracts" | Scan all, report drift |
| "sync contracts" | Update YAMLs from MDs |
| "contract for X" | Show/create contract |
| "validate contracts" | Run validation scripts |

## PowerShell Scripts

```powershell
# Validate all contracts
.\validate-contracts.ps1 -Path "."

# Compute hash for a contract
.\compute-hash.ps1 -FilePath "src/auth/CONTRACT.md"

# Initialize contracts (dry run)
.\init-contracts.ps1 -Path "." -DryRun

# Initialize contracts (interactive)
.\init-contracts.ps1 -Path "." -Interactive
```

## AI Rules

### ❌ Never

- Edit CONTRACT.md (after init)
- Ignore hash mismatches
- Proceed against constraints
- Delete changelog entries

### ✅ Always

- Check for contracts before edits
- Sync YAML when MD changes
- Add changelog entries
- Flag constraint violations
