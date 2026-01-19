# CLAUDE.md - Shellflow Project

This file provides context for Claude Code when working in this repository.

## What is Shellflow?

Shellflow is a CLI tool for spawning multiple autonomous Claude agents that work in parallel on isolated git worktrees. The human user is always the supervisor.

## Key Concepts

1. **Non-interactive agents**: Agents run `claude -p "task" --allowedTools "..."` and work autonomously until done
2. **Git worktrees**: Each agent gets its own worktree (branch) to avoid file conflicts
3. **Spec files**: YAML files defining agent tasks, models, tools, and scope
4. **Human supervisor**: User controls everything via shell commands

## Main Files

- `config/shellflow.zsh` - All shell functions (spawn-agent, changes, progress, etc.)
- `scripts/build-specs.sh` - Interactive spec builder wizard
- `config/tmux.conf` - tmux configuration

## Shell Commands

```bash
# Spec builder
build-specs              # Interactive wizard

# Spawn agents
spawn-agent <name> <task> [--model X] [--tools Y] [--repo R]
spawn-from-spec <file>   # From YAML spec

# Monitor
status                   # Overview
progress <name>          # Agent output
changes [name]           # Code diffs

# Cleanup
cleanup <name>           # Remove one
cleanup-all              # Remove all
```

## Multi-Repo Mode

Spawn agents across different repositories by setting `SHELLFLOW_PROJECTS_ROOT`:

```bash
export SHELLFLOW_PROJECTS_ROOT=~/projects

# Spawn agents in different repos
spawn-agent api-auth "add oauth" --repo notetaker-api
spawn-agent api-rate "rate limiting" --repo notetaker-api
spawn-agent rec-fix "fix encoding" --repo notetaker-recorder

# All commands work across repos
status                    # Shows agents grouped by repo
changes                   # Shows changes across all repos
cleanup api-auth          # Finds and cleans up agent
```

Worktree structure in multi-repo mode:
```
~/projects/
├── notetaker-api/
├── notetaker-recorder/
└── worktrees/
    ├── notetaker-api/
    │   ├── api-auth/
    │   └── api-rate/
    └── notetaker-recorder/
        └── rec-fix/
```

## Development Notes

- Shell functions are in zsh format
- YAML parsing in spawn-from-spec is basic (grep/sed), works for our simple format
- Without `SHELLFLOW_PROJECTS_ROOT`, worktrees are created at `../worktrees/<agent-name>` relative to repo root
- With `SHELLFLOW_PROJECTS_ROOT`, worktrees are organized by repo under `$SHELLFLOW_PROJECTS_ROOT/worktrees/<repo>/<agent>`
