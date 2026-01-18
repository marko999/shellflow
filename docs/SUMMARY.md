# Shellflow - Complete Implementation Summary

## What Is Shellflow?

Shellflow is a supervisor-worker architecture for running multiple AI agents in parallel. It enables you to:

1. **Stay in one terminal pane** while controlling everything
2. **Switch seamlessly** between bash, AI questions, and orchestrator mode
3. **Spawn parallel AI agents** in isolated git worktrees
4. **Monitor and direct agents** without leaving your main pane
5. **Spawn watcher dashboards** for logs, metrics, and system monitoring
6. **Broadcast commands** to multiple panes with different parameters

---

## Why We Built This

### The Problem

Running multiple AI agents in parallel for software development requires:
- **Isolation**: Agents need separate working directories to avoid conflicts
- **Orchestration**: A way to spawn, monitor, and direct multiple agents
- **Context switching**: Easy movement between bash, AI, and orchestration
- **Visibility**: Ability to see what all agents are doing without losing your place
- **Control**: Send commands to agents, check their progress, merge their work

### Existing Solutions Evaluated

| Tool | What It Does | Why We Didn't Use It |
|------|--------------|---------------------|
| **dmux** | TUI for Claude + worktrees | Interactive TUI, not scriptable |
| **workmux** | Worktrees + tmux windows | Good but adds dependency |
| **Worktrunk** | Simplified worktree CLI | Good alternative, optional |
| **Ralph Orchestrator** | Autonomous loop execution | Different paradigm (loop-based) |
| **Auto-Claude** | Visual Kanban agents | GUI-based, different workflow |
| **Warp AI** | Built-in terminal AI | Can't use own API keys (free tier) |

### Our Decision: Raw tmux + Claude Code

We chose to use **raw tmux commands** and **Claude Code** directly because:
- No additional dependencies beyond tmux and Claude Code
- Full control over behavior
- Easy to customize
- Claude Code's `-p` flag provides non-interactive AI
- tmux's `-d` flag spawns windows without switching focus

---

## Core Design Principle

> **You ALWAYS stay in your main pane.**

Everything else happens in the background:
- Agents spawn in background windows
- Watchers spawn in background windows
- Output comes TO you (via `check`)
- Commands go FROM you (via `tell`)
- You only leave your pane if you explicitly `peek`

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        YOUR MAIN PANE                           │
│                                                                 │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐ │
│  │    BASH     │  │  QUICK AI   │  │     ORCHESTRATOR        │ │
│  │             │  │             │  │                         │ │
│  │ $ ls -la    │  │ $ ask "..." │  │ $ oo                    │ │
│  │ $ git push  │  │ $ howto ... │  │ claude> plan feature    │ │
│  │ $ kubectl   │  │             │  │ claude> /spawn-agent    │ │
│  └─────────────┘  └─────────────┘  └─────────────────────────┘ │
│         ↑                ↑                    ↑                 │
│         └────────────────┼────────────────────┘                 │
│                          │                                      │
│              YOU SWITCH MODES SEAMLESSLY                        │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
                           │
                           │ spawns & controls
                           ▼
┌──────────┬──────────┬──────────┬──────────┬──────────┐
│ agent-1  │ agent-2  │ watchers │ broadcast│  ...     │
│ (window) │ (window) │ (window) │ (window) │          │
│          │          │          │          │          │
│ worktree │ worktree │ k8s/logs │ pod logs │          │
│ + claude │ + claude │ monitors │ multiple │          │
└──────────┴──────────┴──────────┴──────────┴──────────┘
      │          │
      ▼          ▼
 ../worktrees/agent-1/
 ../worktrees/agent-2/
