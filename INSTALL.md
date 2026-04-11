# Installation Guide

> **For AI agents**: Follow these instructions step by step to install the Contracts Skill.
> **For humans**: Copy the bootstrap prompt from the [README](./README.md#install-via-ai-agent) and paste it to your AI assistant.

**Repository:** `https://github.com/kombifyio/contracts-skill`

---

## Option A: Run the Installer Script (Recommended)

The installer auto-detects AI agents (Copilot, Claude, Cursor, Codex), lets the user choose targets, copies skill files, and injects instruction hooks.

### Detect the User's OS

Check the operating system. Then run the matching command:

### Windows / PowerShell

```powershell
irm https://raw.githubusercontent.com/kombifyio/contracts-skill/main/installers/install.ps1 | iex
```

Non-interactive (auto-detect and install to all agents):

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/kombifyio/contracts-skill/main/installers/install.ps1))) -Auto
```

### macOS / Linux / Bash

```bash
curl -fsSL https://raw.githubusercontent.com/kombifyio/contracts-skill/main/installers/install.sh | bash
```

Non-interactive:

```bash
curl -fsSL https://raw.githubusercontent.com/kombifyio/contracts-skill/main/installers/install.sh | bash -s -- --auto
```

---

## Option B: Manual Installation (If Scripts Cannot Be Run)

Use this when the agent has no terminal access or the installer scripts fail.

### Step 1: Clone the Repository

```bash
git clone --depth 1 https://github.com/kombifyio/contracts-skill.git /tmp/contracts-skill
```

If `git` is unavailable, download and extract the ZIP:

```
https://github.com/kombifyio/contracts-skill/archive/refs/heads/main.zip
```

### Step 2: Copy the `skill/` Directory

Copy the **contents** of `skill/` to the appropriate agent skill folder:

| Agent | Target Path |
|-------|-------------|
| GitHub Copilot | `~/.copilot/skills/contracts/` |
| Claude Code | `~/.claude/skills/contracts/` |
| Cursor | `~/.cursor/skills/contracts/` |
| OpenAI Codex | `~/.codex/skills/contracts/` |
| Project-local (any agent) | `./.agent/skills/contracts/` |

On Windows, `~` is `%USERPROFILE%` (e.g., `C:\Users\<name>`).

Example (Copilot on macOS/Linux):

```bash
mkdir -p ~/.copilot/skills/contracts
cp -r /tmp/contracts-skill/skill/* ~/.copilot/skills/contracts/
```

Example (Copilot on Windows PowerShell):

```powershell
$target = Join-Path $env:USERPROFILE ".copilot\skills\contracts"
New-Item -ItemType Directory -Path $target -Force | Out-Null
Copy-Item -Path "C:\temp\contracts-skill\skill\*" -Destination $target -Recurse -Force
```

Install to multiple agents by copying to each target path.

### Step 3: Verify Installation

Confirm `SKILL.md` exists at the target path:

```bash
test -f ~/.copilot/skills/contracts/SKILL.md && echo "OK" || echo "MISSING"
```

### Step 4: Clean Up

```bash
rm -rf /tmp/contracts-skill
```

---

## Post-Installation

After successful installation, tell the user:

> **Contracts Skill installed successfully.** Say "init contracts" to set up contracts for your project.

---

## Choosing a Variant

The repository contains two variants:

| Variant | Source Directory | When to Use |
|---------|----------------|-------------|
| **Base** (default) | `skill/` | Any project — advisory enforcement via instructions |
| **Beads-Enforced** | `skill-beads/` | Projects using [Beads](https://github.com/steveyegge/beads) — structural enforcement via dependency blocking |

The installer uses the base variant by default. For the Beads variant, copy `skill-beads/` instead of `skill/` to the target path.

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| `git clone` fails (access denied) | This is a **public** repository. Check network/proxy settings. |
| Installer exits without detecting agents | Run with explicit agent: `--agents copilot` (bash) or `-Agents "copilot"` (PS1) |
| Skill not detected after install | Restart the editor. Verify `SKILL.md` exists in the target skill folder. |
| Permission denied on `~/.copilot/` | Create the parent directory first: `mkdir -p ~/.copilot/skills/` |
