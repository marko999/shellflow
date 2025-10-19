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
sf-spawn-agent auth "implement oauth login"

# Check progress
sf-progress auth

# See code changes
sf-changes auth

# When done
sf-cleanup auth
```

Short aliases also work: `sa`, `st`, `cu`, `bs`, `sfs`.

---

## The Spec Builder (Recommended)

The interactive wizard helps you create well-structured agent specs:

```bash
sf-build-specs
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
sf-spawn-from-spec specs/my-spec.yaml

# Spawn only one agent
sf-spawn-from-spec specs/my-spec.yaml --only auth
```

### Quick Spawn (One-off)

```bash
# Basic
sf-spawn-agent auth "implement oauth login"

# With model
sf-spawn-agent api "add rate limiting" --model haiku

# With specific tools
sf-spawn-agent fix "fix the bug" --tools "Read,Glob,Grep,Edit"
```

### Model Options

- `haiku` - Fast, cheap, good for simple tasks
- `sonnet` - Default, balanced (recommended)
- `opus` - Most capable, expensive

---

## Monitoring

### Status Overview

```bash
sf-status
```

Shows all tmux windows and agent worktrees with change summary.

### Agent Output

```bash
sf-progress auth        # What is auth doing?
sf-progress auth 200    # Show more lines
```

### Code Changes

```bash
sf-changes              # All agents
sf-changes auth         # Specific agent
```

Shows colored git diff of what agents changed.

---

## Watchers

### Generic Watcher

```bash
sf-spawn-watcher logs "tail -f /var/log/app.log"
```

### K8s Pod Logs

```bash
# Specific pods
sf-watch-k8s api-pod-xxx worker-pod-xxx

# By label
K8S_NAMESPACE=prod sf-watch-k8s-label app=api
```

---

## Cleanup

```bash
sf-cleanup auth         # Remove one agent
sf-cleanup-all          # Remove all agents
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

1. **Start simple**: Try `sf-spawn-agent` before `sf-build-specs`
2. **Use haiku for simple tasks**: Faster and cheaper
3. **Be specific about scope**: Tell agents exactly which files to modify
4. **Check changes before merging**: `sf-changes` shows what agents did
5. **Use collision detection**: `sf-build-specs` prevents file conflicts

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
sf-progress <name>

# Kill and restart
sf-cleanup <name>
sf-spawn-agent <name> "task"
```

### Worktree errors

```bash
git worktree list                            # See all
git worktree remove --force ../worktrees/X   # Force remove
```
