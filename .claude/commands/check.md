# Check Agent/Watcher

Read and summarize the current output from any tmux window (agent or watcher).

## Input
`$ARGUMENTS` = `<name>` (window name, with or without "watch-" prefix)

Examples:
- `/check auth-service` - Check agent progress
- `/check api-logs` - Check watcher output
- `/check all` - Check all windows

## Steps

### If checking a specific window:

1. **Capture recent output**:
   ```bash
   tmux capture-pane -t "<name>" -p -S -100
   ```

   If that fails, try with "watch-" prefix:
   ```bash
   tmux capture-pane -t "watch-<name>" -p -S -100
   ```

2. **Analyze the output**:
   - For **agents**: Look for STATUS lines, progress indicators, questions, errors
   - For **watchers**: Summarize current state, highlight anomalies

3. **Report**:
   ```
   === <name> ===
   Type: Agent | Watcher
   Status: WORKING | COMPLETE | BLOCKED | QUESTION | RUNNING

   Recent Activity:
   <summary of what's happening>

   [If agent has a question]:
   QUESTION: <the question>

   [If errors detected]:
   ERRORS: <error summary>
   ```

### If `/check all`:

1. **List all windows**:
   ```bash
   tmux list-windows -F "#{window_name}"
   ```

2. **Capture each window** (last 30 lines each)

3. **Produce summary table**:
   ```
   | Window          | Type    | Status   | Notes              |
   |-----------------|---------|----------|---------------------|
   | auth-service    | Agent   | WORKING  | Implementing OAuth  |
   | watch-pods      | Watcher | RUNNING  | 3/3 pods healthy    |
   | payment-api     | Agent   | QUESTION | Needs DB schema     |
   ```

4. **Flag anything needing attention**:
   ```
   ⚠️  Needs Attention:
   - payment-api has a question: "Should I use UUID or auto-increment for user IDs?"
   ```
