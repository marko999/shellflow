# Shellflow

A supervisor-worker architecture for running multiple AI agents in parallel using git worktrees, tmux, and Claude Code.

## Overview

Shellflow lets you:

1. **Plan** with a high-capability AI (supervisor mode)
2. **Spawn** multiple worker agents in isolated git worktrees
3. **Monitor** their progress from your main conversation
4. **Direct** agents with additional instructions
5. **Verify** and **merge** their work with quality gates

```
┌─────────────────────────────────────────────────────────────┐
│  SUPERVISOR (You + Claude Code)                             │
│  ════════════════════════════════════════════════════════  │
│                                                             │
│  You: "Plan the auth refactor"                              │
│  Claude: [plans, decomposes into tasks]                     │
│                                                             │
│  You: /spawn-agent auth "Implement OAuth2"                  │
│  You: /spawn-agent api "Add rate limiting"                  │
│  You: /spawn-watcher pods "kubectl get pods -w"             │
│                                                             │
│  You: /status                                               │
│  Claude: [shows all agent progress]                         │
│                                                             │
│  You: /verify                                               │
│  Claude: [runs tests, shows report, asks for merge approval]│
│                                                             │
└─────────────────────────────────────────────────────────────┘
        │
        │ controls
        ▼
┌───────┬───────┬───────┬───────┐
│ auth  │  api  │ pods  │ logs  │
│ agent │ agent │ watch │ watch │
└───────┴───────┴───────┴───────┘
```

## Quick Start

### Prerequisites

- macOS
- Git
- tmux (`brew install tmux`)
- Claude Code CLI (`npm install -g @anthropic/claude-code`)
- jq (`brew install jq`)

### Installation

**One-liner (recommended):**
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

**Set up a specific project:**
```bash
cd /path/to/your/project
~/.shellflow/scripts/install-to-project.sh
```

See [docs/USAGE.md](docs/USAGE.md) for detailed installation options.

### Basic Usage

```bash
# Start tmux session
tmux new -s shellflow

# Enter supervisor mode
claude

# Now you can:
# - Plan with Claude
# - Spawn agents: /spawn-agent <name> <task>
# - Spawn watchers: /spawn-watcher <name> <command>
# - Check status: /status
# - Send messages: /tell <name> <message>
# - Verify work: /verify
# - Merge: /merge <name>
```

## Three Modes of Operation

### Mode 1: Quick AI Questions
```bash
$ ask "what kubectl command shows pod memory?"
kubectl top pods --sort-by=memory

$ howto "find large files over 100MB"
find . -size +100M -type f
```

### Mode 2: Non-Interactive AI
```bash
# Review a diff
git diff | claude -p "review for bugs"

# Generate commit message
git diff --staged | claude -p "write commit message"

# Read-only analysis
claude -p "explain codebase" --allowedTools "Read,Glob,Grep"
```

### Mode 3: Supervisor/Orchestrator
```bash
$ claude

You: Plan the authentication refactor

Claude: Here's my plan:
1. Extract auth interfaces
2. Implement OAuth2 provider
3. Add rate limiting
4. Update tests

You: /spawn-agent auth-interfaces "Extract auth interfaces"
Claude: ✓ Agent 'auth-interfaces' spawned

You: /spawn-agent oauth "Implement OAuth2 provider"
Claude: ✓ Agent 'oauth' spawned

You: /status
Claude: [shows status of all agents]

You: /tell oauth "Use JWT for tokens"
Claude: ✓ Sent to 'oauth'

You: /verify
Claude: [runs tests, shows results]

You: /merge all
Claude: [merges verified work]
```

## Slash Commands

| Command | Description |
|---------|-------------|
| `/spawn-agent <name> <task>` | Create agent in new worktree |
| `/spawn-watcher <name> <cmd>` | Create monitoring window |
| `/check <name>` | Read agent/watcher output |
| `/tell <name> <msg>` | Send message to agent |
| `/list` | List all windows |
| `/status` | Comprehensive status report |
| `/verify` | Run verification checks |
| `/merge <name>` | Merge verified work |
| `/cleanup <name>` | Remove without merging |

