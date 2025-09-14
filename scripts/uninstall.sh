#!/bin/bash
# Shellflow Uninstall Script
# Removes Shellflow configuration

set -e

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║           Shellflow Uninstall                             ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

read -p "Are you sure you want to uninstall Shellflow? (y/N) " confirm
if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
  echo "Cancelled."
  exit 0
fi

echo ""

# Remove from .zshrc
if grep -q "shellflow.zsh" ~/.zshrc 2>/dev/null; then
  sed -i.bak '/shellflow/d' ~/.zshrc
  echo "✅ Removed from ~/.zshrc"
else
  echo "⏭️  Not in ~/.zshrc"
fi

# Remove from .tmux.conf
if grep -q "shellflow" ~/.tmux.conf 2>/dev/null; then
  sed -i.bak '/shellflow/d' ~/.tmux.conf
  echo "✅ Removed from ~/.tmux.conf"
else
  echo "⏭️  Not in ~/.tmux.conf"
fi

# Remove hooks
if [ -f ~/.claude/hooks/agent-filter.sh ]; then
  rm ~/.claude/hooks/agent-filter.sh
  echo "✅ Removed agent-filter.sh hook"
else
  echo "⏭️  Hook not found"
fi

# Remove slash commands
for cmd in spawn-agent spawn-watcher check tell list status verify merge cleanup; do
  if [ -f ~/.claude/commands/$cmd.md ]; then
    rm ~/.claude/commands/$cmd.md
    echo "✅ Removed $cmd.md"
  fi
done

echo ""
echo "Uninstall complete. You may want to:"
echo "  - Reload your shell: source ~/.zshrc"
echo "  - Clean up worktrees: rm -rf ../worktrees"
echo "  - Remove this directory: rm -rf $(pwd)"
