# Reddit Post: Contracts Skill Launch

**Title:**

> I built a skill that keeps AI assistants aligned with your specs — even on long, complex projects [open source]

---

**Body:**

AI coding assistants are great at building things fast. But I kept running into the same problem: **production readiness on complex projects.**

The first 80% goes fine. Then things get messy. The AI starts ignoring constraints you defined weeks ago. Features drift from the spec. Edge cases get skipped. The bigger the project, the worse it gets.

I wanted to fix this for myself — not with better prompts (those are session-scoped and forgotten), but with something **persistent and verifiable**.

So I built **Contracts**: a skill that gives every module in your project a living specification the AI checks before touching code. Hash-verified drift detection, verification tests that prove the module works, and attestation that tracks implementation health across sessions.

For me, it's what makes the last 20% manageable — even on larger projects with many modules. Maybe it's helpful for others too.

### How it works: You write specs, the AI tracks everything else

The core idea is a clean separation between **what you define** and **what the AI maintains**:

- `CONTRACT.md` — **yours.** Plain natural language. Purpose, features, constraints, verification tests. This is the only file you ever need to touch.
- `CONTRACT.yaml` — **the AI's job.** Auto-generated technical metadata: implementation status, drift detection (SHA256 hash), attestation, test results. You don't need to care about this file.

You change your requirements? Just edit the `.md`. The AI detects the change (hash mismatch), stops, syncs the YAML, and tells you what shifted before continuing. No manual bookkeeping.

### Get Started

**Install** (one-liner):
```bash
# Bash
curl -fsSL https://raw.githubusercontent.com/KombiverseLabs/contracts-skill/main/installers/install.sh | bash

# PowerShell
irm https://raw.githubusercontent.com/KombiverseLabs/contracts-skill/main/installers/bootstrap-install.ps1 | iex
```

The installer detects your AI assistants (Copilot, Claude, Cursor, Windsurf, Cline, Aider, OpenCode) and configures accordingly.

**Initialize:**

Ask your AI assistant:
> "Initialize contracts for this project"

It analyzes your codebase, suggests which modules should get contracts, and generates drafts. Your project should have at least a basic scaffolding/structure planned — contracts work at the module level, so you need module boundaries.

### Contracts UI: Quick overview

There's a lightweight UI you can optionally install alongside contracts. It gives you a visual overview of your modules — which contracts exist, what's implemented, what's drifting — and lets you edit contracts directly.

My recommendation: when you start a project, walk through each module's contract once. Define your constraints, write your verification tests. That upfront investment has saved me a lot of rework later on.

### Two variants: with and without Beads

I built this on top of the [Beads framework](https://github.com/steveyegge/beads) — persistent task management for AI agents. With Beads, the contract preflight check *structurally blocks* the AI from starting work until specs are verified. It's not a suggestion, it's enforcement.

I use the Beads variant exclusively and honestly can't recommend it enough. The combination of spec-driven + test-driven + persistent task management is what works for me.

That said, not everyone uses or wants Beads, so there's a **base variant** that works purely through instructions — no dependencies. I haven't used it much myself, but I've gotten positive feedback from people who do.

### Side benefit: Single source of truth

Something I didn't plan for: contracts ended up being my documentation backbone. When every module has a clear `CONTRACT.md` with purpose, features, and constraints — that's not just a spec, it's living documentation that stays current (because the AI can't work without checking it). When you have many concepts or modules referencing each other, it helps to have one place where things are defined — instead of scattered across prompt history and old chat sessions.

**GitHub**: https://github.com/KombiverseLabs/contracts-skill

This came from solving my own problem. It's not a silver bullet — complex projects are still complex. But it's helped me stay on track, and if it's useful for someone else, great.

Happy to answer questions.
