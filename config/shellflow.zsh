# Shellflow - Simple Non-Interactive Agent Orchestration
# Human is the supervisor. Agents run autonomously until done.
#
# Add to ~/.zshrc: source /path/to/shellflow/config/shellflow.zsh

# ============================================
# QUICK AI HELPERS (non-interactive)
# ============================================

ask() {
  claude -p "$*"
}

howto() {
  claude -p "Give me ONLY the command, no explanation: $*"
}

explain() {
  claude -p "Explain this command briefly: $*"
}

review() {
  if [ -n "$1" ]; then
    git diff "$@" | claude -p "Review this diff for bugs and issues"
  else
    git diff | claude -p "Review this diff for bugs and issues"
  fi
}

# ============================================
# SPAWN AGENT (non-interactive, autonomous)
# ============================================

spawn-agent() {
  local name=""
  local task=""
  local model="sonnet"
  local tools="Read,Glob,Grep,Edit,Write,Bash"

  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case $1 in
      --model|-m)
        model="$2"
        shift 2
        ;;
      --tools|-t)
        tools="$2"
        shift 2
        ;;
      *)
        if [ -z "$name" ]; then
          name="$1"
        else
          task="$task $1"
        fi
        shift
        ;;
    esac
  done

  task="${task# }"  # trim leading space

  if [ -z "$name" ] || [ -z "$task" ]; then
    echo "Usage: spawn-agent <name> <task> [--model sonnet|haiku|opus] [--tools 'Read,Edit,...']"
    echo ""
    echo "Examples:"
    echo "  spawn-agent auth 'implement oauth login'"
    echo "  spawn-agent api 'add rate limiting' --model haiku"
    echo "  spawn-agent fix 'fix the bug' --tools 'Read,Glob,Grep,Edit'"
    return 1
  fi

  local repo_root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
  local worktree_path="$repo_root/../worktrees/$name"

  # Create worktree
  mkdir -p "$repo_root/../worktrees"
  git worktree add -b "$name" "$worktree_path" 2>/dev/null || {
    echo "Worktree '$name' may already exist, reusing..."
  }

  # Create tmux window
  tmux new-window -d -n "$name" -c "$worktree_path"

  # Build the claude command
  local claude_cmd="claude -p '${task}' --allowedTools '${tools}'"

  # Add model if not default
  if [ "$model" != "sonnet" ]; then
    claude_cmd="$claude_cmd --model $model"
  fi

  # Run agent non-interactively
  tmux send-keys -t "$name" "$claude_cmd" Enter

  echo "✓ Agent '$name' spawned (non-interactive, autonomous)"
  echo "  Model: $model"
  echo "  Tools: $tools"
  echo "  Task: $task"
  echo ""
  echo "  Commands:"
  echo "    progress $name    - see what agent is doing"
  echo "    changes $name     - see code changes"
  echo "    cleanup $name     - remove agent when done"
}

# Short alias
sa() { spawn-agent "$@"; }

# ============================================
# SPAWN WATCHERS (k8s focused)
# ============================================

spawn-watcher() {
  local name=$1
  shift
  local cmd="$*"

  if [ -z "$name" ] || [ -z "$cmd" ]; then
    echo "Usage: spawn-watcher <name> <command>"
    return 1
  fi

  tmux new-window -d -n "watch-$name"
  tmux send-keys -t "watch-$name" "$cmd" Enter

  echo "✓ Watcher 'watch-$name' started"
  echo "  Check: progress watch-$name"
}

