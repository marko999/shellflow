# Merge Agent

Merge a verified agent's work into the main branch and clean up.

## Input
`$ARGUMENTS` = `<name>` | `all`

## Prerequisites
- Agent must have STATUS: COMPLETE
- Verification must have passed (`/verify` shows green)
- User must have explicitly requested merge

## Steps

### For a specific agent:

1. **Confirm verification passed**:
   ```
   ⚠️  Pre-merge checklist for '<name>':
   - [ ] Agent reported COMPLETE
   - [ ] Tests passed
   - [ ] Lint passed
   - [ ] No merge conflicts

   Proceed with merge? (waiting for your confirmation)
   ```

2. **After user confirms, perform merge**:
   ```bash
   # Switch to main
   git checkout main

   # Pull latest
   git pull origin main

   # Merge the agent's branch
   git merge <name> --no-ff -m "Merge <name>: <task summary>"

   # Verify merge succeeded
   git log --oneline -1
   ```

3. **Clean up**:
   ```bash
   # Close the tmux window
   tmux kill-window -t <name>

   # Remove the worktree
   git worktree remove ../worktrees/<name>

   # Delete the branch
   git branch -d <name>
   ```

4. **Report**:
   ```
   ✅ Merged '<name>' into main

   Merge commit: <hash>
   Files changed: N
   Insertions: +X
   Deletions: -Y

   Cleaned up:
   - ✓ tmux window closed
   - ✓ worktree removed
   - ✓ branch deleted
   ```

### For `/merge all`:

1. **List all verified agents**

2. **Confirm with user**:
   ```
   Ready to merge 3 agents:
   1. auth-service - Implement OAuth2 login
   2. user-service - Add profile endpoints
   3. api-gateway - Add rate limiting

   Merge all? (waiting for your confirmation)
   ```

3. **Merge each sequentially** (to avoid conflicts)

4. **Report summary**:
   ```
   ✅ Merged 3 agents into main

   - auth-service: abc1234
   - user-service: def5678
   - api-gateway: ghi9012

   Total: 15 files changed, +423, -89
   ```

## If Conflicts Occur

```
❌ Merge conflict detected in '<name>'

Conflicting files:
- src/auth/login.ts
- src/utils/validation.ts

Options:
1. I can attempt to resolve automatically (risky)
2. You resolve manually, then run /merge <name> again
3. Abort and keep agent running: /tell <name> Rebase on main and fix conflicts

What would you like to do?
```
