# Tell Agent

Send a message or instruction to a running agent.

## Input
`$ARGUMENTS` = `<name> <message>`

Examples:
- `/tell auth-service Also add rate limiting to the login endpoint`
- `/tell payment-api Use UUID for user IDs, not auto-increment`
- `/tell all Stop what you're doing and report status`

## Steps

### For a specific agent:

1. **Send the message**:
   ```bash
   tmux send-keys -t "<name>" "<message>" Enter
   ```

2. **Confirm**:
   ```
   ✓ Sent to '<name>': <message>
   ```

### For `/tell all <message>`:

1. **Get all agent windows** (exclude watch-* windows):
   ```bash
   tmux list-windows -F "#{window_name}" | grep -v "^watch-"
   ```

2. **Send to each**:
   ```bash
   for window in $windows; do
     tmux send-keys -t "$window" "<message>" Enter
   done
   ```

3. **Confirm**:
   ```
   ✓ Broadcast to N agents: <message>
     - auth-service
     - payment-api
     - user-service
   ```

## Common Instructions

### Status requests
- "Report your current status"
- "What's blocking you?"
- "Summarize your progress"

### Direction changes
- "Stop current work and focus on X instead"
- "Also consider Y when implementing"
- "Prioritize Z over other tasks"

### Answers to questions
- "Use approach A because..."
- "The correct endpoint is /api/v2/..."
- "Yes, proceed with that approach"
