# List Windows

Show all active tmux windows (agents and watchers).

## Input
`$ARGUMENTS` = (optional) `agents` | `watchers` | (empty for all)

## Steps

1. **Get all windows**:
   ```bash
   tmux list-windows -F "#{window_index}|#{window_name}|#{window_active}"
   ```

2. **Get worktree info**:
   ```bash
   git worktree list
   ```

3. **Produce formatted table**:

   ```
   === Active Sessions ===

   AGENTS (in worktrees):
   | # | Name          | Worktree                    | Active |
   |---|---------------|-----------------------------|---------|
   | 2 | auth-service  | ../worktrees/auth-service   |         |
   | 3 | payment-api   | ../worktrees/payment-api    | ◀       |
   | 4 | user-service  | ../worktrees/user-service   |         |

   WATCHERS:
   | # | Name          | Purpose                     |
   |---|---------------|-----------------------------|
   | 5 | watch-pods    | kubectl get pods -w         |
   | 6 | watch-logs    | kubectl logs -f -l app=api  |

   Quick commands:
   - Switch to window: tmux select-window -t <name>
   - Check status: /check <name>
   - Send message: /tell <name> <message>
   ```

4. **If `agents` filter**: Only show agent windows
5. **If `watchers` filter**: Only show watch-* windows
