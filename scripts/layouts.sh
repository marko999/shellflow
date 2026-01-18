#!/bin/bash
# Shellflow Layout Scripts
# Pre-configured tmux layouts for agents and watchers

set -e

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
WORKTREES_DIR="$REPO_ROOT/../worktrees"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

#######################################
# Create 2x2 agent grid
# Arguments:
#   $1 - name1:task1
#   $2 - name2:task2
#   $3 - name3:task3 (optional)
#   $4 - name4:task4 (optional)
#######################################
create_agent_grid() {
  local agents=("$@")
  local count=${#agents[@]}

  if [ $count -lt 2 ]; then
    echo "Usage: create_agent_grid 'name1:task1' 'name2:task2' ['name3:task3'] ['name4:task4']"
    return 1
  fi

  echo -e "${BLUE}Creating agent grid with $count agents...${NC}"

  # Create window
  tmux new-window -n "agents" 2>/dev/null || tmux rename-window "agents"

  # Process each agent
  local pane=0
  for agent_spec in "${agents[@]}"; do
    local name="${agent_spec%%:*}"
    local task="${agent_spec#*:}"

    echo -e "  ${GREEN}→${NC} Creating agent: $name"

    # Create worktree
    mkdir -p "$WORKTREES_DIR"
    git worktree add -b "$name" "$WORKTREES_DIR/$name" 2>/dev/null || true

    # Create pane (split existing)
    if [ $pane -eq 0 ]; then
      # First pane - already exists
      true
    elif [ $pane -eq 1 ]; then
      # Split horizontally (right)
      tmux split-window -h -t agents
    elif [ $pane -eq 2 ]; then
      # Go to first pane, split vertically (down)
      tmux select-pane -t agents.0
      tmux split-window -v -t agents
    elif [ $pane -eq 3 ]; then
      # Go to second pane, split vertically (down)
      tmux select-pane -t agents.1
      tmux split-window -v -t agents
    fi

    # Send commands to current pane
    tmux send-keys -t agents "cd '$WORKTREES_DIR/$name'" Enter
    tmux send-keys -t agents "claude" Enter

    ((pane++))
  done

  # Balance layout
  tmux select-layout -t agents tiled

  # Send tasks after agents start (give them time to initialize)
  echo -e "${BLUE}Waiting for agents to initialize...${NC}"
  sleep 3

  pane=0
  for agent_spec in "${agents[@]}"; do
    local task="${agent_spec#*:}"
    tmux send-keys -t agents.$pane "$task" Enter
    ((pane++))
  done

  echo -e "${GREEN}✓ Agent grid created${NC}"
  echo ""
  echo "View: tmux select-window -t agents"
}

#######################################
# Create watcher dashboard
# Arguments:
#   $1 - preset name OR custom specs
#######################################
create_watcher_dashboard() {
  local preset="$1"
  shift
  local custom_specs=("$@")

  local watchers=()

  case "$preset" in
    k8s|kubernetes)
      watchers=(
        "pods:kubectl get pods -w"
        "logs:kubectl logs -f -l app=\${APP:-app} --tail=50"
        "events:kubectl get events -w --sort-by='.lastTimestamp'"
        "top:watch -n 5 kubectl top pods"
      )
      ;;
    docker)
      watchers=(
        "ps:watch -n 2 docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'"
        "logs:docker logs -f \$(docker ps -q | head -1) 2>/dev/null || echo 'No containers'"
        "stats:docker stats --format 'table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}'"
      )
      ;;
    dev)
      watchers=(
        "tests:npm run test -- --watch 2>/dev/null || echo 'No test:watch'"
        "git:watch -n 5 'git status --short && echo --- && git log --oneline -5'"
        "files:fswatch -r ./src 2>/dev/null || watch -n 2 'ls -la src/ 2>/dev/null || ls -la'"
      )
      ;;
    rabbit|rabbitmq)
      watchers=(
        "queues:watch -n 2 'rabbitmqctl list_queues name messages consumers 2>/dev/null || echo Not available'"
        "conns:watch -n 5 'rabbitmqctl list_connections 2>/dev/null || echo Not available'"
      )
      ;;
    system)
      watchers=(
        "htop:htop 2>/dev/null || top"
        "mem:watch -n 2 'free -h 2>/dev/null || vm_stat'"
        "disk:watch -n 10 df -h"
        "net:watch -n 2 'netstat -i 2>/dev/null || networksetup -listallhardwareports'"
      )
      ;;
    custom)
      watchers=("${custom_specs[@]}")
      ;;
    *)
      echo "Unknown preset: $preset"
      echo "Available: k8s, docker, dev, rabbit, system"
      echo "Or use: create_watcher_dashboard custom 'name1:cmd1' 'name2:cmd2'"
      return 1
      ;;
  esac

  local count=${#watchers[@]}
  echo -e "${BLUE}Creating watcher dashboard ($preset) with $count panes...${NC}"

  # Create window
  tmux new-window -n "watchers" 2>/dev/null || tmux rename-window "watchers"

  # Process each watcher
  local pane=0
  for watcher_spec in "${watchers[@]}"; do
    local name="${watcher_spec%%:*}"
    local cmd="${watcher_spec#*:}"

    echo -e "  ${GREEN}→${NC} $name: $cmd"

    # Create pane
    if [ $pane -eq 0 ]; then
      true
    elif [ $pane -eq 1 ]; then
      tmux split-window -h -t watchers
    elif [ $pane -eq 2 ]; then
      tmux select-pane -t watchers.0
      tmux split-window -v -t watchers
    elif [ $pane -eq 3 ]; then
      tmux select-pane -t watchers.1
      tmux split-window -v -t watchers
    else
      # More than 4, just keep splitting
      tmux split-window -t watchers
    fi

    # Run command
    tmux send-keys -t watchers "$cmd" Enter

    ((pane++))
  done

  # Balance layout
  tmux select-layout -t watchers tiled

  echo -e "${GREEN}✓ Watcher dashboard created${NC}"
  echo ""
  echo "View: tmux select-window -t watchers"
}

#######################################
# Quick commands
#######################################

# Alias functions for easy use
agents() {
  create_agent_grid "$@"
}

watchers() {
  create_watcher_dashboard "$@"
}

# If script is run directly (not sourced), show usage
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  case "$1" in
    agents)
      shift
      create_agent_grid "$@"
      ;;
    watchers)
      shift
      create_watcher_dashboard "$@"
      ;;
    *)
      echo "Shellflow Layouts"
      echo ""
      echo "Usage:"
      echo "  $0 agents 'name1:task1' 'name2:task2' ['name3:task3'] ['name4:task4']"
      echo "  $0 watchers <preset>"
      echo "  $0 watchers custom 'name1:cmd1' 'name2:cmd2'"
      echo ""
      echo "Watcher presets: k8s, docker, dev, rabbit, system"
      echo ""
      echo "Examples:"
      echo "  $0 agents 'auth:Implement OAuth' 'api:Add rate limiting'"
      echo "  $0 watchers k8s"
      echo "  $0 watchers custom 'logs:tail -f /var/log/app.log' 'cpu:htop'"
      ;;
  esac
fi
