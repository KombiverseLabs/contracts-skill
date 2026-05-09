# Contract Locking

Use this reference when a user wants approved contracts to be read-only for agents, or asks to lock/unlock contract files after human review.

Contract locking is an optional StackKit guardrail. It protects `CONTRACT.md` from accidental agent edits after human approval. It is not a complete security boundary when the agent and human share the same OS user.

## Default Policy

- Lock `CONTRACT.md` after the human approves the contract text.
- Keep `CONTRACT.yaml` writable by default because it is AI-maintained for hashes, VT status, and attestation.
- If a locked `CONTRACT.md` needs changes, propose a diff or draft first. Do not unlock or edit it unless the user explicitly approves.
- After an approved human/UI edit, sync `CONTRACT.yaml`, validate hashes, and lock `CONTRACT.md` again.

## Commands

Linux/macOS:

```bash
skill/scripts/lock-contracts.sh --path .
skill/scripts/unlock-contracts.sh --file src/core/auth/CONTRACT.md
```

Windows/PowerShell:

```powershell
pwsh skill/scripts/lock-contracts.ps1 -Path .
pwsh skill/scripts/unlock-contracts.ps1 -Files src/core/auth/CONTRACT.md
```

Use `--include-yaml` / `-IncludeYaml` only when the project intentionally locks `CONTRACT.yaml` too.

## Platform Semantics

- Linux: `lock-contracts.sh` uses `chmod a-w`; `unlock-contracts.sh` uses `chmod u+w`.
- macOS: the Bash scripts use the same POSIX permissions as Linux. Stronger `chflags uchg` locking is intentionally not the default because it is easier to leave files stuck during normal development.
- Windows: PowerShell scripts use the file `ReadOnly` attribute as a best-effort guardrail. For hard enforcement, run agents as a separate OS user and manage NTFS ACLs outside the skill.

## Agent Behavior

When a locked `CONTRACT.md` is encountered:

1. Treat it as human-owned and read-only.
2. Never bypass the lock to make a direct edit.
3. Draft proposed changes separately and ask for approval.
4. Run unlock only after explicit approval for that contract edit.
5. Re-lock after the approved edit and YAML sync are complete.
