#!/bin/bash
# Shellflow Setup Script
# Run this script to install and configure Shellflow

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║           Shellflow Setup - Agentic Workflow              ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

# Check for required tools
check_dependencies() {
  echo "Checking dependencies..."

  local missing=()

  command -v git >/dev/null 2>&1 || missing+=("git")
  command -v tmux >/dev/null 2>&1 || missing+=("tmux")
  command -v claude >/dev/null 2>&1 || missing+=("claude (Claude Code CLI)")
  command -v jq >/dev/null 2>&1 || missing+=("jq")

  if [ ${#missing[@]} -gt 0 ]; then
    echo "❌ Missing dependencies:"
    for dep in "${missing[@]}"; do
      echo "   - $dep"
    done
    echo ""
    echo "Install with:"
    echo "  brew install tmux jq"
    echo "  npm install -g @anthropic/claude-code"
    exit 1
  fi

  echo "✅ All dependencies installed"
}

# Install shell configuration
install_shell_config() {
  echo ""
  echo "Installing shell configuration..."

  local shell_config="$REPO_DIR/config/shellflow.zsh"
  local source_line="source \"$shell_config\""

  # Check if already installed
  if grep -q "shellflow.zsh" ~/.zshrc 2>/dev/null; then
    echo "✅ Shell config already in ~/.zshrc"
  else
    echo "" >> ~/.zshrc
    echo "# Shellflow - Agentic Workflow" >> ~/.zshrc
    echo "$source_line" >> ~/.zshrc
    echo "✅ Added shellflow to ~/.zshrc"
  fi
}

# Install tmux configuration
install_tmux_config() {
  echo ""
  echo "Installing tmux configuration..."

  local tmux_config="$REPO_DIR/config/tmux.conf"

  if [ -f ~/.tmux.conf ]; then
    # Check if already included
    if grep -q "shellflow" ~/.tmux.conf 2>/dev/null; then
      echo "✅ Tmux config already includes shellflow"
    else
      echo "" >> ~/.tmux.conf
      echo "# Shellflow configuration" >> ~/.tmux.conf
      echo "source-file \"$tmux_config\"" >> ~/.tmux.conf
      echo "✅ Added shellflow to ~/.tmux.conf"
    fi
  else
    cp "$tmux_config" ~/.tmux.conf
    echo "✅ Created ~/.tmux.conf"
  fi
}

# Install Claude Code hooks
install_hooks() {
  echo ""
  echo "Installing Claude Code hooks..."

  local hooks_dir="$HOME/.claude/hooks"
  mkdir -p "$hooks_dir"

  # Copy the agent filter hook
  cp "$REPO_DIR/.claude/hooks/agent-filter.sh" "$hooks_dir/"
  chmod +x "$hooks_dir/agent-filter.sh"

  echo "✅ Installed agent-filter.sh hook"
}

# Install Claude Code slash commands
install_commands() {
  echo ""
  echo "Installing Claude Code slash commands..."

  local commands_dir="$HOME/.claude/commands"
  mkdir -p "$commands_dir"

  # Copy all commands
  for cmd in "$REPO_DIR/.claude/commands/"*.md; do
    local name=$(basename "$cmd")
    cp "$cmd" "$commands_dir/"
    echo "   ✓ $name"
  done

  echo "✅ Installed slash commands"
}

# Create worktrees directory
setup_worktrees() {
  echo ""
  echo "Setting up worktrees directory..."

  mkdir -p "$REPO_DIR/../worktrees"
  echo "✅ Created ../worktrees directory"
}

# Print summary
print_summary() {
  echo ""
  echo "╔═══════════════════════════════════════════════════════════╗"
  echo "║                  Setup Complete!                          ║"
  echo "╚═══════════════════════════════════════════════════════════╝"
  echo ""
  echo "To get started:"
  echo ""
  echo "  1. Reload your shell:"
  echo "     source ~/.zshrc"
  echo ""
  echo "  2. Start a tmux session:"
  echo "     tmux new -s shellflow"
  echo ""
  echo "  3. Enter supervisor mode:"
  echo "     claude"
  echo ""
  echo "Available commands:"
  echo ""
  echo "  Shell aliases:"
  echo "    ask <question>       - Quick AI question"
  echo "    howto <task>         - Get command for a task"
  echo "    orchestrate (sf)     - Start supervisor session"
  echo "    spawn-agent (sfa)    - Create new agent"
  echo "    spawn-watcher (sfw)  - Create new watcher"
  echo "    check-agent (sfc)    - Check agent status"
  echo "    tell-agent (sft)     - Send message to agent"
  echo "    list-agents (sfl)    - List all agents/watchers"
  echo "    cleanup-agent (sfx)  - Remove an agent"
  echo ""
  echo "  Claude Code slash commands:"
  echo "    /spawn-agent <name> <task>"
  echo "    /spawn-watcher <name> <command>"
  echo "    /check <name>"
  echo "    /tell <name> <message>"
  echo "    /list"
  echo "    /status"
  echo "    /verify"
  echo "    /merge <name>"
  echo "    /cleanup <name>"
  echo ""
  echo "  Tmux shortcuts:"
  echo "    Ctrl+b S  - Toggle broadcast mode"
  echo "    Ctrl+b A  - Create agent window"
  echo "    Ctrl+b W  - Create watcher window"
  echo "    Ctrl+b G  - Grid layout"
  echo ""
}

# Main
main() {
  check_dependencies
  install_shell_config
  install_tmux_config
  install_hooks
  install_commands
  setup_worktrees
  print_summary
}

main "$@"
