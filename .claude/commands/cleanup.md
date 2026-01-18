# Cleanup

Remove agent worktrees, windows, and branches without merging.

## Input
`$ARGUMENTS` = `<name>` | `all` | `stale`

## Steps

### For a specific agent:

1. **Confirm with user**:
   ```
   ⚠️  This will DELETE without merging:
   - Worktree: ../worktrees/<name>
   - Branch: <name>
   - tmux window: <name>

   Any uncommitted work will be LOST.

   Proceed? (waiting for confirmation)
   ```

2. **After confirmation**:
   ```bash
   # Kill tmux window
   tmux kill-window -t "<name>" 2>/dev/null || true

   # Remove worktree (force)
   git worktree remove --force ../worktrees/<name> 2>/dev/null || true

   # Delete branch
   git branch -D <name> 2>/dev/null || true
   ```

3. **Report**:
   ```
   ✓ Cleaned up '<name>'
   ```

### For `/cleanup all`:

1. **List everything**:
   ```bash
   git worktree list
   tmux list-windows -F "#{window_name}"
   ```

2. **Confirm**:
   ```
   ⚠️  This will DELETE ALL agents without merging:
   - auth-service (2 commits, uncommitted changes)
   - payment-api (3 commits)
   - user-service (0 commits)

   Also closing watchers:
   - watch-pods
   - watch-logs

   Are you sure? (waiting for confirmation)
   ```

3. **Clean up each**

### For `/cleanup stale`:

Only clean up agents that:
- Have been idle for > 30 minutes
- Have no uncommitted changes
- Have no commits ahead of main

```
Found 1 stale agent:
- test-feature (idle 2h, no changes)

Clean up? (waiting for confirmation)
```