# K8s watchers with pod names
watch-k8s() {
  local namespace="${K8S_NAMESPACE:-default}"
  local pods=("$@")

  if [ ${#pods[@]} -eq 0 ]; then
    echo "Usage: watch-k8s <pod1> <pod2> ..."
    echo "  Set K8S_NAMESPACE env var for namespace (default: default)"
    return 1
  fi

  # Create watchers window with grid
  tmux new-window -d -n "k8s-watch"

  local pane=0
  for pod in "${pods[@]}"; do
    if [ $pane -gt 0 ]; then
      if [ $((pane % 2)) -eq 1 ]; then
        tmux split-window -d -h -t "k8s-watch"
      else
        tmux split-window -d -v -t "k8s-watch"
      fi
    fi
    ((pane++))
  done

  tmux select-layout -t "k8s-watch" tiled

  pane=0
  for pod in "${pods[@]}"; do
    tmux send-keys -t "k8s-watch.$pane" "kubectl logs -f $pod -n $namespace --tail=100" Enter
    ((pane++))
  done

  echo "✓ K8s watchers started for: ${pods[*]}"
  echo "  Namespace: $namespace"
  echo "  View: peek k8s-watch"
}

# Watch pods by label
watch-k8s-label() {
  local label=$1
  local namespace="${K8S_NAMESPACE:-default}"

  if [ -z "$label" ]; then
    echo "Usage: watch-k8s-label <label-selector>"
    echo "  Example: watch-k8s-label app=api"
    return 1
  fi

  local pods=($(kubectl get pods -l "$label" -n "$namespace" -o jsonpath='{.items[*].metadata.name}' 2>/dev/null))

  if [ ${#pods[@]} -eq 0 ]; then
    echo "No pods found with label: $label"
    return 1
  fi

  watch-k8s "${pods[@]}"
}

# Short aliases
sw() { spawn-watcher "$@"; }
wk() { watch-k8s "$@"; }
wkl() { watch-k8s-label "$@"; }

# ============================================
# PROGRESS & CHANGES (human supervisor tools)
# ============================================

# See agent output / what it's doing
progress() {
  local name=$1
  local lines=${2:-80}

  if [ -z "$name" ]; then
    echo "=== All Windows ==="
    tmux list-windows -F "  [#{window_index}] #{window_name}"
    echo ""
    echo "Usage: progress <name> [lines]"
    return
  fi

  echo "╔═══════════════════════════════════════════════════════════════╗"
  echo "║  PROGRESS: $name"
  echo "╚═══════════════════════════════════════════════════════════════╝"
  echo ""
  tmux capture-pane -t "$name" -p -S -$lines 2>/dev/null || {
    echo "Window '$name' not found"
    tmux list-windows -F "  Available: #{window_name}"
  }
}

# See code changes in agent worktree (nice colored diff)
changes() {
  local name=$1
  local repo_root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)

  if [ -z "$name" ]; then
    # Show changes for ALL agents
    echo "╔═══════════════════════════════════════════════════════════════╗"
    echo "║  ALL AGENT CHANGES                                            ║"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    echo ""

    local worktrees_dir="$repo_root/../worktrees"
    if [ ! -d "$worktrees_dir" ]; then
      echo "No worktrees found"
      return
    fi

    for agent_dir in "$worktrees_dir"/*/; do
      if [ -d "$agent_dir" ]; then
        local agent_name=$(basename "$agent_dir")
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "AGENT: $agent_name"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

        local changed=$(git -C "$agent_dir" diff --stat 2>/dev/null)
        if [ -n "$changed" ]; then
          echo "$changed"
          echo ""
          git -C "$agent_dir" diff --color=always 2>/dev/null | head -100
        else
          echo "(no changes)"
        fi
        echo ""
      fi
    done
    return
  fi

  # Show changes for specific agent
  local worktree_path="$repo_root/../worktrees/$name"

  if [ ! -d "$worktree_path" ]; then
    echo "Agent worktree '$name' not found"
    return 1
  fi

  echo "╔═══════════════════════════════════════════════════════════════╗"
  echo "║  CHANGES: $name"
  echo "╚═══════════════════════════════════════════════════════════════╝"
  echo ""

  # Summary
  echo "FILES CHANGED:"
  git -C "$worktree_path" diff --stat 2>/dev/null || echo "(no changes)"
  echo ""

  # Detailed diff with colors
  echo "DIFF:"
  git -C "$worktree_path" diff --color=always 2>/dev/null || echo "(no changes)"
}

# ============================================
# STATUS & CONTROL
# ============================================

status() {
  local repo_root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)

  echo "╔═══════════════════════════════════════════════════════════════╗"
  echo "║                    SHELLFLOW STATUS                           ║"
  echo "╚═══════════════════════════════════════════════════════════════╝"
  echo ""

  echo "TMUX WINDOWS:"
  tmux list-windows -F "  [#{window_index}] #{window_name} #{?window_active,← YOU,}"
  echo ""

  echo "AGENT WORKTREES:"
  local worktrees_dir="$repo_root/../worktrees"
  if [ -d "$worktrees_dir" ]; then
    for agent_dir in "$worktrees_dir"/*/; do
      if [ -d "$agent_dir" ]; then
        local agent_name=$(basename "$agent_dir")
        local changed=$(git -C "$agent_dir" diff --stat --shortstat 2>/dev/null | tail -1)
        if [ -n "$changed" ]; then
          echo "  $agent_name: $changed"
        else
          echo "  $agent_name: (no changes)"
        fi
      fi
    done
  else
    echo "  (no agents)"
  fi
  echo ""

  echo "COMMANDS:"
  echo "  progress <name>  - see agent output"
  echo "  changes [name]   - see code changes"
  echo "  cleanup <name>   - remove agent"
  echo "  peek <name>      - switch to window"
}

# Peek at a window
peek() {
  local name=$1
  if [ -z "$name" ]; then
    echo "Usage: peek <window>"
    return 1
  fi
  tmux select-window -t "$name"
}

# Cleanup agent (kill window + remove worktree)
cleanup() {
  local name=$1
  if [ -z "$name" ]; then
    echo "Usage: cleanup <agent-name>"
    return 1
  fi

  tmux kill-window -t "$name" 2>/dev/null

  local repo_root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
  git worktree remove --force "$repo_root/../worktrees/$name" 2>/dev/null
  git branch -D "$name" 2>/dev/null

  echo "✓ Cleaned up '$name'"
}

# Cleanup all agents
cleanup-all() {
  local repo_root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
  local worktrees_dir="$repo_root/../worktrees"

  if [ ! -d "$worktrees_dir" ]; then
    echo "No agents to clean up"
    return
  fi

  echo "Cleaning up all agents..."
  for agent_dir in "$worktrees_dir"/*/; do
    if [ -d "$agent_dir" ]; then
      local agent_name=$(basename "$agent_dir")
      cleanup "$agent_name"
    fi
  done
  echo "✓ All agents cleaned up"
}

# ============================================
# ALIASES
# ============================================

alias st='status'
alias cu='cleanup'

# ============================================
# TAB COMPLETION
# ============================================

_shellflow_windows() {
  local windows
  windows=($(tmux list-windows -F "#{window_name}" 2>/dev/null))
  _describe 'windows' windows
}

_shellflow_agents() {
  local repo_root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
  local agents=()
  local worktrees_dir="$repo_root/../worktrees"
  if [ -d "$worktrees_dir" ]; then
    agents=($(ls "$worktrees_dir" 2>/dev/null))
  fi
  _describe 'agents' agents
}

if type compdef &>/dev/null; then
  compdef _shellflow_windows progress peek
  compdef _shellflow_agents changes cleanup
fi

# ============================================
# SPEC BUILDER & SPAWN FROM SPEC
# ============================================

# Interactive spec builder wizard
build-specs() {
  local script_dir="${SHELLFLOW_DIR:-$HOME/.shellflow}"
  if [ -f "$script_dir/scripts/build-specs.sh" ]; then
    bash "$script_dir/scripts/build-specs.sh" "$@"
  else
    # Try relative to this script
    local zsh_dir="$(dirname "${(%):-%x}")"
    bash "$zsh_dir/../scripts/build-specs.sh" "$@"
  fi
}

# Spawn agents from a spec file
spawn-from-spec() {
  local spec_file=$1
  local only_agent=$2

  if [ -z "$spec_file" ]; then
    echo "Usage: spawn-from-spec <spec.yaml> [--only <agent-name>]"
    return 1
  fi

  if [ ! -f "$spec_file" ]; then
    echo "Spec file not found: $spec_file"
    return 1
  fi

  # Parse --only flag
  if [ "$2" = "--only" ]; then
    only_agent="$3"
  fi

  echo "╔═══════════════════════════════════════════════════════════════╗"
  echo "║  SPAWNING AGENTS FROM SPEC                                    ║"
  echo "╚═══════════════════════════════════════════════════════════════╝"
  echo ""
  echo "Spec file: $spec_file"
  echo ""

  # Parse YAML and spawn agents
  # Using simple grep/sed parsing (works for our simple format)
  local in_agent=false
  local current_name=""
  local current_model="sonnet"
  local current_tools="Read,Glob,Grep,Edit,Write,Bash"
  local current_task=""
  local reading_task=false

  while IFS= read -r line || [ -n "$line" ]; do
    # Detect new agent block
    if [[ "$line" =~ ^[[:space:]]*-[[:space:]]*name:[[:space:]]*(.+)$ ]]; then
      # Spawn previous agent if exists
      if [ -n "$current_name" ] && [ -n "$current_task" ]; then
        if [ -z "$only_agent" ] || [ "$only_agent" = "$current_name" ]; then
          echo "Spawning: $current_name ($current_model)"
          spawn-agent "$current_name" "$current_task" --model "$current_model" --tools "$current_tools"
          echo ""
        fi
      fi

      # Start new agent
      current_name="${BASH_REMATCH[1]}"
      current_name=$(echo "$current_name" | xargs)  # trim
      current_model="sonnet"
      current_tools="Read,Glob,Grep,Edit,Write,Bash"
      current_task=""
      reading_task=false
      in_agent=true

    elif [ "$in_agent" = true ]; then
      # Parse agent properties
      if [[ "$line" =~ ^[[:space:]]*model:[[:space:]]*(.+)$ ]]; then
        current_model="${BASH_REMATCH[1]}"
        current_model=$(echo "$current_model" | xargs)

      elif [[ "$line" =~ ^[[:space:]]*tools:[[:space:]]*(.+)$ ]]; then
        current_tools="${BASH_REMATCH[1]}"
        current_tools=$(echo "$current_tools" | xargs)

      elif [[ "$line" =~ ^[[:space:]]*task:[[:space:]]*\|?$ ]]; then
        reading_task=true
        current_task=""

      elif [ "$reading_task" = true ]; then
        # Check if we've hit another property (end of task)
        if [[ "$line" =~ ^[[:space:]]*(name|model|tools|verify|scope):[[:space:]] ]]; then
          reading_task=false
        elif [[ "$line" =~ ^[[:space:]]*-[[:space:]]*name: ]]; then
          reading_task=false
        else
          # Append to task (strip leading whitespace for YAML multiline)
          local task_line=$(echo "$line" | sed 's/^[[:space:]]*//')
          if [ -n "$current_task" ]; then
            current_task="$current_task $task_line"
          else
            current_task="$task_line"
          fi
        fi
      fi
    fi
  done < "$spec_file"

  # Spawn last agent
  if [ -n "$current_name" ] && [ -n "$current_task" ]; then
    if [ -z "$only_agent" ] || [ "$only_agent" = "$current_name" ]; then
      echo "Spawning: $current_name ($current_model)"
      spawn-agent "$current_name" "$current_task" --model "$current_model" --tools "$current_tools"
      echo ""
    fi
  fi

  echo "Done! Use 'status' to see all agents."
}

# Alias
alias bs='build-specs'
alias sfs='spawn-from-spec'

# ============================================
# HELP
# ============================================

shellflow-help() {
  cat << 'EOF'
╔═══════════════════════════════════════════════════════════════════╗
║                      SHELLFLOW COMMANDS                           ║
╠═══════════════════════════════════════════════════════════════════╣
║ QUICK AI:                                                         ║
║   ask "question"              Quick AI answer                     ║
║   howto "task"                Get command for task                ║
║   explain "cmd"               Explain a command                   ║
║   review [file]               Review diff for bugs                ║
║                                                                   ║
║ SPEC BUILDER (interactive wizard):                                ║
║   build-specs (bs)            Create agent specs interactively   ║
║   spawn-from-spec (sfs) <file>  Spawn agents from spec file      ║
║                                                                   ║
║ SPAWN AGENTS (autonomous, non-interactive):                       ║
║   spawn-agent <name> <task> [--model X] [--tools Y]              ║
║   sa auth "implement oauth" --model haiku                        ║
║                                                                   ║
║ SPAWN WATCHERS:                                                   ║
║   spawn-watcher <name> <cmd>  Generic watcher                    ║
║   watch-k8s pod1 pod2         K8s pod logs (set K8S_NAMESPACE)   ║
║   watch-k8s-label app=api     K8s pods by label                  ║
║                                                                   ║
║ MONITOR & CONTROL:                                                ║
║   progress <name>             See agent output                   ║
║   changes [name]              See code changes (all if no name)  ║
║   status                      Overview of all agents             ║
║   peek <name>                 Switch to window                   ║
║   cleanup <name>              Remove agent + worktree            ║
║   cleanup-all                 Remove all agents                  ║
╚═══════════════════════════════════════════════════════════════════╝
EOF
}

echo "Shellflow loaded. Type 'shellflow-help' for commands."
