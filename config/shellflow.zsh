# Shellflow - Agentic Workflow Shell Configuration
# Add this to your ~/.zshrc: source /path/to/shellflow/config/shellflow.zsh
#
# CORE CONCEPT: You ALWAYS stay in your main pane.
# - Run bash commands directly
# - Talk to Claude Code (orchestrator mode)
# - Quick AI questions with 'ask' or 'claude -p'
# - Spawn agents/watchers in OTHER windows (you don't switch)
# - Check/tell agents from YOUR pane (output comes to you)

# ============================================
# MODE SWITCHING (all from your main pane)
# ============================================

# Enter orchestrator mode (Claude Code interactive)
# You stay in your pane, Claude runs here
orchestrator() {
  echo "Entering orchestrator mode... (type 'exit' or Ctrl+D to return to bash)"
  claude
}
alias oo='orchestrator'

# Quick AI question (one-shot, stays in bash)
ask() {
  claude -p "$*"
}

# Get just the command (no explanation)
howto() {
  claude -p "Give me ONLY the command, no explanation: $*"
}

# Explain a command
explain() {
  claude -p "Explain this command briefly: $*"
}

# Review code
review() {
  if [ -n "$1" ]; then
    git diff "$@" | claude -p "Review this diff for bugs and issues"
  else
    git diff | claude -p "Review this diff for bugs and issues"
  fi
}

# Generate commit message
genmsg() {
  git diff --staged | claude -p "Write a concise commit message (conventional commits)"
}

# ============================================
# SPAWN AGENTS (in background, you stay here)
# ============================================

# Spawn single agent - DOES NOT switch window
spawn-agent() {
  local name=$1
  shift
  local task="$*"

  if [ -z "$name" ] || [ -z "$task" ]; then
    echo "Usage: spawn-agent <name> <task>"
    return 1
  fi

  local repo_root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
  local worktree_path="$repo_root/../worktrees/$name"

  # Create worktree
  mkdir -p "$repo_root/../worktrees"
  git worktree add -b "$name" "$worktree_path" 2>/dev/null || true

  # Create window WITHOUT switching (-d flag)
  tmux new-window -d -n "$name" -c "$worktree_path"

  # Start agent in that window
  tmux send-keys -t "$name" "claude" Enter

  # Wait for Claude to initialize (check for prompt)
  local retries=0
  while [ $retries -lt 10 ]; do
    sleep 1
    if tmux capture-pane -t "$name" -p 2>/dev/null | grep -qE "(❯|>|claude)"; then
      break
    fi
    ((retries++))
  done
  sleep 1  # Extra buffer after prompt appears

  tmux send-keys -t "$name" "$task" Enter

  echo "✓ Agent '$name' spawned (window created in background)"
  echo "  Check: check $name"
  echo "  Tell:  tell $name <message>"
}

