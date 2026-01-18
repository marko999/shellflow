#!/bin/bash
# Shellflow - One-Line Installer
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/marko999/shellflow/main/install.sh | bash
#
# Or with a specific install location:
#   curl -fsSL https://raw.githubusercontent.com/marko999/shellflow/main/install.sh | bash -s -- --dir ~/.shellflow
#
# This script:
#   1. Clones Shellflow to ~/.shellflow (or specified dir)
#   2. Installs shell functions to ~/.zshrc
#   3. Installs tmux config to ~/.tmux.conf
#   4. Installs Claude Code slash commands and hooks
#   5. Optionally sets up the current directory as a project

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Default values
SHELLFLOW_DIR="${HOME}/.shellflow"
REPO_URL="https://github.com/marko999/shellflow.git"
SETUP_PROJECT=false
PROJECT_DIR=""

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --dir)
      SHELLFLOW_DIR="$2"
      shift 2
      ;;
    --project)
      SETUP_PROJECT=true
      PROJECT_DIR="$2"
      shift 2
      ;;
    --repo)
      REPO_URL="$2"
      shift 2
      ;;
    -h|--help)
      echo "Shellflow Installer"
      echo ""
      echo "Usage:"
      echo "  curl -fsSL <url>/install.sh | bash"
      echo "  curl -fsSL <url>/install.sh | bash -s -- [options]"
      echo ""
      echo "Options:"
      echo "  --dir <path>      Install Shellflow to this directory (default: ~/.shellflow)"
      echo "  --project <path>  Also set up this directory as a Shellflow project"
      echo "  --repo <url>      Use this git repo URL (for forks)"
      echo "  -h, --help        Show this help"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

echo -e "${BLUE}"
cat << 'EOF'
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║   ███████╗██╗  ██╗███████╗██╗     ██╗     ███████╗██╗     ║
║   ██╔════╝██║  ██║██╔════╝██║     ██║     ██╔════╝██║     ║
║   ███████╗███████║█████╗  ██║     ██║     █████╗  ██║     ║
║   ╚════██║██╔══██║██╔══╝  ██║     ██║     ██╔══╝  ╚═╝     ║
║   ███████║██║  ██║███████╗███████╗███████╗██║     ██╗     ║
║   ╚══════╝╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝╚═╝     ╚═╝     ║
║                                                           ║
║           Agentic Workflow for Claude Code                ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# ============================================
# Check dependencies
# ============================================

echo -e "${BLUE}Checking dependencies...${NC}"

MISSING=()
command -v git >/dev/null 2>&1 || MISSING+=("git")
command -v tmux >/dev/null 2>&1 || MISSING+=("tmux (brew install tmux)")
command -v claude >/dev/null 2>&1 || MISSING+=("claude (npm install -g @anthropic/claude-code)")

