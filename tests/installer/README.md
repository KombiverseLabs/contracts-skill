# Installer / Hook Integration Tests

These tests run the PowerShell installer in a sandbox (fake USERPROFILE + fake APPDATA) and validate:
- Skill installation paths per agent
- Project instruction hooks (.github/copilot-instructions.md, CLAUDE.md, etc.)
- Presence of the new contract-preflight hook
- Preflight drift detection behavior
- Quality gates (snippets contain required semantics and stay short)

Run locally:
- `npm test`
- `npm run test:installer`