```

---

## What We Implemented

### 1. Mode Switching (You Stay in Main Pane)

| Mode | How to Enter | How to Exit | Purpose |
|------|--------------|-------------|---------|
| **Bash** | Default | N/A | Run shell commands |
| **Quick AI** | `ask "question"` | Auto-returns | One-shot AI questions |
| **Orchestrator** | `oo` | `exit` or Ctrl+D | Extended AI conversation |

**Why**: Seamless context switching without losing your place.

### 2. Agent Spawning (Background)

| Command | What It Does |
|---------|--------------|
| `sa <name> <task>` | Single agent in worktree |
| `sas 'n1:t1' 'n2:t2' ...` | Multiple agents in 2x2 grid |

**Why**: Agents need isolation (worktrees) and shouldn't steal your focus.

**How it works**:
1. Creates git worktree at `../worktrees/<name>`
2. Creates tmux window with `-d` flag (background)
3. Starts `claude` in that window
4. Sends the task to Claude

### 3. Watcher Spawning (Background)

| Command | What It Does |
|---------|--------------|
| `sw <name> <cmd>` | Single watcher window |
| `sws k8s` | Kubernetes dashboard (pods, logs, events, top) |
| `sws docker` | Docker dashboard (ps, stats, logs) |
| `sws dev` | Dev dashboard (tests, git status, file watch) |
| `sws system` | System dashboard (htop, disk, processes) |

**Why**: Long-running monitoring shouldn't require manual setup each time.

### 4. Broadcast (Background)

| Command | What It Does |
|---------|--------------|
| `bc 'cmd {}' p1 p2 p3` | Run cmd with different params in grid |
| `wp pod1 pod2 pod3` | Watch logs from multiple pods |
| `wp -l app=api` | Auto-discover pods by selector |

**Why**: Common pattern - same command, different targets (pods, servers, files).

### 5. Control (From Your Pane)

| Command | What It Does |
|---------|--------------|
| `check <name>` | Show last 50 lines from window |
| `check <name> 100` | Show last 100 lines |
| `tell <name> <msg>` | Send message/command to window |
| `st` | Status of all windows and worktrees |
| `peek <name>` | Switch to window (Ctrl+b 0 to return) |
| `kw <name>` | Kill window |
| `cu <name>` | Cleanup agent (window + worktree + branch) |

**Why**: Control everything without leaving your main pane.

### 6. Agent Constraints (Hooks)

Worker agents are restricted via permission hooks:

**Allowed**:
- Read files (Read, Glob, Grep tools)
- Run tests and linters
- Git add/commit in their worktree
- Read-only bash commands (ls, cat, grep, etc.)

**Blocked**:
- Edit/Write tools
- Destructive bash (rm, mv, sudo)
- Package installation

**Why**: Agents work autonomously but can't make hard-to-undo mistakes.

### 7. Claude Code Slash Commands

For use when in orchestrator mode (`oo`):

| Command | Purpose |
|---------|---------|
| `/spawn-agent` | Create agent with full instructions |
| `/spawn-agents` | Create multiple agents in grid |
| `/spawn-watcher` | Create single watcher |
| `/spawn-watchers` | Create watcher dashboard |
| `/broadcast` | Broadcast with params |
| `/check` | Check window output |
| `/tell` | Send to window |
| `/list` | List all windows |
| `/status` | Full status report |
| `/verify` | QA checks before merge |
| `/merge` | Merge verified work |
| `/cleanup` | Remove without merging |

**Why**: When in Claude conversation, you can use natural language + these commands.

---

## Technology Choices

### Terminal: Ghostty or iTerm2

| Terminal | Why Consider |
|----------|--------------|
| **Ghostty** | Fast, native macOS (SwiftUI), simple config |
| **iTerm2** | Most mature, best tmux integration |

**Why not Warp**: Can't use your own API keys on free tier. Claude Code provides better AI anyway.

### Multiplexer: tmux

**Why tmux**:
- Universal, proven, scriptable
- `-d` flag creates windows without switching
- `send-keys` allows remote control
- `capture-pane` allows reading output
- Required by most agent orchestration tools anyway

### Worktree Management: Raw git

**Why not Worktrunk/workmux**:
- One less dependency
- Full control over behavior
- Simple enough with raw commands

**Alternative**: Install Worktrunk (`brew install max-sixty/tap/worktrunk`) if you prefer its UX.

### AI: Claude Code

**Why Claude Code**:
- `-p` flag for non-interactive queries
- Your own API key (no limits)
- Full coding assistant capabilities
- Slash commands for extension
- Hooks for permission control

---

## File Structure

```
shellflow/
├── .claude/
│   ├── commands/           # Claude Code slash commands (11 files)
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
│   ├── hooks/
│   │   └── agent-filter.sh  # Permission filter for agents
│   └── settings.local.json  # Project settings
│
├── config/
│   ├── shellflow.zsh       # Shell functions & aliases (MAIN FILE)
│   ├── tmux.conf           # tmux configuration
│   └── agent-settings.json # Template for constrained agents
│
├── scripts/
│   ├── setup.sh            # One-command installation
│   ├── uninstall.sh        # Clean removal
│   ├── layouts.sh          # Layout helper functions
│   └── broadcast.sh        # Broadcast standalone script
│
├── docs/
│   ├── SUMMARY.md          # This document
│   ├── research-report.md  # Tool comparisons & research
│   ├── ghostty-walkthrough.md
│   ├── wezterm-walkthrough.md
│   └── warp-walkthrough.md
│
├── README.md               # Quick start guide
├── CLAUDE.md               # Context for Claude Code
└── .gitignore
```

---

## Quick Reference Card

```
╔═══════════════════════════════════════════════════════════════════╗
║                      SHELLFLOW COMMANDS                           ║
╠═══════════════════════════════════════════════════════════════════╣
║ MODE SWITCHING (you stay in this pane):                           ║
║   oo                    Enter Claude orchestrator mode            ║
║   ask "question"        Quick AI answer                           ║
║   howto "task"          Get command for task                      ║
║   (just type)           Run bash commands directly                ║
║                                                                   ║
║ SPAWN (creates in background, you stay here):                     ║
║   sa <name> <task>         Single agent in worktree              ║
║   sas 'n1:t1' 'n2:t2'      Agent grid (2-4 agents)               ║
║   sw <name> <cmd>          Single watcher                        ║
║   sws <preset>             Watcher dashboard (k8s/docker/dev)    ║
║   bc 'cmd {}' p1 p2        Broadcast with different params       ║
║   wp pod1 pod2             Watch pod logs                        ║
║   wp -l app=api            Watch pods by selector                ║
║                                                                   ║
║ CONTROL (output comes to you, you stay here):                    ║
║   check <name>          See window output                        ║
║   tell <name> <msg>     Send message to window                   ║
║   st                    Status of all windows                    ║
║   peek <name>           Switch to window (Ctrl+b 0 to return)    ║
║   kw <name>             Kill window                              ║
║   cu <name>             Cleanup agent + worktree                 ║
║                                                                   ║
║ TMUX SHORTCUTS:                                                   ║
║   Ctrl+b 0-9            Switch to window N                       ║
║   Ctrl+b S              Toggle sync (type to all panes)          ║
║   Ctrl+b d              Detach (session keeps running)           ║
╚═══════════════════════════════════════════════════════════════════╝
```

---

## Example Workflow

```bash
# Start tmux
$ tmux new -s work

