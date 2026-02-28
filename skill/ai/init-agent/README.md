# Init Agent

Local, deterministic initializer that generates draft `CONTRACT.md` and `CONTRACT.yaml`
for detected modules. Intentionally not LLM-based (safe and deterministic) but provides
a clear interface for an assistant-driven workflow.

## Usage

```bash
# Analyze project and show recommendations
node skill/ai/init-agent/index.js --path . --analyze

# Dry-run (show what would be created)
node skill/ai/init-agent/index.js --path . --dry-run

# Write files after manual confirmation
node skill/ai/init-agent/index.js --path . --apply

# Write + commit
node skill/ai/init-agent/index.js --path . --apply --commit
```

## What It Does

1. Detects project type (Node.js, Python, Go, Rust)
2. Scans source directories for modules
3. Scores modules by complexity, exports, and test coverage
4. Generates contract drafts with purpose, features, constraints, success criteria, and verification tests
5. Presents recommendations for user approval

## Integration

The assistant should run in dry-run mode first, present the diffs to the user, then ask for approval.
After approval, the assistant can run with `--apply` to create files.

**Important**: Always ask for explicit user approval before running with `--apply`.
