# Spawn Multiple Agents (Grid Layout)

Create multiple worker agents at once in a pre-configured grid layout.

## Input
`$ARGUMENTS` = Comma-separated or newline-separated list of `<name>:<task>` pairs

Examples:
```
/spawn-agents auth:Implement OAuth, api:Add rate limiting, tests:Write integration tests
```

Or:
```
/spawn-agents
auth: Implement OAuth login
api: Add rate limiting
tests: Write integration tests
db: Optimize queries
```

## Steps

1. **Parse the task list** into name/task pairs

2. **Create the agent window with grid layout**:
   ```bash
   # Create main window for agents
   tmux new-window -n "agents"
   ```

3. **For each agent (up to 4 for 2x2 grid, up to 6 for 2x3)**:

   a. Create worktree:
   ```bash
   git worktree add -b "<name>" "../worktrees/<name>"
   ```

   b. If not first pane, split appropriately:
   ```bash
   # For 2x2 grid:
   # Pane 1: initial (top-left)
   # Pane 2: split horizontal (top-right)
   # Pane 3: select pane 0, split vertical (bottom-left)
   # Pane 4: select pane 2, split vertical (bottom-right)

   # Agent 2: split right
   tmux split-window -h -t agents

   # Agent 3: go to pane 0, split down
   tmux select-pane -t agents.0
   tmux split-window -v -t agents

   # Agent 4: go to pane 2, split down
   tmux select-pane -t agents.2
   tmux split-window -v -t agents
   ```

   c. Send commands to each pane:
   ```bash
   tmux send-keys -t agents.<pane_number> "cd ../worktrees/<name> && claude" Enter
   # Wait, then send task
   sleep 2
   tmux send-keys -t agents.<pane_number> "<task prompt>" Enter
   ```

4. **Apply tiled layout for even sizing**:
   ```bash
   tmux select-layout -t agents tiled
   ```

5. **Report**:
   ```
   ✓ Created agent grid with N agents:

   ┌─────────────┬─────────────┐
   │ auth        │ api         │
   │ OAuth login │ rate limit  │
   ├─────────────┼─────────────┤
   │ tests       │ db          │
   │ integration │ optimize    │
   └─────────────┴─────────────┘

   View: tmux select-window -t agents
   Check all: /status
   ```

## Layout Reference

**2 agents**: side by side
```
┌───────┬───────┐
│   1   │   2   │
└───────┴───────┘
```

**3 agents**: top 2, bottom 1
```
┌───────┬───────┐
│   1   │   2   │
├───────┴───────┤
│       3       │
└───────────────┘
```

**4 agents**: 2x2 grid
```
┌───────┬───────┐
│   1   │   2   │
├───────┼───────┤
│   3   │   4   │
└───────┴───────┘
```

**5-6 agents**: use tiled layout
```
┌─────┬─────┬─────┐
│  1  │  2  │  3  │
├─────┼─────┼─────┤
│  4  │  5  │  6  │
└─────┴─────┴─────┘
```
