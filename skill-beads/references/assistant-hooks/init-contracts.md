# Contract Initialization (AI-Assisted) — Beads-Enforced

**Trigger phrases:** "init contracts", "initialize contracts", "set up contracts", "analyze my project for contracts"

---

## Prerequisites

- Beads must be initialized in the project (`.beads/` directory, `bd` CLI available)
- If Beads is not initialized, run `bd init` before proceeding

## Quick Start

1. Verify Beads is initialized (`bd status`)
2. Verify skill is installed (look for `SKILL.md` in skill directory)
3. Run semantic analysis on the project
4. Present recommendations with reasoning
5. Generate drafts for user review
6. Create files ONLY after explicit user approval
7. Create Beads preflight task for ongoing enforcement

```bash
# CLI alternative
node .github/skills/contracts/ai/init-agent/index.js --path . --analyze
node .github/skills/contracts/ai/init-agent/index.js --path . --apply --yes
```

---

## The Initialization Flow

### Step 1: Project Discovery

Detect project type from config files (package.json, pyproject.toml, go.mod, Cargo.toml).
Scan source directories (src/, lib/, app/). Map module boundaries.

### Step 2: Semantic Module Analysis

For each potential module, evaluate:
- **Code volume**: lines, file count → module importance
- **Complexity**: subdirectory depth → tier assignment
- **Public API**: exports, entry points → feature extraction
- **Test coverage**: test file presence → maturity signal
- **Relationships**: import patterns → dependency mapping

### Step 3: Score and Recommend

```javascript
score = (lineCount / 10) + (subDirCount * 5) + (hasEntryPoint ? 10 : 0)
      + (hasTests ? 10 : 0) + (exportCount * 2) + (isCoreType ? 20 : 0)
```

| Tier | Criteria | CONTRACT.md Limit |
|------|----------|-------------------|
| core | < 100 lines, ≤ 1 subdirectory | 30 lines |
| standard | 100-500 lines, 2-3 subdirectories | 50 lines |
| complex | > 500 lines, > 3 subdirectories | 80 lines |

Module type by path: core/ → core, features/ → feature, integration/ → integration, util/ → utility.

### Step 4: Present Recommendations

Show user a table with module name, type, tier, reason (why this module needs a contract).
Ask: "Generate drafts for all, select specific, add unlisted, or skip?"

### Step 5: Generate and Review Drafts

For each approved module:
1. Use appropriate template (core/feature/integration/utility)
2. Fill Purpose from code analysis (NOT just listing exports — describe the user problem)
3. Fill Features from detected exports, map to test files
4. Generate testable Success Criteria (Given/When/Then, not "works correctly")
5. **Generate Verification Tests** (see Step 5b below)
6. Mark as `<!-- DRAFT: Review and modify, then remove this line -->`
7. Present draft to user for approval before creating files

### Step 5b: Generate Verification Tests

This is the most critical step. VTs make contracts enforceable long-term.

**The Process:**
1. **Understand the golden path**: What does a real user DO first with this module?
2. **Trace the chain**: What features MUST work for that action to succeed?
3. **Find the content assertion**: What concrete output proves it all worked? Not "no error" — actual text, value, or state.
4. **Write the VT**: Scenario → Action → Verify → Proves

**The Chain-Verification Principle:**
A good VT is like pulling a thread — if ANY link breaks, the test fails:
```
User action → Feature A → Feature B → Feature C → Observable output
                 ↓            ↓            ↓            ↓
              If broken,   If broken,   If broken,   We check THIS
              test fails   test fails   test fails   specific value
```

**Decision Framework:**

| Question | Guides |
|----------|--------|
| What does a user do FIRST? | → VT-1 scenario |
| What output proves it WORKED? | → VT-1 verify |
| Longest feature chain needed? | → VT-1 proves list |
| Most dangerous failure mode? | → VT-2 scenario |
| Secondary path power users use? | → VT-3 (complex only) |

**Concrete Examples:**

| Module Type | Verify Assertion | Implicitly Tests |
|-------------|------------------|------------------|
| Chat Agent | Response contains factual answer | Auth, session, UI, API, LLM, rendering |
| Auth Module | Token decodes to correct user ID | Hashing, storage, login, token gen |
| Payment API | Transaction ID matches `txn_[a-z0-9]+` | Auth, formatting, API call, parsing |
| Dashboard | Widget shows correct user name | Auth, data fetch, render, state mgmt |

**Quality Gate for VTs:**

