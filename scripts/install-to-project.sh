#!/bin/bash
# Shellflow - Install to Another Project
#
# Usage (from any repo):
#   curl -fsSL https://raw.githubusercontent.com/marko999/shellflow/main/scripts/install-to-project.sh | bash
#   OR
#   /path/to/shellflow/scripts/install-to-project.sh
#   OR
#   /path/to/shellflow/scripts/install-to-project.sh /path/to/target/repo

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}"
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║           Shellflow - Install to Project                  ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Determine Shellflow source directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SHELLFLOW_DIR="$(dirname "$SCRIPT_DIR")"

# Determine target directory
if [ -n "$1" ]; then
  TARGET_DIR="$1"
else
  TARGET_DIR="$(pwd)"
fi

# Verify shellflow source exists
if [ ! -f "$SHELLFLOW_DIR/config/shellflow.zsh" ]; then
  echo -e "${RED}Error: Cannot find Shellflow source at $SHELLFLOW_DIR${NC}"
  echo "Make sure you're running this from the Shellflow repo or provide the path."
  exit 1
fi

# Verify target is a git repo
if [ ! -d "$TARGET_DIR/.git" ]; then
  echo -e "${YELLOW}Warning: $TARGET_DIR is not a git repo${NC}"
  read -p "Continue anyway? (y/N) " confirm
  if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    exit 1
  fi
fi

echo -e "Source: ${BLUE}$SHELLFLOW_DIR${NC}"
echo -e "Target: ${BLUE}$TARGET_DIR${NC}"
echo ""

# ============================================
# 1. Install global components (shell, tmux, hooks)
# ============================================

echo -e "${BLUE}[1/4] Installing global components...${NC}"

# Shell config
SHELL_CONFIG="$SHELLFLOW_DIR/config/shellflow.zsh"
SOURCE_LINE="source \"$SHELL_CONFIG\""

if grep -q "shellflow.zsh" ~/.zshrc 2>/dev/null; then
  echo -e "  ${GREEN}✓${NC} Shell config already in ~/.zshrc"
else
  echo "" >> ~/.zshrc
  echo "# Shellflow - Agentic Workflow" >> ~/.zshrc
  echo "$SOURCE_LINE" >> ~/.zshrc
  echo -e "  ${GREEN}✓${NC} Added shellflow to ~/.zshrc"
fi

# tmux config
TMUX_CONFIG="$SHELLFLOW_DIR/config/tmux.conf"

if [ -f ~/.tmux.conf ]; then
  if grep -q "shellflow" ~/.tmux.conf 2>/dev/null; then
    echo -e "  ${GREEN}✓${NC} tmux config already includes shellflow"
  else
    echo "" >> ~/.tmux.conf
    echo "# Shellflow configuration" >> ~/.tmux.conf
    echo "source-file \"$TMUX_CONFIG\"" >> ~/.tmux.conf
    echo -e "  ${GREEN}✓${NC} Added shellflow to ~/.tmux.conf"
  fi
else
  cp "$TMUX_CONFIG" ~/.tmux.conf
  echo -e "  ${GREEN}✓${NC} Created ~/.tmux.conf"
fi

# Global hooks
HOOKS_DIR="$HOME/.claude/hooks"
mkdir -p "$HOOKS_DIR"
cp "$SHELLFLOW_DIR/.claude/hooks/agent-filter.sh" "$HOOKS_DIR/"
chmod +x "$HOOKS_DIR/agent-filter.sh"
echo -e "  ${GREEN}✓${NC} Installed agent-filter.sh hook"

# Global slash commands
COMMANDS_DIR="$HOME/.claude/commands"
mkdir -p "$COMMANDS_DIR"
for cmd in "$SHELLFLOW_DIR/.claude/commands/"*.md; do
  cp "$cmd" "$COMMANDS_DIR/"
done
echo -e "  ${GREEN}✓${NC} Installed $(ls "$SHELLFLOW_DIR/.claude/commands/"*.md | wc -l | tr -d ' ') slash commands"

# ============================================
# 2. Install project-specific components
# ============================================

echo -e "${BLUE}[2/4] Installing project components to $TARGET_DIR...${NC}"

# Create .claude directory in target
mkdir -p "$TARGET_DIR/.claude"

# Copy project settings template
cat > "$TARGET_DIR/.claude/settings.json" << 'EOF'
{
  "permissions": {
    "allow": [
      "Bash(git *)",
      "Bash(tmux *)",
      "Bash(ls *)",
      "Bash(cat *)"
    ]
  },
  "env": {
    "SHELLFLOW_MODE": "supervisor"
  }
}
EOF
echo -e "  ${GREEN}✓${NC} Created .claude/settings.json"

# Copy CLAUDE.md
cp "$SHELLFLOW_DIR/CLAUDE.md" "$TARGET_DIR/CLAUDE.md"
echo -e "  ${GREEN}✓${NC} Created CLAUDE.md"

# ============================================
# 3. Create worktrees directory
# ============================================

echo -e "${BLUE}[3/4] Setting up worktrees directory...${NC}"

WORKTREES_DIR="$TARGET_DIR/../worktrees"
mkdir -p "$WORKTREES_DIR"
echo -e "  ${GREEN}✓${NC} Created $WORKTREES_DIR"

# Add to .gitignore if not already there
if [ -f "$TARGET_DIR/.gitignore" ]; then
  if ! grep -q "worktrees" "$TARGET_DIR/.gitignore" 2>/dev/null; then
    echo "" >> "$TARGET_DIR/.gitignore"
    echo "# Shellflow worktrees" >> "$TARGET_DIR/.gitignore"
    echo "../worktrees/" >> "$TARGET_DIR/.gitignore"
    echo -e "  ${GREEN}✓${NC} Added worktrees to .gitignore"
  fi
fi

# ============================================
# 4. Verify dependencies
# ============================================

echo -e "${BLUE}[4/4] Checking dependencies...${NC}"

MISSING=()
command -v git >/dev/null 2>&1 || MISSING+=("git")
command -v tmux >/dev/null 2>&1 || MISSING+=("tmux")
command -v claude >/dev/null 2>&1 || MISSING+=("claude")
command -v jq >/dev/null 2>&1 || MISSING+=("jq")

if [ ${#MISSING[@]} -gt 0 ]; then
  echo -e "  ${YELLOW}Warning: Missing dependencies:${NC}"
  for dep in "${MISSING[@]}"; do
    echo -e "    - $dep"
  done
  echo ""
  echo "  Install with:"
  echo "    brew install tmux jq"
  echo "    npm install -g @anthropic/claude-code"
else
  echo -e "  ${GREEN}✓${NC} All dependencies installed"
fi

# ============================================
# Done
# ============================================

echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                  Installation Complete!                   ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "To get started:"
echo ""
echo -e "  ${BLUE}1.${NC} Reload your shell:"
echo "     source ~/.zshrc"
echo ""
echo -e "  ${BLUE}2.${NC} Navigate to your project:"
echo "     cd $TARGET_DIR"
echo ""
echo -e "  ${BLUE}3.${NC} Start tmux:"
echo "     tmux new -s work"
echo ""
echo -e "  ${BLUE}4.${NC} Type 'shellflow-help' for commands"
echo ""
echo "Quick commands:"
echo "  oo                    - Enter orchestrator (Claude)"
echo "  ask 'question'        - Quick AI question"
echo "  sa name task          - Spawn agent"
echo "  sas 'n:t' 'n:t'       - Spawn agent grid"
echo "  sws k8s               - Spawn k8s watchers"
echo "  check name            - Check agent output"
echo "  tell name msg         - Send to agent"
echo "  st                    - Status"
echo ""
