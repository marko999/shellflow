# Broadcast Command

Send a command template to multiple panes with different parameters for each.

## Input
`$ARGUMENTS` = `<command template> :: <param1>, <param2>, <param3>, ...`

The `{}`placeholder in the command will be replaced with each parameter.

## Examples

### Watch multiple pod logs
```
/broadcast kubectl logs {} -f :: api-pod-1, api-pod-2, worker-pod-1, worker-pod-3
```
Creates 4 panes, each running:
- `kubectl logs api-pod-1 -f`
- `kubectl logs api-pod-2 -f`
- `kubectl logs worker-pod-1 -f`
- `kubectl logs worker-pod-3 -f`

### Check env vars in multiple pods
```
/broadcast kubectl exec {} -- env | grep DB :: pod/api-1, pod/api-2, pod/worker-1
```

### Tail multiple log files
```
/broadcast tail -f {} :: /var/log/app.log, /var/log/error.log, /var/log/access.log
```

### SSH to multiple servers
```
/broadcast ssh {} :: dev-server, staging-server, prod-server
```

### Run same git command in multiple worktrees
```
/broadcast cd ../worktrees/{} && git status :: auth, api, tests
```

## Steps

1. **Parse input**: Split on `::` to get command template and parameters
   - Command template: everything before `::`
   - Parameters: comma-separated list after `::`

2. **Create broadcast window**:
   ```bash
   tmux new-window -n "broadcast"
   ```

3. **For each parameter, create a pane**:
   ```bash
   # First param - use existing pane
   cmd="${template//\{\}/$param1}"
   tmux send-keys -t broadcast "$cmd" Enter

   # Subsequent params - split and send
   tmux split-window -t broadcast
   cmd="${template//\{\}/$param2}"
   tmux send-keys -t broadcast "$cmd" Enter
   # ... repeat
   ```

4. **Apply tiled layout**:
   ```bash
   tmux select-layout -t broadcast tiled
   ```

5. **Report**:
   ```
   ✓ Broadcast to 4 panes:

   ┌─────────────────────┬─────────────────────┐
   │ kubectl logs        │ kubectl logs        │
   │ api-pod-1 -f        │ api-pod-2 -f        │
   ├─────────────────────┼─────────────────────┤
   │ kubectl logs        │ kubectl logs        │
   │ worker-pod-1 -f     │ worker-pod-3 -f     │
   └─────────────────────┴─────────────────────┘

   View: tmux select-window -t broadcast
   Toggle sync (type to all): Ctrl+b S
   ```

## Advanced: Multiple Placeholders

For commands with multiple varying parts, use numbered placeholders:

```
/broadcast kubectl logs {1} -n {2} -f :: api-pod:production, worker-pod:staging
```

Each parameter is `value1:value2` where:
- `{1}` → `value1`
- `{2}` → `value2`

## Sync Mode (Type to All)

After broadcast, you can enable tmux sync mode to type the same thing in all panes:

```bash
# Enable (in tmux): Ctrl+b S
# Or: tmux setw -t broadcast synchronize-panes on

# Disable: Ctrl+b S again
```

This is useful for:
- Sending Ctrl+C to stop all watchers
- Typing the same filter command in all
- Running identical follow-up commands
