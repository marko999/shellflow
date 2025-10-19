# Shellflow

Parallel AI agents in isolated git worktrees. You supervise, they code.

## Overview

Shellflow spawns multiple autonomous Claude Code agents that work in parallel, each in its own git worktree. No AI supervisor -- just shell commands and you.

```
┌─────────────────────────────────────────────────────────────┐
│  YOU (Human Supervisor)                                     │
│  ═══════════════════════════════════════════════════════    │
│                                                             │
│  $ sf-build-specs                # Interactive wizard       │
│  $ sf-spawn-from-spec specs/auth.yaml                       │
│  $ sf-spawn-agent api "add rate limiting" --model haiku    │
│                                                             │
│  $ sf-status                     # See all agents           │
│  $ sf-progress auth              # See agent output         │
│  $ sf-changes                    # See all code changes     │
│                                                             │
│  $ sf-cleanup auth               # Done? Remove agent       │
└─────────────────────────────────────────────────────────────┘
        │
        │ spawns
        ▼
┌───────┬───────┬───────┐
│ auth  │  api  │  db   │
│ agent │ agent │ agent │
│(haiku)│(sonnet)│(opus)│
└───────┴───────┴───────┘
  Each agent runs `claude -p "task" --allowedTools "..."`
  in its own worktree, autonomously until done.
```

## Quick Start

### Prerequisites

- macOS
- Git
- tmux (`brew install tmux`)
- Claude Code CLI (`npm install -g @anthropic-ai/claude-code`)

### Installation

**One-liner:**
```bash
curl -fsSL https://raw.githubusercontent.com/marko999/shellflow/main/install.sh | bash
source ~/.zshrc
```

**Or clone manually:**
```bash
git clone https://github.com/marko999/shellflow.git ~/.shellflow
~/.shellflow/scripts/setup.sh
source ~/.zshrc
```

## Usage

### 1. Interactive Spec Builder

The spec builder wizard creates agent specifications with collision detection:

```bash
$ sf-build-specs

╔═══════════════════════════════════════════════════════════════╗
║                    SHELLFLOW SPEC BUILDER                     ║
╚═══════════════════════════════════════════════════════════════╝

How many agents do you need? 2

AGENT 1 of 2
─────────────────────────────────────────────────────────────────
Name: auth
What should this agent do? Implement OAuth2 login with JWT tokens
Which files/directories will it modify?
  > src/auth/
  > src/middleware/auth.ts
  >

COLLISION CHECK
─────────────────────────────────────────────────────────────────
✓ auth: src/auth/, src/middleware/auth.ts
✓ api: src/api/
✓ No collisions detected

Spec saved to: specs/2024-01-18-2230-auth-api.yaml
Spawn these agents now? [y/N]: y
```

### 2. Quick Agent Spawn

```bash
# Basic
sf-spawn-agent auth "implement oauth login"

# With model selection
sf-spawn-agent api "add rate limiting" --model haiku

# With specific tools
sf-spawn-agent fix "fix the bug" --tools "Read,Glob,Grep,Edit"
```

### 3. From Spec File

```bash
# Spawn all agents in spec
sf-spawn-from-spec specs/my-spec.yaml

# Spawn only one agent from spec
sf-spawn-from-spec specs/my-spec.yaml --only auth
```

### 4. Monitor Progress

```bash
# Overview of all agents
sf-status

# See what an agent is doing
sf-progress auth

# See code changes (colored diff)
sf-changes          # All agents
sf-changes auth     # Specific agent
```

### 5. Cleanup

```bash
# Remove one agent
sf-cleanup auth

# Remove all agents
sf-cleanup-all
```

## All Commands

| Command | Alias | Description |
|---------|-------|-------------|
| `sf-build-specs` | `bs` | Interactive spec builder wizard |
| `sf-spawn-from-spec <file>` | `sfs` | Spawn agents from spec file |
| `sf-spawn-agent <name> <task>` | `sa` | Spawn single agent |
| `sf-spawn-watcher <name> <cmd>` | `sw` | Spawn command watcher |
| `sf-status` | `st` | Show all agents/watchers |
| `sf-progress <name>` | | See agent output |
| `sf-changes [name]` | | See code changes |
| `sf-diff-agent <name>` | `da` | Diff agent branch vs main |
| `sf-list-agents` | `la` | List all agents across repos |
| `sf-peek <name>` | | Switch to tmux window |
| `sf-cleanup <name>` | `cu` | Remove agent + worktree |
| `sf-cleanup-all` | | Remove all agents |

### Quick AI Helpers

```bash
ask "what's the kubectl command for pod memory?"
howto "find large files over 100MB"
explain "tar -xzvf"
review                  # Review unstaged changes
review HEAD~3..HEAD     # Review last 3 commits
```

## How It Works

1. **Agents run non-interactively**: Each agent runs `claude -p "task" --allowedTools "..."` and works until done
2. **Isolated worktrees**: Each agent gets its own git worktree (branch) to avoid conflicts
3. **You review changes**: Use `sf-changes` to see what each agent did
4. **You merge**: When satisfied, merge the agent's branch manually

## Multi-Repo Mode

```bash
export SHELLFLOW_PROJECTS_ROOT=~/projects

sf-spawn-agent api-auth "add oauth" --repo notetaker-api
sf-spawn-agent rec-fix "fix encoding" --repo notetaker-recorder

sf-status        # Shows agents grouped by repo
sf-changes       # Shows changes across all repos
```

## Spec File Format

```yaml
# specs/my-project.yaml
agents:
  - name: auth
    model: haiku
    tools: Read,Glob,Grep,Edit,Write,Bash
    verify: npm test -- --grep auth
    task: |
      Implement OAuth2 login flow.
      - Add /auth/login endpoint
      - Use JWT tokens with 24h expiry

      SCOPE (files you may modify):
        - src/auth/
        - src/middleware/auth.ts

      DO NOT MODIFY:
        - src/api/*
        - src/db/*

  - name: api
    model: sonnet
    ...
```

## Directory Structure

```
~/.shellflow/
├── config/
│   ├── shellflow.zsh      # Shell functions (source this)
│   ├── tmux.conf          # tmux configuration
│   └── agent-settings.json
├── scripts/
│   ├── setup.sh           # Installation
│   ├── build-specs.sh     # Spec builder wizard
│   ├── install-to-project.sh
│   └── ...
└── .claude/
    ├── commands/          # Slash commands for Claude Code
    └── hooks/             # Permission hooks for agents

your-project/
├── specs/                 # Your agent specs (gitignore this)
│   └── 2024-01-18-auth-api.yaml
└── ../worktrees/          # Agent worktrees (auto-created)
    ├── auth/
    └── api/
```

## License

MIT
