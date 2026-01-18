# Agentic Workflow Tools - Research Report

This report summarizes research on tools for running parallel AI agents with git worktrees, terminal multiplexing, and orchestration.

## Executive Summary

For agentic workflows where a supervisor (you + high-capability AI) orchestrates multiple worker agents:

| Component | Recommended | Alternatives |
|-----------|-------------|--------------|
| Terminal | **Ghostty** or **iTerm2** | WezTerm, Warp |
| Multiplexer | **tmux** | WezTerm built-in, Warp splits |
| Worktree Management | **Worktrunk** or **manual** | workmux, dmux |
| Orchestration | **Claude Code** + slash commands | Ralph Orchestrator, Auto-Claude |
| AI Assistance | **Claude Code** (`-p` flag) | Warp AI (limited free) |

---

## Terminal Emulators Comparison

### Ghostty
- **Pros**: Fastest, native macOS (SwiftUI), simple config, low resource use
- **Cons**: Newer (fewer features), ~250MB/tab RAM
- **Best for**: Speed-focused workflows, minimal setup
- **Install**: `brew install --cask ghostty`

### iTerm2
- **Pros**: Most mature, best tmux integration (native mode), battle-tested
- **Cons**: Higher resource usage, complex settings GUI
- **Best for**: Heavy tmux users, maximum reliability
- **Install**: `brew install --cask iterm2`

### WezTerm
- **Pros**: Lua scripting, built-in multiplexer, cross-platform
- **Cons**: ~320MB RAM, feels less native on macOS
- **Best for**: Programmers who want to script their terminal
- **Install**: `brew install --cask wezterm`

### Warp
- **Pros**: Built-in AI, modern UX, block-based output
- **Cons**: Cannot use own API keys (Free/Pro), telemetry, tmux awkward
- **Best for**: Users who want integrated AI and don't mind limitations
- **Install**: `brew install --cask warp`

### Recommendation
**Ghostty** for modern/fast, **iTerm2** for reliability. Skip Warp for agentic workflows (Claude Code provides better AI integration).

---

## Worktree & Multiplexing Tools

### Worktrunk (Recommended)
**GitHub**: https://github.com/max-sixty/worktrunk

A CLI for git worktree management designed specifically for parallel AI agent workflows.

**Key Features**:
- Simplified worktree commands (`wt switch`, `wt list`, `wt merge`, `wt remove`)
- Branch-based addressing (no typing paths)
- Hooks system for automation
- Fast Rust implementation

**Installation**:
```bash
brew install max-sixty/tap/worktrunk
```

**Usage**:
```bash
# Create worktree and switch to it
wt switch --create feature-x

# Create and launch Claude
alias wsc='wt switch --create --execute=claude'
wsc auth-refactor

# List worktrees
wt list

# Merge back to main
wt merge

# Remove worktree
wt remove feature-x
```

**Why it's good for Shellflow**: Designed for exactly this use case. Minimal ceremony, works well with tmux.

### workmux
**GitHub**: https://github.com/raine/workmux

Git worktrees + tmux windows automation.

**Features**:
- One command creates worktree + tmux window
- Built-in merge workflow
- `.workmux.yaml` config

**Usage**:
```bash
workmux add my-task
workmux merge
```

### dmux
**npm**: `npm install -g dmux`

TUI for managing Claude Code sessions in tmux panes.

**Features**:
- Interactive TUI
- 4 panes in one window
- Press `n` to create, `m` to merge

**Best for**: Visual monitoring of multiple agents in one view.

### Comparison

| Tool | Style | Worktree | tmux | Best For |
|------|-------|----------|------|----------|
| **Worktrunk** | CLI | Yes | Works with | Scripting, speed |
| **workmux** | CLI | Yes | Windows | Automation |
| **dmux** | TUI | Yes | Panes | Visual monitoring |
| **Manual** | Bash | Yes | Yes | Maximum control |

---

## Orchestration Frameworks

### Ralph Orchestrator
**GitHub**: https://github.com/mikeyobrien/ralph-orchestrator
**Docs**: https://mikeyobrien.github.io/ralph-orchestrator/

An implementation of the "Ralph Wiggum technique" - continuous iteration until task completion.

**How it works**:
1. Define a task in a prompt file
2. Ralph runs an AI agent against it
3. Agent iterates until outputting completion signal
4. Configurable limits and safety controls

**Key Features**:
- Supports Claude, Q Chat, Gemini
- Loop detection (prevents infinite loops)
- Cost controls
- Two modes: Traditional (simple loop) and Hat-based (roles/personas)

**Use Cases**:
- Long-running autonomous tasks
- Tasks with clear completion criteria
- Iterative refinement

**Real-world examples**:
- Y Combinator hackathon: shipped 6 repos overnight
- $50k contract completed for $297 in API costs
- 3-month loop created a complete programming language

### Auto-Claude
**GitHub**: https://github.com/AndyMik90/Auto-Claude

A visual framework for running Claude Code as a multi-agent Kanban system.

