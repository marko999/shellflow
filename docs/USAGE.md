# Using Shellflow

Shellflow is a simple CLI for spawning autonomous Claude agents. Human is the supervisor.

## Installation

### One-liner (Recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/marko999/shellflow/main/install.sh | bash
source ~/.zshrc
```

### Manual Install

```bash
git clone https://github.com/marko999/shellflow.git ~/.shellflow
~/.shellflow/scripts/setup.sh
source ~/.zshrc
```

### Per-Project Setup

If you want project-specific settings:

```bash
cd /your/project
~/.shellflow/scripts/install-to-project.sh
```

This creates:
- `specs/` directory for your agent specs
- `.gitignore` entries for worktrees

---

## Quick Start

```bash
# Start tmux session
tmux new -s work

# Spawn an agent
spawn-agent auth "implement oauth login"

# Check progress
progress auth

# See code changes
changes auth

# When done
cleanup auth
```

---

## The Spec Builder (Recommended)

The interactive wizard helps you create well-structured agent specs:

```bash
build-specs
```

It guides you through:
1. Number of agents
2. For each agent:
   - Name
   - Task description
   - Files to modify (scope)
   - Files to avoid
   - Verification command
   - Model selection (haiku/sonnet/opus)
3. Collision detection
4. Generates YAML spec file
5. Optionally spawns agents immediately

---

## Spawning Agents

### From Spec File

```bash
# Spawn all agents in spec
spawn-from-spec specs/my-spec.yaml

# Spawn only one agent
spawn-from-spec specs/my-spec.yaml --only auth
```

### Quick Spawn (One-off)

```bash
# Basic
spawn-agent auth "implement oauth login"

# With model
spawn-agent api "add rate limiting" --model haiku

# With specific tools
spawn-agent fix "fix the bug" --tools "Read,Glob,Grep,Edit"
```

### Model Options

- `haiku` - Fast, cheap, good for simple tasks
- `sonnet` - Default, balanced (recommended)
- `opus` - Most capable, expensive

---

## Monitoring

### Status Overview

```bash
status
```

Shows all tmux windows and agent worktrees with change summary.

### Agent Output

```bash
progress auth        # What is auth doing?
progress auth 200    # Show more lines
```

### Code Changes

```bash
changes              # All agents
changes auth         # Specific agent
```

Shows colored git diff of what agents changed.

---

## Watchers

### Generic Watcher

```bash
spawn-watcher logs "tail -f /var/log/app.log"
```

### K8s Pod Logs

```bash
# Specific pods
watch-k8s api-pod-xxx worker-pod-xxx

# By label
K8S_NAMESPACE=prod watch-k8s-label app=api
```

---

## Cleanup

```bash
cleanup auth         # Remove one agent
cleanup-all          # Remove all agents
```

This:
1. Kills the tmux window
2. Removes the git worktree
3. Deletes the branch

---

## Quick AI Helpers

```bash
ask "what's the command for..."    # Quick question
howto "find large files"           # Just the command
explain "tar -xzvf"                # Explain a command
review                             # Review git diff
```

---

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

      SCOPE (files you may modify):
        - src/auth/
        - src/middleware/auth.ts

      DO NOT MODIFY:
        - src/api/*

  - name: api
    model: sonnet
    task: |
      Add rate limiting to API endpoints.
      ...
```

---

## Directory Structure

```
~/.shellflow/           # Shellflow installation
├── config/
│   ├── shellflow.zsh   # Shell functions
│   └── tmux.conf       # tmux config
└── scripts/
    ├── setup.sh
    └── build-specs.sh

your-project/
├── specs/              # Your agent specs
│   └── 2024-01-18-auth-api.yaml
└── ../worktrees/       # Agent worktrees (auto-created)
    ├── auth/
    └── api/
```

---

## Tips

1. **Start simple**: Try `spawn-agent` before `build-specs`
2. **Use haiku for simple tasks**: Faster and cheaper
3. **Be specific about scope**: Tell agents exactly which files to modify
4. **Check changes before merging**: `changes` shows what agents did
5. **Use collision detection**: `build-specs` prevents file conflicts

---

## Troubleshooting

### "Command not found"

```bash
source ~/.zshrc
```

### "Not in tmux"

```bash
tmux new -s work
```

### Agent stuck

```bash
# Check what it's doing
progress <name>

# Kill and restart
cleanup <name>
spawn-agent <name> "task"
```

### Worktree errors

```bash
git worktree list                            # See all
git worktree remove --force ../worktrees/X   # Force remove
```
