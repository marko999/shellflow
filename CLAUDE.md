# CLAUDE.md - Shellflow Project Instructions

This file provides context to Claude Code when working in this repository.

## Project Overview

Shellflow is a supervisor-worker architecture for running multiple AI agents in parallel. The supervisor (you running Claude Code) orchestrates worker agents that run in isolated git worktrees.

## Key Concepts

1. **Supervisor Mode**: A long-running Claude Code session where you plan, spawn agents, and monitor progress
2. **Worker Agents**: Claude Code instances running in separate tmux windows with isolated worktrees
3. **Watchers**: Non-agent windows running monitoring commands (logs, resource usage, etc.)
4. **Slash Commands**: Custom commands in `.claude/commands/` for orchestration

## Available Slash Commands

- `/spawn-agent <name> <task>` - Create a worker agent
- `/spawn-watcher <name> <command>` - Create a monitoring window
- `/check <name>` - Read output from a window
- `/tell <name> <message>` - Send instruction to an agent
- `/list` - List all windows
- `/status` - Full status report
- `/verify` - Run QA checks before merge
- `/merge <name>` - Merge verified work
- `/cleanup <name>` - Remove without merging

## When Acting as Supervisor

As the supervisor, you should:

1. **Plan first**: Understand the task, break into parallel work items
2. **Spawn agents**: Use `/spawn-agent` for each independent task
3. **Monitor**: Periodically use `/status` to check progress
4. **Unblock**: Answer agent questions via `/tell`
5. **Verify**: Use `/verify` before allowing merges
6. **Merge with approval**: Only merge after user confirms

## When Spawning Agents

Each agent should receive:
- Clear, specific task description
- Constraints (what files to touch, what to avoid)
- Expected output format (STATUS: COMPLETE/BLOCKED/QUESTION)
- Verification commands to run

## Worker Agent Constraints

Worker agents are constrained (via hooks) to:
- Read any file
- Run tests and linters
- Git add/commit in their worktree
- NOT use Edit/Write tools
- NOT run destructive commands

This ensures agents work safely without supervisor intervention.

## File Structure

```
.claude/commands/   - Slash command definitions
.claude/hooks/      - Permission filter scripts
config/             - Shell and tmux configuration
scripts/            - Setup and utility scripts
docs/               - Documentation and walkthroughs
```

## Common tmux Commands (for orchestration)

```bash
# Create window
tmux new-window -n <name> -c <path>

# Send keys to window
tmux send-keys -t <name> "<command>" Enter

# Capture output
tmux capture-pane -t <name> -p -S -50

# Kill window
tmux kill-window -t <name>

# List windows
tmux list-windows -F "#{window_name}"
```

## Common git worktree Commands

```bash
# Create worktree
git worktree add -b <branch> ../worktrees/<name>

# List worktrees
git worktree list

# Remove worktree
git worktree remove ../worktrees/<name>
```

## Workflow Example

```
User: Plan a new authentication system

Supervisor: [Plans and breaks into tasks]
1. Extract auth interfaces
2. Implement JWT tokens
3. Add middleware
4. Write tests

User: Spawn agents for tasks 1-3

Supervisor:
/spawn-agent interfaces "Extract auth interfaces from current code"
/spawn-agent jwt "Implement JWT token generation and validation"
/spawn-agent middleware "Add auth middleware to API routes"

[Agents work in parallel...]

User: How's it going?

Supervisor: /status
[Reports progress of all agents]

User: The jwt agent has a question

Supervisor: /check jwt
Agent jwt asks: "Should tokens expire in 1 hour or 24 hours?"

User: Tell it 24 hours for access, 7 days for refresh

Supervisor: /tell jwt "Use 24 hour expiry for access tokens, 7 days for refresh tokens"

[Work continues...]

User: Verify and merge

Supervisor: /verify
[Runs tests, reports results]
All checks pass. Ready to merge?

User: Yes

Supervisor: /merge all
[Merges each agent's branch]
```
