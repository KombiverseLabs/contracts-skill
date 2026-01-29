Init Agent PoC

This PoC is a local, deterministic initializer that generates draft CONTRACT.md and CONTRACT.yaml
for detected modules. It's intentionally not an LLM-based generator (to be safe and deterministic)
but provides a clear interface for an assistant-driven workflow.

Usage examples:
  # Dry-run (show diffs)
  node skill/ai/init-agent/index.js --path . --dry-run

  # Write files after manual confirmation
  node skill/ai/init-agent/index.js --path . --apply

  # Write + commit
  node skill/ai/init-agent/index.js --path . --apply --commit

Integration notes for the assistant:
- Assistant should run the PoC in dry-run mode first, present the diffs to the user, then ask for approval.
- After approval, the assistant can run with --apply and optionally --commit to create a branch or commit.

Security note:
- The assistant must always ask for explicit user approval before running with --apply.