# You're in your main pane. Let's plan a feature.
$ oo
claude> I need to refactor the auth system. Help me plan it.
claude> [Claude helps plan, breaks into tasks]
claude> exit

# Spawn agents for parallel work
$ sas 'auth:Extract auth interfaces' 'jwt:Implement JWT tokens' 'tests:Write auth tests'
✓ Created 3 agents in 'agents' window (background)

# Spawn watchers for monitoring
$ sws k8s
✓ Watcher dashboard 'k8s' created (background)

# Check on an agent
$ check auth
=== auth (last 50 lines) ===
[shows agent output]

# Agent has a question - answer it
$ tell auth "Use RS256 algorithm for JWT"
✓ Sent to 'auth'

# Check overall status
$ st
╔═══════════════════════════════════════════════════════════╗
║                    SHELLFLOW STATUS                       ║
╚═══════════════════════════════════════════════════════════╝

WINDOWS:
  [0] main ← YOU ARE HERE
  [1] agents
  [2] watchers

WORKTREES:
  /path/to/repo          abc1234 [main]
  /path/to/worktrees/auth def5678 [auth]
  /path/to/worktrees/jwt  ghi9012 [jwt]
  /path/to/worktrees/tests jkl3456 [tests]

# Quick AI question without entering orchestrator
$ ask "what's the openssl command to generate RS256 keys?"
[Claude answers, you're still in bash]

# Run the command
$ openssl genrsa -out private.pem 2048

# When agents are done, clean up
$ cu auth
✓ Cleaned up 'auth'

# You never left your main pane the entire time.
```

---

## Installation

```bash
cd /path/to/shellflow
./scripts/setup.sh
source ~/.zshrc
```

This installs:
- Shell functions to `~/.zshrc`
- tmux config to `~/.tmux.conf`
- Claude Code slash commands to `~/.claude/commands/`
- Permission hooks to `~/.claude/hooks/`

---

## Uninstallation

```bash
./scripts/uninstall.sh
```

---

## Future Enhancements (Not Implemented)

1. **Worktrunk integration**: Use `wt` commands instead of raw git
2. **Auto-merge**: Automatically merge when agents complete and tests pass
3. **Agent memory**: Persist agent context between sessions
4. **Dashboard TUI**: Visual overview of all agents (like dmux)
5. **Remote agents**: Run agents on remote machines via SSH

---

## Related Tools & Resources

### Tools We Evaluated
- [Worktrunk](https://github.com/max-sixty/worktrunk) - Simplified worktree management
- [Ralph Orchestrator](https://github.com/mikeyobrien/ralph-orchestrator) - Autonomous loops
- [Auto-Claude](https://github.com/AndyMik90/Auto-Claude) - Visual agent management
- [dmux](https://www.npmjs.com/package/dmux) - TUI for Claude + worktrees
- [workmux](https://github.com/raine/workmux) - Worktrees + tmux

### Documentation
- [Claude Code Headless Mode](https://code.claude.com/docs/en/headless)
- [Claude Code Best Practices](https://www.anthropic.com/engineering/claude-code-best-practices)
- [tmux Manual](https://man7.org/linux/man-pages/man1/tmux.1.html)
- [Git Worktrees](https://git-scm.com/docs/git-worktree)

### Terminal Walkthroughs
- [Ghostty Walkthrough](./ghostty-walkthrough.md)
- [WezTerm Walkthrough](./wezterm-walkthrough.md)
- [Warp Walkthrough](./warp-walkthrough.md)
