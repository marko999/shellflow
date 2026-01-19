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
spawn-agent <name> <task> [--model X] [--tools Y]
spawn-from-spec <file>   # From YAML spec

# Monitor
status                   # Overview
progress <name>          # Agent output
changes [name]           # Code diffs

# Cleanup
cleanup <name>           # Remove one
cleanup-all              # Remove all
```

## Development Notes

- Shell functions are in zsh format
- YAML parsing in spawn-from-spec is basic (grep/sed), works for our simple format
- Worktrees are created at `../worktrees/<agent-name>` relative to repo root
