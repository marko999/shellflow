# Spawn Agent

Create a new worker agent in an isolated git worktree with constrained permissions.

## Input
`$ARGUMENTS` = `<name> <task description>`

Example: `/spawn-agent auth-service Implement OAuth2 login flow with JWT tokens`

## Steps

1. **Parse arguments**: Extract `<name>` (first word) and `<task>` (rest of the line)

2. **Create worktree**:
   ```bash
   git worktree add -b "<name>" "../worktrees/<name>"
   ```

3. **Create agent constraints file** in the worktree:
   Write to `../worktrees/<name>/.claude/settings.local.json`:
   ```json
   {
     "permissions": {
       "allow": [
         "Read", "Glob", "Grep", "TodoWrite",
         "Bash(git add *)", "Bash(git commit *)", "Bash(git status)",
         "Bash(git diff *)", "Bash(git log *)", "Bash(git show *)",
         "Bash(npm test *)", "Bash(npm run *)", "Bash(pnpm *)",
         "Bash(yarn *)", "Bash(bun *)", "Bash(pytest *)",
         "Bash(go test *)", "Bash(cargo test *)", "Bash(make test *)",
         "Bash(cat *)", "Bash(ls *)", "Bash(head *)", "Bash(tail *)",
         "Bash(wc *)", "Bash(find *)", "Bash(grep *)", "Bash(rg *)"
       ],
       "deny": ["Edit", "Write", "NotebookEdit", "Bash(rm *)", "Bash(mv *)"]
     }
   }
   ```

4. **Write the worker prompt** to `/tmp/shellflow-<name>.prompt.md`:
   ```markdown
   # Worker Agent: <name>

   ## Your Task
   <task description>

   ## Constraints (STRICTLY ENFORCED)
   - You may READ any file
   - You may RUN tests and linters
   - You may GIT ADD and GIT COMMIT in this worktree only
   - You must NOT use Edit or Write tools (they will be blocked)
   - You must NOT modify files directly

   ## Workflow
   1. Analyze the task and explore the codebase
   2. Plan your changes (use TodoWrite)
   3. Create a detailed implementation plan as a patch/diff
   4. Save your proposed changes to CHANGES.md
   5. Git commit your work with a clear message
   6. Report status using this format:

   STATUS: COMPLETE | BLOCKED | QUESTION
   SUMMARY: <one line summary>
   DETAILS: <brief details or question>
   ```

5. **Create tmux window**:
   ```bash
   tmux new-window -n "<name>" -c "../worktrees/<name>"
   ```

6. **Start the constrained agent**:
   ```bash
   tmux send-keys -t "<name>" "claude" Enter
   ```

7. **Wait for Claude to initialize** (poll for the prompt to appear):
   ```bash
   # Poll up to 10 times (1 second each) for Claude's prompt
   for i in {1..10}; do
     sleep 1
     if tmux capture-pane -t "<name>" -p 2>/dev/null | grep -q "❯"; then
       break
     fi
   done
   sleep 1  # Extra buffer after prompt appears
   ```

8. **Send the task prompt**:
   ```bash
   tmux send-keys -t "<name>" "$(cat /tmp/shellflow-<name>.prompt.md)" Enter
   ```

## Confirmation
When done, output:
```
✓ Agent '<name>' spawned in worktree ../worktrees/<name>
  Task: <task summary>
  Window: tmux select-window -t <name>
```