if [ ${#MISSING[@]} -gt 0 ]; then
  echo -e "${YELLOW}Missing dependencies:${NC}"
  for dep in "${MISSING[@]}"; do
    echo "  - $dep"
  done
  echo ""
  read -p "Continue anyway? (y/N) " confirm
  if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo "Aborted. Install dependencies first."
    exit 1
  fi
fi

echo -e "${GREEN}✓${NC} Dependencies checked"

# ============================================
# Clone or update Shellflow
# ============================================

echo -e "${BLUE}Installing Shellflow to ${SHELLFLOW_DIR}...${NC}"

if [ -d "$SHELLFLOW_DIR/.git" ]; then
  echo "  Shellflow already installed, updating..."
  cd "$SHELLFLOW_DIR"
  git pull --quiet
  echo -e "${GREEN}✓${NC} Updated Shellflow"
else
  if [ -d "$SHELLFLOW_DIR" ]; then
    echo -e "${YELLOW}Directory exists but is not a git repo. Removing...${NC}"
    rm -rf "$SHELLFLOW_DIR"
  fi
  git clone --quiet "$REPO_URL" "$SHELLFLOW_DIR"
  echo -e "${GREEN}✓${NC} Cloned Shellflow"
fi

# ============================================
# Install shell configuration
# ============================================

echo -e "${BLUE}Installing shell configuration...${NC}"

SHELL_SOURCE="source \"${SHELLFLOW_DIR}/config/shellflow.zsh\""

if grep -q "shellflow.zsh" ~/.zshrc 2>/dev/null; then
  # Update existing line to new path
  sed -i.bak "s|source.*shellflow.zsh.*|${SHELL_SOURCE}|" ~/.zshrc
  echo -e "${GREEN}✓${NC} Updated shellflow in ~/.zshrc"
else
  echo "" >> ~/.zshrc
  echo "# Shellflow - Agentic Workflow" >> ~/.zshrc
  echo "$SHELL_SOURCE" >> ~/.zshrc
  echo -e "${GREEN}✓${NC} Added shellflow to ~/.zshrc"
fi

# ============================================
# Install tmux configuration
# ============================================

echo -e "${BLUE}Installing tmux configuration...${NC}"

TMUX_SOURCE="source-file \"${SHELLFLOW_DIR}/config/tmux.conf\""

if [ -f ~/.tmux.conf ]; then
  if grep -q "shellflow" ~/.tmux.conf 2>/dev/null; then
    sed -i.bak "s|source-file.*shellflow.*|${TMUX_SOURCE}|" ~/.tmux.conf
    echo -e "${GREEN}✓${NC} Updated shellflow in ~/.tmux.conf"
  else
    echo "" >> ~/.tmux.conf
    echo "# Shellflow configuration" >> ~/.tmux.conf
    echo "$TMUX_SOURCE" >> ~/.tmux.conf
    echo -e "${GREEN}✓${NC} Added shellflow to ~/.tmux.conf"
  fi
else
  echo "# Shellflow configuration" > ~/.tmux.conf
  echo "$TMUX_SOURCE" >> ~/.tmux.conf
  echo -e "${GREEN}✓${NC} Created ~/.tmux.conf"
fi

# ============================================
# Install Claude Code components
# ============================================

echo -e "${BLUE}Installing Claude Code components...${NC}"

# Slash commands
COMMANDS_DIR="$HOME/.claude/commands"
mkdir -p "$COMMANDS_DIR"
cp "$SHELLFLOW_DIR/.claude/commands/"*.md "$COMMANDS_DIR/"
echo -e "${GREEN}✓${NC} Installed $(ls "$SHELLFLOW_DIR/.claude/commands/"*.md | wc -l | tr -d ' ') slash commands"

# Hooks
HOOKS_DIR="$HOME/.claude/hooks"
mkdir -p "$HOOKS_DIR"
cp "$SHELLFLOW_DIR/.claude/hooks/agent-filter.sh" "$HOOKS_DIR/"
chmod +x "$HOOKS_DIR/agent-filter.sh"
echo -e "${GREEN}✓${NC} Installed permission hooks"

# ============================================
# Set up project (if requested)
# ============================================

if [ "$SETUP_PROJECT" = true ] && [ -n "$PROJECT_DIR" ]; then
  echo -e "${BLUE}Setting up project at ${PROJECT_DIR}...${NC}"

  mkdir -p "$PROJECT_DIR/.claude"

  cat > "$PROJECT_DIR/.claude/settings.json" << 'EOF'
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

  cp "$SHELLFLOW_DIR/CLAUDE.md" "$PROJECT_DIR/CLAUDE.md"
  mkdir -p "$PROJECT_DIR/../worktrees"

  echo -e "${GREEN}✓${NC} Project configured"
fi

# ============================================
# Done
# ============================================

echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║              Installation Complete!                       ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "Next steps:"
echo ""
echo -e "  ${BLUE}1.${NC} Reload your shell:"
echo "     source ~/.zshrc"
echo ""
echo -e "  ${BLUE}2.${NC} Start a tmux session:"
echo "     tmux new -s work"
echo ""
echo -e "  ${BLUE}3.${NC} Try it out:"
echo "     shellflow-help     # Show all commands"
echo "     ask 'hello'        # Quick AI question"
echo "     oo                 # Enter orchestrator mode"
echo ""
echo -e "  ${BLUE}4.${NC} Set up a project (optional):"
echo "     cd /your/project"
echo "     ${SHELLFLOW_DIR}/scripts/install-to-project.sh"
echo ""
echo "Documentation: ${SHELLFLOW_DIR}/docs/"
echo ""