# Spawn multiple agents in grid - DOES NOT switch
spawn-agents() {
  local specs=("$@")

  if [ ${#specs[@]} -lt 2 ]; then
    echo "Usage: spawn-agents 'name1:task1' 'name2:task2' ..."
    return 1
  fi

  local repo_root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
  mkdir -p "$repo_root/../worktrees"

  # Create window WITHOUT switching
  tmux new-window -d -n "agents"

  local pane=0
  for spec in "${specs[@]}"; do
    local name="${spec%%:*}"
    local task="${spec#*:}"
    local worktree_path="$repo_root/../worktrees/$name"

    # Create worktree
    git worktree add -b "$name" "$worktree_path" 2>/dev/null || true

    # Create panes
    if [ $pane -gt 0 ]; then
      if [ $((pane % 2)) -eq 1 ]; then
        tmux split-window -d -h -t "agents"
      else
        tmux select-pane -t "agents.0"
        tmux split-window -d -v -t "agents"
      fi
    fi

    ((pane++))
  done

  # Balance layout
  tmux select-layout -t "agents" tiled

  # Now send commands to each pane
  pane=0
  for spec in "${specs[@]}"; do
    local name="${spec%%:*}"
    local task="${spec#*:}"
    local worktree_path="$repo_root/../worktrees/$name"

    tmux send-keys -t "agents.$pane" "cd '$worktree_path' && claude" Enter
    ((pane++))
  done

  # Wait for Claude instances to initialize (check for prompts)
  echo "  Waiting for Claude instances to initialize..."
  local retries=0
  while [ $retries -lt 15 ]; do
    sleep 1
    local ready=0
    for i in $(seq 0 $((${#specs[@]} - 1))); do
      if tmux capture-pane -t "agents.$i" -p 2>/dev/null | grep -qE "(❯|>|claude)"; then
        ((ready++))
      fi
    done
    if [ $ready -eq ${#specs[@]} ]; then
      break
    fi
    ((retries++))
  done
  sleep 1  # Extra buffer

  # Send tasks to each pane
  pane=0
  for spec in "${specs[@]}"; do
    local task="${spec#*:}"
    tmux send-keys -t "agents.$pane" "$task" Enter
    ((pane++))
  done

  echo "✓ Created ${#specs[@]} agents in 'agents' window (background)"
  echo "  View:   peek agents"
  echo "  Status: status"
}

# ============================================
# SPAWN WATCHERS (in background, you stay here)
# ============================================

# Spawn single watcher - DOES NOT switch
spawn-watcher() {
  local name=$1
  shift
  local cmd="$*"

  if [ -z "$name" ] || [ -z "$cmd" ]; then
    echo "Usage: spawn-watcher <name> <command>"
    return 1
  fi

  # Create window WITHOUT switching (-d flag)
  tmux new-window -d -n "watch-$name"
  tmux send-keys -t "watch-$name" "$cmd" Enter

  echo "✓ Watcher 'watch-$name' started (background)"
  echo "  Check: check watch-$name"
}

# Spawn watcher dashboard with preset - DOES NOT switch
spawn-watchers() {
  local preset="$1"
  local watchers=()

  case "$preset" in
    k8s)
      watchers=(
        "kubectl get pods -w"
        "kubectl logs -f -l app=\${APP:-app} --tail=50"
        "kubectl get events -w"
        "watch -n 5 kubectl top pods"
      )
      ;;
    docker)
      watchers=(
        "watch -n 2 docker ps"
        "docker stats"
        "docker logs -f \$(docker ps -q | head -1) 2>/dev/null || echo 'No containers'"
      )
      ;;
    dev)
      watchers=(
        "npm run test -- --watch 2>/dev/null || echo 'No test:watch'"
        "watch -n 5 'git status --short'"
        "fswatch -r ./src 2>/dev/null || watch -n 2 ls -la"
      )
      ;;
    system)
      watchers=(
        "htop 2>/dev/null || top"
        "watch -n 2 df -h"
        "watch -n 5 'ps aux | head -20'"
      )
      ;;
    *)
      echo "Usage: spawn-watchers <preset>"
      echo "Presets: k8s, docker, dev, system"
      return 1
      ;;
  esac

  # Create window WITHOUT switching
  tmux new-window -d -n "watchers"

  local pane=0
  for cmd in "${watchers[@]}"; do
    if [ $pane -gt 0 ]; then
      if [ $((pane % 2)) -eq 1 ]; then
        tmux split-window -d -h -t "watchers"
      else
        tmux select-pane -t "watchers.0"
        tmux split-window -d -v -t "watchers"
      fi
    fi
    ((pane++))
  done

  tmux select-layout -t "watchers" tiled

  pane=0
  for cmd in "${watchers[@]}"; do
    tmux send-keys -t "watchers.$pane" "$cmd" Enter
    ((pane++))
  done

  echo "✓ Watcher dashboard '$preset' created (background)"
  echo "  View: peek watchers"
}

# Broadcast command with different params - DOES NOT switch
broadcast() {
  local template="$1"
  shift
  local params=("$@")

  if [ -z "$template" ] || [ ${#params[@]} -eq 0 ]; then
    echo "Usage: broadcast 'cmd with {} placeholder' param1 param2 ..."
    echo "Example: broadcast 'kubectl logs {} -f' pod1 pod2 pod3"
    return 1
  fi

  # Create window WITHOUT switching
  local win_name="broadcast-$(date +%s)"
  tmux new-window -d -n "$win_name"

  local pane=0
  for param in "${params[@]}"; do
    if [ $pane -gt 0 ]; then
      if [ $((pane % 2)) -eq 1 ]; then
        tmux split-window -d -h -t "$win_name"
      else
        tmux select-pane -t "$win_name.0"
        tmux split-window -d -v -t "$win_name"
      fi
    fi
    ((pane++))
  done

  tmux select-layout -t "$win_name" tiled

  pane=0
  for param in "${params[@]}"; do
    local cmd="${template//\{\}/$param}"
    tmux send-keys -t "$win_name.$pane" "$cmd" Enter
    ((pane++))
  done

  echo "✓ Broadcast to ${#params[@]} panes (background)"
  echo "  View: peek $win_name"
}

# Quick pod logs
watch-pods() {
  if [ "$1" = "-l" ]; then
    local pods=($(kubectl get pods -l "$2" -o jsonpath='{.items[*].metadata.name}' 2>/dev/null))
    if [ ${#pods[@]} -eq 0 ]; then
      echo "No pods found"
      return 1
    fi
    broadcast "kubectl logs {} -f --tail=100" "${pods[@]}"
  else
    broadcast "kubectl logs {} -f --tail=100" "$@"
  fi
}

# ============================================
# CHECK/TELL/CONTROL (from your main pane)
# ============================================

# Check agent output (output comes TO you)
check() {
  local name=$1
  local lines=${2:-50}

  if [ -z "$name" ]; then
    echo "=== All Windows ==="
    tmux list-windows -F "  #{window_index}: #{window_name}"
    return
  fi

  echo "=== $name (last $lines lines) ==="
  tmux capture-pane -t "$name" -p -S -$lines 2>/dev/null || {
    echo "Window '$name' not found"
    tmux list-windows -F "  Available: #{window_name}"
  }
}

# Send message to agent (from your pane)
tell() {
  local name=$1
  shift
  local msg="$*"

  if [ -z "$name" ] || [ -z "$msg" ]; then
    echo "Usage: tell <window> <message>"
    return 1
  fi

  tmux send-keys -t "$name" "$msg" Enter
  echo "✓ Sent to '$name'"
}

# Quick status of all agents
status() {
  echo "╔═══════════════════════════════════════════════════════════╗"
  echo "║                    SHELLFLOW STATUS                       ║"
  echo "╚═══════════════════════════════════════════════════════════╝"
  echo ""
  echo "WINDOWS:"
  tmux list-windows -F "  [#{window_index}] #{window_name} #{?window_active,← YOU ARE HERE,}"
  echo ""
  echo "WORKTREES:"
  git worktree list 2>/dev/null | sed 's/^/  /' || echo "  (not in git repo)"
  echo ""
  echo "COMMANDS:"
  echo "  check <name>      - See window output"
  echo "  tell <name> <msg> - Send to window"
  echo "  peek <name>       - Quick look (switch & back)"
  echo "  kill <name>       - Close window"
}

# Peek at a window briefly (switches, then you manually come back with Ctrl+b 0)
peek() {
  local name=$1
  if [ -z "$name" ]; then
    echo "Usage: peek <window>"
    return 1
  fi
  echo "Switching to '$name'... (Ctrl+b + number to return)"
  tmux select-window -t "$name"
}

# Kill a window
kill-window() {
  local name=$1
  if [ -z "$name" ]; then
    echo "Usage: kill-window <name>"
    return 1
  fi
  tmux kill-window -t "$name" 2>/dev/null && echo "✓ Killed '$name'" || echo "Window not found"
}

# Cleanup agent (kill window + remove worktree)
cleanup() {
  local name=$1
  if [ -z "$name" ]; then
    echo "Usage: cleanup <agent-name>"
    return 1
  fi

  tmux kill-window -t "$name" 2>/dev/null
  git worktree remove --force "../worktrees/$name" 2>/dev/null
  git branch -D "$name" 2>/dev/null

  echo "✓ Cleaned up '$name'"
}

# ============================================
# ALIASES (short forms)
# ============================================

alias oo='orchestrator'           # Enter Claude Code
alias sa='spawn-agent'            # Spawn single agent
alias sas='spawn-agents'          # Spawn agent grid
alias sw='spawn-watcher'          # Spawn single watcher
alias sws='spawn-watchers'        # Spawn watcher dashboard
alias bc='broadcast'              # Broadcast command
alias wp='watch-pods'             # Watch pod logs
alias st='status'                 # Show status
alias kw='kill-window'            # Kill window
alias cu='cleanup'                # Cleanup agent

# ============================================
# TAB COMPLETION
# ============================================

_shellflow_windows() {
  local windows
  windows=($(tmux list-windows -F "#{window_name}" 2>/dev/null))
  _describe 'windows' windows
}

# Only set up completions if compdef is available (requires compinit)
if type compdef &>/dev/null; then
  compdef _shellflow_windows check tell peek kill-window cleanup kw cu
fi

# ============================================
# STARTUP MESSAGE
# ============================================

shellflow-help() {
  cat << 'EOF'
╔═══════════════════════════════════════════════════════════════════╗
║                      SHELLFLOW COMMANDS                           ║
╠═══════════════════════════════════════════════════════════════════╣
║ MODE SWITCHING (you stay in this pane):                           ║
║   oo                    Enter Claude orchestrator mode            ║
║   ask "question"        Quick AI answer                           ║
║   howto "task"          Get command for task                      ║
║   (just type)           Run bash commands directly                ║
║                                                                   ║
║ SPAWN (creates in background, you stay here):                     ║
║   sa <name> <task>         Single agent                          ║
║   sas 'n1:t1' 'n2:t2'      Agent grid (2-4)                      ║
║   sw <name> <cmd>          Single watcher                        ║
║   sws <preset>             Watcher dashboard (k8s/docker/dev)    ║
║   bc 'cmd {}' p1 p2        Broadcast with different params       ║
║   wp pod1 pod2             Watch pod logs                        ║
║                                                                   ║
║ CONTROL (from your pane):                                         ║
║   check <name>          See window output                        ║
║   tell <name> <msg>     Send message to window                   ║
║   st                    Status of all windows                    ║
║   peek <name>           Switch to window (Ctrl+b 0 to return)    ║
║   kw <name>             Kill window                              ║
║   cu <name>             Cleanup agent + worktree                 ║
╚═══════════════════════════════════════════════════════════════════╝
EOF
}

echo "Shellflow loaded. Type 'shellflow-help' for commands."
