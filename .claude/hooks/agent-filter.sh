#!/bin/bash
# Agent Permission Filter Hook
# This hook restricts what commands worker agents can execute
#
# Exit codes:
#   0 = Allow
#   2 = Block
#
# Place this in ~/.claude/hooks/ or project .claude/hooks/
# Configure in settings.json with PreToolUse hook

set -e

# Read hook input from stdin (JSON format)
INPUT=$(cat)

# Extract tool name and command
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Log for debugging (comment out in production)
# echo "[HOOK] Tool: $TOOL_NAME, Command: $COMMAND" >> /tmp/agent-filter.log

#############################
# BLOCK: Write/Edit tools
#############################
if [[ "$TOOL_NAME" == "Edit" ]] || [[ "$TOOL_NAME" == "Write" ]] || [[ "$TOOL_NAME" == "NotebookEdit" ]]; then
  echo "BLOCK: Write operations not allowed for worker agents. Use git patches instead."
  exit 2
fi

#############################
# FILTER: Bash commands
#############################
if [[ "$TOOL_NAME" == "Bash" ]]; then

  # ALLOW: Git read operations
  if [[ "$COMMAND" =~ ^git\ (status|diff|log|show|branch|stash\ list|worktree\ list|remote|fetch) ]]; then
    exit 0
  fi

  # ALLOW: Git write operations (only add/commit)
  if [[ "$COMMAND" =~ ^git\ (add|commit|stash\ (push|pop|apply)) ]]; then
    exit 0
  fi

  # ALLOW: Read-only file operations
  if [[ "$COMMAND" =~ ^(cat|head|tail|less|more|wc|file|stat|ls|tree|pwd|which|whereis|type)\ ]]; then
    exit 0
  fi

  # ALLOW: Search operations
  if [[ "$COMMAND" =~ ^(grep|rg|ag|find|fd|locate)\ ]]; then
    exit 0
  fi

  # ALLOW: Environment inspection
  if [[ "$COMMAND" =~ ^(echo|printf|env|printenv|set|export)\ ]]; then
    exit 0
  fi

  # ALLOW: Node.js test/lint/build (read-only operations)
  if [[ "$COMMAND" =~ ^(npm|pnpm|yarn|bun)\ (test|run\ (test|lint|check|typecheck|build|dev)|list|outdated|audit) ]]; then
    exit 0
  fi

  # ALLOW: Python test/lint
  if [[ "$COMMAND" =~ ^(pytest|python\ -m\ pytest|ruff|pylint|mypy|black\ --check|isort\ --check) ]]; then
    exit 0
  fi

  # ALLOW: Go test/lint
  if [[ "$COMMAND" =~ ^(go\ (test|vet|fmt\ -l|build)|golangci-lint) ]]; then
    exit 0
  fi

  # ALLOW: Rust test/lint
  if [[ "$COMMAND" =~ ^(cargo\ (test|check|clippy|fmt\ --check|build)) ]]; then
    exit 0
  fi

  # ALLOW: Make targets (common safe ones)
  if [[ "$COMMAND" =~ ^make\ (test|lint|check|build|compile)$ ]]; then
    exit 0
  fi

  # ALLOW: kubectl read operations
  if [[ "$COMMAND" =~ ^kubectl\ (get|describe|logs|top|explain|api-resources|version) ]]; then
    exit 0
  fi

  # ALLOW: docker read operations
  if [[ "$COMMAND" =~ ^docker\ (ps|images|logs|inspect|stats|version) ]]; then
    exit 0
  fi

  # BLOCK: Destructive operations
  if [[ "$COMMAND" =~ ^(rm|rmdir|mv|unlink|shred)\ ]]; then
    echo "BLOCK: Destructive file operations not allowed"
    exit 2
  fi

  # BLOCK: System modifications
  if [[ "$COMMAND" =~ ^(sudo|chmod|chown|chgrp|mkfs|mount|umount) ]]; then
    echo "BLOCK: System modification commands not allowed"
    exit 2
  fi

  # BLOCK: Network operations that could be dangerous
  if [[ "$COMMAND" =~ ^(curl|wget|nc|netcat).*\|.*(bash|sh|exec) ]]; then
    echo "BLOCK: Piping network content to shell not allowed"
    exit 2
  fi

  # BLOCK: Package installation
  if [[ "$COMMAND" =~ (npm|pip|brew|apt|yum)\ install ]]; then
    echo "BLOCK: Package installation not allowed for agents"
    exit 2
  fi

  # DEFAULT: Block unknown commands
  echo "BLOCK: Command not in agent allowlist: $COMMAND"
  exit 2
fi

# Allow all other tools (Read, Glob, Grep, etc.)
exit 0
