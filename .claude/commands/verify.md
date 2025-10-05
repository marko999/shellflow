# Verify Agents

Run verification checks on all completed agents before allowing merge.

## Input
`$ARGUMENTS` = (optional) `<name>` for specific agent, or empty for all completed

## Steps

1. **Identify completed agents** (those reporting STATUS: COMPLETE):
   ```bash
   # Check each agent window for completion status
   for agent in $(tmux list-windows -F "#{window_name}" | grep -v "^watch-"); do
     output=$(tmux capture-pane -t "$agent" -p -S -20)
     if echo "$output" | grep -q "STATUS: COMPLETE"; then
       echo "$agent"
     fi
   done
   ```

2. **For each completed agent, run verification**:

   a. **Check git status**:
   ```bash
   cd ../worktrees/<name>
   git status --short
   git diff --stat main
   ```

   b. **Run tests** (detect test runner):
   ```bash
   # Try common test commands
   if [ -f package.json ]; then npm test; fi
   if [ -f pytest.ini ] || [ -d tests ]; then pytest; fi
   if [ -f go.mod ]; then go test ./...; fi
   if [ -f Cargo.toml ]; then cargo test; fi
   if [ -f Makefile ]; then make test; fi
   ```

   c. **Run linter** (detect linter):
   ```bash
   if [ -f package.json ]; then npm run lint 2>/dev/null || true; fi
   if [ -f .pylintrc ] || [ -f pyproject.toml ]; then ruff check . || pylint .; fi
   if [ -f .golangci.yml ]; then golangci-lint run; fi
   ```

   d. **Check for merge conflicts**:
   ```bash
   git fetch origin main
   git merge-tree $(git merge-base HEAD origin/main) origin/main HEAD
   ```

3. **Produce verification report**:

   ```
   ╔══════════════════════════════════════════════════════════════╗
   ║                   VERIFICATION REPORT                        ║
   ╠══════════════════════════════════════════════════════════════╣

   ┌─────────────────────────────────────────────────────────────┐
   │ auth-service                                                │
   ├──────────────┬──────────────────────────────────────────────┤
   │ Tests        │ ✅ PASSED (24 tests)                         │
   │ Lint         │ ✅ PASSED                                     │
   │ Conflicts    │ ✅ NONE                                       │
   │ Files Changed│ 5 files (+142, -23)                          │
   │ Commits      │ 3                                             │
   ├──────────────┴──────────────────────────────────────────────┤
   │ VERDICT: ✅ READY TO MERGE                                   │
   └─────────────────────────────────────────────────────────────┘

   ┌─────────────────────────────────────────────────────────────┐
   │ payment-api                                                 │
   ├──────────────┬──────────────────────────────────────────────┤
   │ Tests        │ ❌ FAILED (2 failures)                        │
   │ Lint         │ ⚠️  WARNINGS (3)                              │
   │ Conflicts    │ ✅ NONE                                       │
   │ Files Changed│ 8 files (+256, -12)                          │
   │ Commits      │ 4                                             │
   ├──────────────┴──────────────────────────────────────────────┤
   │ VERDICT: ❌ NOT READY - Fix test failures                    │
   └─────────────────────────────────────────────────────────────┘

   ═══════════════════════════════════════════════════════════════

   SUMMARY:
   ✅ Ready to merge: auth-service
   ❌ Needs work: payment-api

   NEXT STEPS:
   1. /merge auth-service (or wait for all)
   2. /tell payment-api Fix the failing tests in payment.test.ts
   ```

4. **Only recommend merge if ALL checks pass**

5. **Require explicit user approval**:
   ```
   ⚠️  Merge requires your approval.
   Type: /merge <name> to merge a specific agent
   Type: /merge all to merge all verified agents
   ```