| Pass | Fail |
|------|------|
| Checks specific text/value/state | Checks "not null" or "status 200" |
| Proves list includes 3+ features | Only tests one function |
| Realistic user action | Trivial test data |
| Exact expected value defined | "Works correctly" |

### Step 6: Create Files

After explicit approval:
1. Create CONTRACT.md files (marked DRAFT)
2. Create CONTRACT.yaml files with computed hashes
3. Create/update `.contracts/registry.yaml`
4. Present summary with next steps

---

## Quality Gates for Generated Contracts

A good contract draft must pass these checks:

| Gate | Pass | Fail |
|------|------|------|
| **Purpose** | Describes user problem solved | Just lists exports or function names |
| **Features** | Each maps to a test file (or "TODO") | No test mapping |
| **Constraints** | Testable, measurable MUST/MUST NOT | Vague ("handle errors gracefully") |
| **Success Criteria** | Given/When/Then or specific metric | "Module works correctly" |
| **Verification Tests** | Content assertion on golden-path output | "No errors", "status 200", or missing |

### Good vs Bad Examples

**Purpose — GOOD:**
> Manages user authentication state to enable secure access across the application. Handles login, session persistence, and token refresh.

**Purpose — BAD:**
> Provides login, logout, validateSession, refreshToken functions.

**Success Criteria — GOOD:**
> - Given valid credentials, when login() is called, then returns session token within 200ms
> - Given expired token, when validateSession() is called, then returns false and triggers refresh

**Success Criteria — BAD:**
> - Module functions as expected and integrates with the rest of the application.
> - All tests pass.

**Constraints — GOOD:**
> - MUST: Hash passwords with bcrypt (min 12 rounds)
> - MUST NOT: Store plain-text passwords in any storage layer

**Constraints — BAD:**
> - MUST: Follow project coding standards
> - MUST: Have comprehensive test coverage

**Verification Test — GOOD:**
> **VT-1: Chat produces verified factual response**
> - Scenario: Authenticated user sends a factual question through chat UI
> - Action: Login with test creds → open chat → send "What is the capital of France?"
> - Verify: Response text contains "Paris"
> - Proves: Auth, session, chat UI, message pipeline, LLM integration, response rendering

**Verification Test — BAD:**
> **VT-1: Chat works**
> - Scenario: User sends a message
> - Action: Send message to chat
> - Verify: Response is not empty
> - Proves: Chat feature

*Why it's bad: "Not empty" proves nothing — an error message is also "not empty". No chain coverage.*

---

## Handling Special Cases

### Monorepos
Analyze from root. Present packages as top-level modules. Offer to drill into specific packages.

### Existing Contracts
Report existing contracts. Only recommend new ones for uncovered modules.

### Non-Standard Structures
Fall back to complexity-based detection. Show top candidates by line count. Let user specify directories.

### Meta-Contracts (Optional)
For project-wide standards (testing policy, deployment, dev workflow), suggest meta-contracts in `.contracts/`.

---

## Error Handling

| Error | Response |
|-------|----------|
| No modules detected | Offer manual directory selection or single project-wide contract |
| analyzer.js not found | Guide user to reinstall skill |
| Permission errors | Continue with accessible files, note skipped directories |
| Existing contracts found | Show existing, recommend only gaps |
| Beads not initialized | Run `bd init` before proceeding |

---

## Post-Initialization: Beads Setup

After contracts are created, set up Beads enforcement:

```bash
# Create the standing preflight task
bd create "PREFLIGHT: Check CONTRACT.md before code changes" -p 0 --tag contracts --design "Before implementing ANY feature or fix:
1. Identify affected module(s) by path
2. Read MODULE/CONTRACT.md (user-owned spec)
3. Read MODULE/CONTRACT.yaml and verify source_hash matches
4. Summarize MUST/MUST NOT constraints (max 5 sentences)
5. If drift detected, sync YAML before proceeding
This task should be a dependency for all feature work."
```

This task blocks all feature work until a preflight check is completed. Each new implementation cycle requires closing and re-creating this task.

## Post-Initialization Next Steps

1. Review each CONTRACT.md — remove `<!-- DRAFT -->` when satisfied
2. Adjust features, constraints, success criteria
3. **Review Verification Tests critically** — for each VT ask:
   - "If this passes, am I confident the module works?" → if not, strengthen assertion
   - "Does Verify check actual content or just existence?" → content is mandatory
   - "How many features would break this test?" → aim for 3+ (chain coverage)
4. Use "check contracts" to verify sync status
5. Use "contract preflight" before implementing features (enforced via Beads)
6. **Implement VT-1 for each contract** as the first development step
7. Attestation initializes automatically after first VT pass