## Shell Aliases

| Alias | Command | Description |
|-------|---------|-------------|
| `ask` | `claude -p` | Quick AI question |
| `howto` | `claude -p` | Get command for task |
| `sf` | `orchestrate` | Start supervisor session |
| `sfa` | `spawn-agent` | Create agent |
| `sfw` | `spawn-watcher` | Create watcher |
| `sfc` | `check-agent` | Check agent |
| `sft` | `tell-agent` | Message agent |
| `sfl` | `list-agents` | List all |
| `sfx` | `cleanup-agent` | Remove agent |

## tmux Shortcuts

| Shortcut | Action |
|----------|--------|
| `Ctrl+b S` | Toggle broadcast mode |
| `Ctrl+b A` | Create agent window |
| `Ctrl+b W` | Create watcher window |
| `Ctrl+b G` | Grid layout (4 panes) |
| `Ctrl+b \|` | Split vertical |
| `Ctrl+b -` | Split horizontal |
| `Alt+1-9` | Switch to window N |

## Agent Constraints

Worker agents are constrained by default:

**Allowed**:
- Read files (Read, Glob, Grep)
- Run tests and linters
- Git add/commit in their worktree

**Blocked**:
- Edit/Write tools (must create diffs instead)
- Destructive bash commands (rm, mv)
- System modifications

This ensures agents can work autonomously but can't make mistakes that are hard to undo.

## Directory Structure

```
shellflow/
├── .claude/
│   ├── commands/          # Slash commands
│   │   ├── spawn-agent.md
│   │   ├── spawn-watcher.md
│   │   ├── check.md
│   │   ├── tell.md
│   │   ├── list.md
│   │   ├── status.md
│   │   ├── verify.md
│   │   ├── merge.md
│   │   └── cleanup.md
│   ├── hooks/
│   │   └── agent-filter.sh  # Permission filter
│   └── settings.local.json
├── config/
│   ├── shellflow.zsh      # Shell functions
│   ├── tmux.conf          # tmux configuration
│   └── agent-settings.json
├── scripts/
│   ├── setup.sh           # Installation
│   └── uninstall.sh       # Removal
├── docs/
│   ├── ghostty-walkthrough.md
│   ├── wezterm-walkthrough.md
│   ├── warp-walkthrough.md
│   └── research-report.md
└── README.md
```

## Recommended Stack

| Component | Recommendation |
|-----------|----------------|
| Terminal | **Ghostty** (fast) or **iTerm2** (reliable) |
| Multiplexer | **tmux** |
| Shell | **Zsh** with the shellflow config |
| AI | **Claude Code** (your API key) |

## Documentation

- **[Complete Summary](docs/SUMMARY.md)** - Full implementation details, architecture, and reasoning
- **[Usage Guide](docs/USAGE.md)** - How to use Shellflow in other projects
- **[Research Report](docs/research-report.md)** - Tool comparisons and alternatives

## Alternative Tools

See [docs/research-report.md](docs/research-report.md) for detailed comparisons:

- **Worktrunk**: Simplified worktree management CLI
- **Ralph Orchestrator**: Autonomous loop-based execution
- **Auto-Claude**: Visual Kanban-based agent management
- **dmux/workmux**: Alternative multiplexing tools

## Terminal Walkthroughs

Detailed guides for setting up your terminal:

- [Ghostty Walkthrough](docs/ghostty-walkthrough.md)
- [WezTerm Walkthrough](docs/wezterm-walkthrough.md)
- [Warp Walkthrough](docs/warp-walkthrough.md)

## Troubleshooting

### Agent not responding
```bash
# Check if window exists
tmux list-windows

# Check agent output
/check <name>

# Send a status request
/tell <name> "Report your status"
```

### Worktree issues
```bash
# List worktrees
git worktree list

# Remove stuck worktree
git worktree remove --force ../worktrees/<name>
```

### tmux session lost
```bash
# List sessions
tmux list-sessions

# Reattach
tmux attach -t shellflow
```

## License

MIT
