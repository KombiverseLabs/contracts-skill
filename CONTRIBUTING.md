# Contributing to Contracts Skill

## Pull Requests

- Keep changes focused.
- Update docs when behavior changes.
- Keep `skill/SKILL.md` concise and move detailed workflows to `skill/references/`.
- Do not add skill-internal README files; put user-facing docs at the repository root.
- Preserve the established GitHub Actions CI/CD setup unless the maintainer explicitly changes it.

## Project Structure

```text
contracts-skill/
├── skill/
│   ├── SKILL.md
│   ├── agents/openai.yaml
│   ├── references/
│   │   ├── assistant-hooks/
│   │   ├── instruction-hooks/
│   │   ├── templates/
│   │   ├── examples/
│   │   ├── project-guide.md
│   │   ├── constitution.md
│   │   ├── spec-driven-methodology.md
│   │   ├── contract-locking.md
│   │   └── beads-enforcement.md
│   ├── scripts/
│   ├── ai/init-agent/
│   └── ui/minimal-ui/
├── installers/
├── examples/
└── .github/workflows/
```

Beads is an optional enforcement mode of `skill/`, not a separate installable skill.

## Local Setup

Maintainer checkouts include the npm/Playwright harness:

```bash
npm ci
```

## Validation

Run the same core checks CI runs:

```bash
python .github/scripts/quick_validate.py skill
```

PowerShell syntax:

```powershell
$paths = @(
  './installers/install.ps1',
  './skill/scripts/init-contracts.ps1'
)
foreach ($p in $paths) {
  $content = Get-Content $p -Raw
  [scriptblock]::Create($content) | Out-Null
}
```

Bash syntax:

```bash
bash -n installers/install.sh
bash -n skill/scripts/init-contracts.sh
```

Contract validation:

```powershell
pwsh skill/scripts/validate-contracts.ps1 -Path "examples/sample-project"
```

UI visual regression, when the Playwright harness is present:

```bash
npm run test:installer
npm run test:ui
```

## Release Notes

Update `CHANGELOG.md` under `[Unreleased]` for user-visible changes.
