# Installer / Hook Integration Tests

These tests run the PowerShell installer in a sandbox and validate:
- explicit target installs
- compatibility profile installs without agent auto-detection
- idempotent `AGENTS.md` hooks
- Beads hook auto-selection
- optional legacy hook mirroring
- no installer-created `.contracts/` or UI project artifacts
- init helper write gating
- preflight drift detection behavior

Run locally:
- `npm test`
- `npm run test:installer`
