# Shellflow

Simple, non-interactive agent orchestration for Claude Code. Human is the supervisor.

## Overview

Shellflow lets you spawn multiple autonomous Claude agents that work in parallel on isolated git worktrees. You stay in control - no AI supervisor, just simple shell commands.

```
┌─────────────────────────────────────────────────────────────┐
│  YOU (Human Supervisor)                                     │
│  ═══════════════════════════════════════════════════════    │
│                                                             │
│  $ build-specs                    # Interactive wizard      │
│  $ spawn-from-spec specs/auth.yaml  # Spawn from file      │
│  $ spawn-agent api "add rate limiting" --model haiku       │
│                                                             │
│  $ status                         # See all agents          │
│  $ progress auth                  # See agent output        │
│  $ changes                        # See all code changes    │
│                                                             │
│  $ cleanup auth                   # Done? Remove agent      │
└─────────────────────────────────────────────────────────────┘
        │
        │ spawns
        ▼
┌───────┬───────┬───────┬───────┐
│ auth  │  api  │  db   │ k8s   │
│ agent │ agent │ agent │ watch │
│(haiku)│(sonnet)│(opus)│       │
└───────┴───────┴───────┴───────┘
  Each agent runs `claude -p "task" --allowedTools "..."`
  in its own worktree, autonomously until done.
```

## Quick Start

### Prerequisites

- macOS
- Git
- tmux (`brew install tmux`)
- Claude Code CLI (`npm install -g @anthropic/claude-code`)

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

### 1. Interactive Spec Builder (Recommended)

The spec builder wizard guides you through creating agent specifications with collision detection:

```bash
$ build-specs

╔═══════════════════════════════════════════════════════════════╗
║                    SHELLFLOW SPEC BUILDER                     ║
╚═══════════════════════════════════════════════════════════════╝

How many agents do you need? 2

─────────────────────────────────────────────────────────────────
AGENT 1 of 2
─────────────────────────────────────────────────────────────────
Name: auth
What should this agent do? Implement OAuth2 login with JWT tokens
Which files/directories will it modify?
  > src/auth/
  > src/middleware/auth.ts
  >
Which files should it NOT touch?
  > src/api/*
  >
How do we verify it worked? npm test -- --grep auth
Which model? [1=haiku, 2=sonnet, 3=opus]: 1

─────────────────────────────────────────────────────────────────
COLLISION CHECK
─────────────────────────────────────────────────────────────────
✓ auth: src/auth/, src/middleware/auth.ts
✓ api: src/api/
✓ No collisions detected

Spec saved to: specs/2024-01-18-2230-auth-api.yaml
Spawn these agents now? [y/N]: y
```

### 2. Quick Agent Spawn

For simple one-off tasks:

```bash
# Basic
spawn-agent auth "implement oauth login"

# With model selection
spawn-agent api "add rate limiting" --model haiku

# With specific tools
spawn-agent fix "fix the bug" --tools "Read,Glob,Grep,Edit"
```

### 3. From Spec File

```bash
# Spawn all agents in spec
spawn-from-spec specs/my-spec.yaml

# Spawn only one agent from spec
spawn-from-spec specs/my-spec.yaml --only auth
```

### 4. Monitor Progress

```bash
# Overview of all agents
status

# See what an agent is doing
progress auth

# See code changes (colored diff)
changes          # All agents
changes auth     # Specific agent
```

### 5. Cleanup

```bash
# Remove one agent
cleanup auth

# Remove all agents
cleanup-all
```

## K8s Watchers

```bash
# Watch specific pods
watch-k8s api-pod-xxx worker-pod-xxx

# Watch pods by label
K8S_NAMESPACE=prod watch-k8s-label app=api

# Generic watcher
spawn-watcher logs "tail -f /var/log/app.log"
```

## All Commands

| Command | Alias | Description |
|---------|-------|-------------|
| `build-specs` | `bs` | Interactive spec builder wizard |
| `spawn-from-spec <file>` | `sfs` | Spawn agents from spec file |
| `spawn-agent <name> <task>` | `sa` | Spawn single agent |
| `spawn-watcher <name> <cmd>` | `sw` | Spawn command watcher |
| `watch-k8s <pods...>` | `wk` | Watch k8s pod logs |
| `watch-k8s-label <label>` | `wkl` | Watch k8s pods by label |
| `status` | `st` | Show all agents/watchers |
| `progress <name>` | | See agent output |
| `changes [name]` | | See code changes |
| `peek <name>` | | Switch to tmux window |
| `cleanup <name>` | `cu` | Remove agent + worktree |
| `cleanup-all` | | Remove all agents |

## Quick AI Helpers

```bash
# Quick question
ask "what's the kubectl command for pod memory?"

# Get just a command
howto "find large files over 100MB"

# Explain a command
explain "tar -xzvf"

# Review a diff
review                  # Review unstaged changes
review HEAD~3..HEAD     # Review last 3 commits
```

## How It Works

1. **Agents run non-interactively**: Each agent runs `claude -p "task" --allowedTools "..."` and works until done
2. **Isolated worktrees**: Each agent gets its own git worktree (branch) to avoid conflicts
3. **You review changes**: Use `changes` to see what each agent did
4. **You merge**: When satisfied, merge the agent's branch manually

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
│   └── tmux.conf          # tmux configuration
├── scripts/
│   ├── setup.sh           # Installation
│   ├── build-specs.sh     # Spec builder wizard
│   └── install-to-project.sh
└── docs/
    └── ...

your-project/
├── specs/                 # Your agent specs (gitignore this)
│   └── 2024-01-18-auth-api.yaml
└── ../worktrees/          # Agent worktrees (auto-created)
    ├── auth/
    └── api/
```

## Tips

1. **Use haiku for simple tasks** - faster and cheaper
2. **Be specific in task descriptions** - agents work better with clear scope
3. **Check `changes` before merging** - review what agents actually did
4. **Use collision detection** - `build-specs` prevents agents from conflicting

## License

MIT
