#!/bin/bash
# Shellflow Broadcast Script
# Send a command template to multiple panes with different parameters

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

#######################################
# Broadcast a command to multiple panes
# Arguments:
#   $1 - command template (use {} for placeholder)
#   $@ - parameters to substitute
#######################################
broadcast() {
  local template="$1"
  shift
  local params=("$@")
  local count=${#params[@]}

  if [ -z "$template" ] || [ $count -eq 0 ]; then
    echo "Usage: broadcast 'command with {} placeholder' param1 param2 param3 ..."
    echo ""
    echo "Examples:"
    echo "  broadcast 'kubectl logs {} -f' api-pod-1 api-pod-2 worker-pod"
    echo "  broadcast 'tail -f {}' /var/log/app.log /var/log/error.log"
    echo "  broadcast 'ssh {}' server1 server2 server3"
    return 1
  fi

  echo -e "${BLUE}Broadcasting to $count panes...${NC}"
  echo -e "Template: $template"
  echo ""

  # Create window
  tmux new-window -n "broadcast" 2>/dev/null || {
    # Window exists, create new one with suffix
    local suffix=$(date +%s)
    tmux new-window -n "broadcast-$suffix"
  }

  local window_name=$(tmux display-message -p '#{window_name}')
  local pane=0

  for param in "${params[@]}"; do
    # Replace {} with parameter
    local cmd="${template//\{\}/$param}"

    echo -e "  ${GREEN}→${NC} Pane $((pane+1)): $cmd"

    if [ $pane -eq 0 ]; then
      # First pane already exists
      tmux send-keys -t "$window_name" "$cmd" Enter
    else
      # Split for new pane
      if [ $((pane % 2)) -eq 1 ]; then
        # Odd panes: split horizontally
        tmux split-window -h -t "$window_name"
      else
        # Even panes: split vertically from appropriate pane
        tmux select-pane -t "$window_name.$((pane - 1))"
        tmux split-window -v -t "$window_name"
      fi
      tmux send-keys -t "$window_name" "$cmd" Enter
    fi

    ((pane++))
  done

  # Balance the layout
  tmux select-layout -t "$window_name" tiled

  echo ""
  echo -e "${GREEN}✓ Broadcast complete${NC}"
  echo ""
  echo "View: tmux select-window -t $window_name"
  echo "Sync mode (type to all): Ctrl+b S"
}

#######################################
# Quick pod log watcher
# Arguments:
#   $@ - pod names or selectors
#######################################
watch_pods() {
  local pods=("$@")

  if [ ${#pods[@]} -eq 0 ]; then
    echo "Usage: watch_pods pod1 pod2 pod3 ..."
    echo "   or: watch_pods -l app=api (uses selector)"
    return 1
  fi

  # Check if using selector
  if [ "${pods[0]}" == "-l" ]; then
    local selector="${pods[1]}"
    # Get pod names from selector
    pods=($(kubectl get pods -l "$selector" -o jsonpath='{.items[*].metadata.name}'))
    echo "Found ${#pods[@]} pods matching selector '$selector'"
  fi

  broadcast "kubectl logs {} -f --tail=100" "${pods[@]}"
}

#######################################
# Quick multi-server SSH
# Arguments:
#   $@ - server names
#######################################
multi_ssh() {
  broadcast "ssh {}" "$@"
}

#######################################
# Quick multi-directory command
# Arguments:
#   $1 - command to run
#   $@ - directories
#######################################
multi_dir() {
  local cmd="$1"
  shift
  broadcast "cd {} && $cmd" "$@"
}

# If script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  case "$1" in
    -h|--help)
      echo "Shellflow Broadcast"
      echo ""
      echo "Usage:"
      echo "  $0 'command with {} placeholder' param1 param2 ..."
      echo ""
      echo "Examples:"
      echo "  $0 'kubectl logs {} -f' api-pod worker-pod"
      echo "  $0 'tail -f {}' /var/log/app.log /var/log/error.log"
      echo "  $0 'ssh {}' server1 server2 server3"
      echo ""
      echo "After broadcast, use Ctrl+b S to toggle sync mode (type to all panes)"
      ;;
    *)
      broadcast "$@"
      ;;
  esac
fi
