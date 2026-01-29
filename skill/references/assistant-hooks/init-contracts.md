Assistant Hook: Initialize Contracts

Trigger phrases (examples):
- "Initialize contracts for this project"
- "Init contracts"
- "Create CONTRACT.md for modules"

Purpose
-------
This hook tells an AI assistant how to perform a safe, interactive initialization flow. The assistant should NOT modify files without explicit user approval.

Behavior the assistant should follow:
1. Verify that the `contracts` skill is installed in `.agent/skills/contracts` or in the assistant's skill registry. If not found, instruct the user to install using the installer.
2. Run the local init PoC in dry-run mode to obtain proposed CONTRACT drafts and diffs:
   - Command: `node .agent/skills/contracts/skill/ai/init-agent/index.js --path . --dry-run`
3. Present the diffs to the user in the conversation. Ask the user to approve file creation and (separately) whether to commit or open a PR.
4. If user approves, run with `--apply` (and `--commit` if user wants a commit):
   - Command: `node .agent/skills/contracts/skill/ai/init-agent/index.js --path . --apply --commit`
5. Report back with created files and commit/PR details.

Notes for assistant implementers
--------------------------------
- The assistant must always show diffs and receive an explicit affirmative response before creating or committing files.
- If a user requests an LLM-generated contract (more nuanced text), the assistant should request permission to use an LLM with the user's configured provider and then generate improved text, again showing diffs and asking for approval.

Example assistant message
-------------------------
"I scanned the repository and propose to create contracts for `src/core/auth` and `src/features/dashboard`. Here is a summary of planned changes: (show diffs). Do you approve creating these files? (Yes/No)"

Placement and discovery
-----------------------
The assistant should look for this file under `skill/references/assistant-hooks/init-contracts.md` in the skill and also under the installed skill path `.agent/skills/contracts/references/assistant-hooks/init-contracts.md`.