**Key Features**:
- Kanban board interface
- Parallel agent execution in worktrees
- Context-aware engineering
- Built-in self-validation (QA agents)
- Cross-session memory

**How it works**:
1. Define tasks in Kanban
2. Auto-Claude spawns agents in worktrees
3. Each agent works independently
4. QA agents review work
5. Visual dashboard for monitoring

**Best for**: Teams wanting visual management of AI agents.

### Claude Code + Slash Commands (This Project)
The approach implemented in Shellflow:

**Key Features**:
- You stay in one conversation (supervisor)
- Spawn agents via `/spawn-agent`
- Monitor via `/status`, `/check`
- Communicate via `/tell`
- Merge via `/verify`, `/merge`

**Best for**: Maximum control, flexibility, no additional framework.

### Comparison

| Tool | Interface | Learning Curve | Control | Best For |
|------|-----------|----------------|---------|----------|
| **Ralph** | CLI | Medium | High | Autonomous long-running tasks |
| **Auto-Claude** | GUI | Low | Medium | Visual team management |
| **Shellflow** | CLI | Low | Maximum | Flexible, custom workflows |

---

## Claude Code Non-Interactive Mode

Claude Code supports headless/non-interactive operation:

### Basic Usage
```bash
# One-shot question
claude -p "What command lists large files?"

# Pipe input
cat file.txt | claude -p "Summarize this"

# With tool restrictions
claude -p "Analyze code" --allowedTools "Read,Glob,Grep"
```

### Flags

| Flag | Purpose |
|------|---------|
| `-p "prompt"` | Non-interactive mode |
| `--output-format json` | Machine-readable output |
| `--output-format stream-json` | Streaming JSON |
| `--allowedTools "A,B"` | Restrict tools |
| `--continue` | Continue last session |
| `--resume <id>` | Resume specific session |
| `--append-system-prompt` | Add custom instructions |

### Examples
```bash
# Code review
git diff | claude -p "Review for bugs"

# Generate commit message
git diff --staged | claude -p "Write commit message"

# Read-only analysis
claude -p "Explain codebase" --allowedTools "Read,Glob,Grep"

# Multi-turn
claude -p "Find performance issues"
claude -p "Now fix the database queries" --continue
```

---

## Terminal Emulator Decision Matrix

| If you want... | Choose |
|----------------|--------|
| Fastest, modern, native | **Ghostty** |
| Maximum tmux integration | **iTerm2** |
| Script everything in Lua | **WezTerm** |
| Built-in AI (limited) | **Warp** |

---

## Recommended Stack

For the agentic workflow described:

```
┌─────────────────────────────────────────────────────────────┐
│ Terminal: Ghostty or iTerm2                                 │
├─────────────────────────────────────────────────────────────┤
│ Multiplexer: tmux                                           │
├─────────────────────────────────────────────────────────────┤
│ Worktrees: Worktrunk (or manual git worktree)               │
├─────────────────────────────────────────────────────────────┤
│ Orchestration: Claude Code + Shellflow slash commands       │
├─────────────────────────────────────────────────────────────┤
│ AI: Claude Code (your API key, unlimited)                   │
└─────────────────────────────────────────────────────────────┘
```

**Why this stack**:
1. **Terminal**: Fast, reliable, doesn't interfere
2. **tmux**: Universal, proven, scriptable
3. **Worktrunk**: Purpose-built for AI workflows
4. **Shellflow**: Maximum flexibility, no framework lock-in
5. **Claude Code**: Your API key, full control

---

## Sources

### Terminal Emulators
- [Choosing a Terminal on macOS 2025](https://medium.com/@dynamicy/choosing-a-terminal-on-macos-2025-iterm2-vs-ghostty-vs-wezterm-vs-kitty-vs-alacritty-d6a5e42fd8b3)
- [Ghostty vs iTerm2](https://medium.com/@artemkhrenov/modern-terminal-emulators-ghostty-vs-iterm2-3cd5e55a8d24)
- [Warp vs Ghostty](https://thenewstack.io/warp-vs-ghostty-which-terminal-app-meets-your-dev-needs/)
- [Ghostty GitHub](https://github.com/ghostty-org/ghostty)
- [WezTerm GitHub](https://github.com/wezterm/wezterm)

### Worktree Tools
- [Worktrunk GitHub](https://github.com/max-sixty/worktrunk)
- [Worktrunk Docs](https://worktrunk.dev/)
- [workmux GitHub](https://github.com/raine/workmux)

### Orchestration
- [Ralph Orchestrator GitHub](https://github.com/mikeyobrien/ralph-orchestrator)
- [Ralph Orchestrator Docs](https://mikeyobrien.github.io/ralph-orchestrator/)
- [Auto-Claude GitHub](https://github.com/AndyMik90/Auto-Claude)
- [Claude Code Headless Mode](https://code.claude.com/docs/en/headless)
- [Claude Code Best Practices](https://www.anthropic.com/engineering/claude-code-best-practices)
