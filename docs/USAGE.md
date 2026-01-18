# Using Shellflow in Another Project

Shellflow is designed to be installed once and used across all your projects. This guide explains how to set it up.

## Quick Install (One Command)

From your target project directory:

```bash
/path/to/shellflow/scripts/install-to-project.sh
```

Or specify the target:

```bash
/path/to/shellflow/scripts/install-to-project.sh /path/to/your/project
```

This installs everything automatically.

---

## Manual Installation

If you prefer to understand what's being installed:

### Step 1: Install Global Components

These are installed once and work across all projects.

#### Shell Configuration

Add to `~/.zshrc`:
```bash
# Shellflow - Agentic Workflow
source "/path/to/shellflow/config/shellflow.zsh"
```

Then reload:
```bash
source ~/.zshrc
```

#### tmux Configuration

Add to `~/.tmux.conf` (create if doesn't exist):
```bash
# Shellflow configuration
source-file "/path/to/shellflow/config/tmux.conf"
```

Or copy it:
```bash
cp /path/to/shellflow/config/tmux.conf ~/.tmux.conf
```

#### Claude Code Slash Commands

Copy to global commands directory:
```bash
mkdir -p ~/.claude/commands
cp /path/to/shellflow/.claude/commands/*.md ~/.claude/commands/
```

#### Permission Hooks

Copy to global hooks directory:
```bash
mkdir -p ~/.claude/hooks
cp /path/to/shellflow/.claude/hooks/agent-filter.sh ~/.claude/hooks/
chmod +x ~/.claude/hooks/agent-filter.sh
```

### Step 2: Project-Specific Setup

For each project you want to use Shellflow with:

#### Create .claude directory
```bash
cd /your/project
mkdir -p .claude
```

#### Create project settings
```bash
cat > .claude/settings.json << 'EOF'
{
  "permissions": {
    "allow": [
      "Bash(git *)",
      "Bash(tmux *)",
      "Bash(ls *)",
      "Bash(cat *)"
    ]
  },
  "env": {
    "SHELLFLOW_MODE": "supervisor"
  }
}
EOF
```

#### Copy CLAUDE.md (optional but recommended)
```bash
cp /path/to/shellflow/CLAUDE.md ./CLAUDE.md
```

#### Create worktrees directory
```bash
mkdir -p ../worktrees
```

#### Update .gitignore
```bash
echo "" >> .gitignore
echo "# Shellflow worktrees" >> .gitignore
echo "../worktrees/" >> .gitignore
```

---

## What Gets Installed Where

### Global (once, in your home directory)

| Component | Location | Purpose |
|-----------|----------|---------|
| Shell functions | `~/.zshrc` (sourced) | Commands like `sa`, `check`, `tell` |
| tmux config | `~/.tmux.conf` (sourced) | Keybindings, layout settings |
| Slash commands | `~/.claude/commands/*.md` | Claude Code commands |
| Hooks | `~/.claude/hooks/agent-filter.sh` | Agent permission filter |

### Per-Project (in each repo)

| Component | Location | Purpose |
|-----------|----------|---------|
| Settings | `.claude/settings.json` | Project-specific Claude settings |
| Context | `CLAUDE.md` | Project context for Claude |
| Worktrees | `../worktrees/` | Agent worktrees (outside repo) |

---

## Directory Structure After Installation

```
~/
├── .zshrc                      # Sources shellflow.zsh
├── .tmux.conf                  # Sources shellflow tmux.conf
├── .claude/
│   ├── commands/               # Global slash commands
│   │   ├── spawn-agent.md
│   │   ├── spawn-agents.md
│   │   ├── spawn-watcher.md
│   │   ├── spawn-watchers.md
│   │   ├── broadcast.md
│   │   ├── check.md
│   │   ├── tell.md
│   │   ├── list.md
│   │   ├── status.md
│   │   ├── verify.md
│   │   ├── merge.md
│   │   └── cleanup.md
│   └── hooks/
│       └── agent-filter.sh     # Permission filter
│
├── repos/
│   ├── shellflow/              # Shellflow source (keep this!)
│   │   ├── config/
│   │   │   ├── shellflow.zsh   # ← sourced by ~/.zshrc
│   │   │   └── tmux.conf       # ← sourced by ~/.tmux.conf
│   │   └── ...
│   │
│   ├── your-project/           # Your project
│   │   ├── .claude/
│   │   │   └── settings.json
│   │   ├── CLAUDE.md
│   │   └── ...
│   │
│   └── worktrees/              # Shared worktrees directory
│       ├── auth/               # Agent worktree
│       ├── api/                # Agent worktree
│       └── ...
```

---

## Using Shellflow in Your Project

### Start a Session

```bash
cd /your/project
tmux new -s myproject
```

### Workflow

```bash
# You're in your main pane

# Quick AI question
$ ask "how do I implement rate limiting in express?"

# Enter orchestrator for longer conversation
$ oo
claude> Let's plan the rate limiting feature...
claude> exit

# Spawn agents (they go to background)
$ sa rate-limit "Implement rate limiting middleware"
$ sa tests "Write tests for rate limiting"

# Check on them
$ check rate-limit
$ tell rate-limit "Use Redis for distributed rate limiting"

# Status
$ st
```

### Cleanup

```bash
# Clean up one agent
$ cu rate-limit

# Kill a window
$ kw tests

# Exit tmux (session keeps running)
Ctrl+b d

# Reattach later
tmux attach -t myproject
```

---

## Multiple Projects

Shellflow works across multiple projects. The global components are shared, but each project has its own:
- `.claude/settings.json` for project-specific settings
- `CLAUDE.md` for project context
- Worktrees are created relative to each project

```bash
# Project A
cd ~/repos/project-a
tmux new -s project-a
# Use shellflow commands...

# Project B (in another terminal or tmux session)
cd ~/repos/project-b
tmux new -s project-b
# Use shellflow commands...
```

---

## Updating Shellflow

When Shellflow is updated:

```bash
cd /path/to/shellflow
git pull

# Slash commands update automatically (they're symlinked/copied to ~/.claude/commands/)
# If you copied them, re-copy:
cp /path/to/shellflow/.claude/commands/*.md ~/.claude/commands/

# Shell functions update automatically (sourced from shellflow dir)
# Just reload your shell:
source ~/.zshrc
```

---

## Uninstalling

### From a specific project
```bash
cd /your/project
rm -rf .claude/
rm CLAUDE.md
# Remove worktrees if desired
rm -rf ../worktrees/
```

### Global uninstall
```bash
# Run uninstall script
/path/to/shellflow/scripts/uninstall.sh

# Or manually:
# Remove from ~/.zshrc (the shellflow source line)
# Remove from ~/.tmux.conf (the shellflow source line)
# Remove ~/.claude/commands/*.md
# Remove ~/.claude/hooks/agent-filter.sh
```

---

## Troubleshooting

### "shellflow-help: command not found"
```bash
source ~/.zshrc
```

### "tmux: command not found"
```bash
brew install tmux
```

### Agents not spawning
Make sure you're in a tmux session:
```bash
tmux new -s work
```

### Worktree errors
```bash
# List existing worktrees
git worktree list

# Remove stuck worktree
git worktree remove --force ../worktrees/<name>
```
