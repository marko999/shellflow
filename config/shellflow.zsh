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

sf-spawn-agent() {
  local name=""
  local task=""
  local model="sonnet"
  local tools="Read,Glob,Grep,Edit,Write,Bash"
  local repo=""

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
      --repo|-r)
        repo="$2"
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
    echo "Usage: spawn-agent <name> <task> [--repo path] [--model sonnet|haiku|opus] [--tools 'Read,Edit,...']"
    echo ""
    echo "Examples:"
    echo "  spawn-agent auth 'implement oauth login'"
    echo "  spawn-agent api 'add rate limiting' --model haiku"
    echo "  spawn-agent fix 'fix the bug' --repo ~/projects/myapp"
    echo "  spawn-agent api-auth 'add oauth' --repo notetaker-api  # with SHELLFLOW_PROJECTS_ROOT"
    return 1
  fi

  # Resolve repo path
  local repo_root
  local repo_name
  local worktrees_base

  if [ -n "$repo" ]; then
    # --repo was specified
    if [[ "$repo" = /* ]] || [[ "$repo" = ~* ]]; then
      # Absolute path or home-relative
      repo_root="${repo/#\~/$HOME}"
    elif [ -n "$SHELLFLOW_PROJECTS_ROOT" ]; then
      # Short name with projects root
      repo_root="$SHELLFLOW_PROJECTS_ROOT/$repo"
    else
      # Try as relative path from current directory
      repo_root="$(cd "$repo" 2>/dev/null && git rev-parse --show-toplevel 2>/dev/null)"
      if [ -z "$repo_root" ]; then
        echo "Error: Cannot resolve repo '$repo'"
        echo "  Either use absolute path or set SHELLFLOW_PROJECTS_ROOT"
        return 1
      fi
    fi

    # Verify it's a git repo
    if [ ! -d "$repo_root/.git" ]; then
      echo "Error: '$repo_root' is not a git repository"
      return 1
    fi

    repo_name=$(basename "$repo_root")
    worktrees_base="${SHELLFLOW_PROJECTS_ROOT:-$(dirname "$repo_root")}/worktrees/$repo_name"
  else
    # No --repo, use current directory's repo (backwards compatible)
    repo_root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
    repo_name=$(basename "$repo_root")

    # Check if SHELLFLOW_PROJECTS_ROOT is set and repo is under it
    if [ -n "$SHELLFLOW_PROJECTS_ROOT" ] && [[ "$repo_root" == "$SHELLFLOW_PROJECTS_ROOT"/* ]]; then
      worktrees_base="$SHELLFLOW_PROJECTS_ROOT/worktrees/$repo_name"
    else
      worktrees_base="$repo_root/../worktrees"
    fi
  fi

  local worktree_path="$worktrees_base/$name"

  # Create worktree directory structure
  mkdir -p "$worktrees_base"

  # Create worktree from the target repo
  git -C "$repo_root" worktree add -b "$name" "$worktree_path" 2>/dev/null || {
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
  echo "  Repo: $repo_name ($repo_root)"
  echo "  Model: $model"
  echo "  Tools: $tools"
  echo "  Task: $task"
  echo ""
  echo "  Commands:"
  echo "    sf-progress $name    - see what agent is doing"
  echo "    sf-changes $name     - see code changes"
  echo "    sf-cleanup $name     - remove agent when done"
}

# Short alias
sa() { sf-spawn-agent "$@"; }

# ============================================
# SPAWN WATCHERS (k8s focused)
# ============================================

sf-spawn-watcher() {
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
  echo "  Check: sf-progress watch-$name"
}

# K8s watchers with pod names
sf-watch-k8s() {
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
  echo "  View: sf-peek k8s-watch"
}

# Watch pods by label
sf-watch-k8s-label() {
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

  sf-watch-k8s "${pods[@]}"
}

# Short aliases
sw() { sf-spawn-watcher "$@"; }
wk() { sf-watch-k8s "$@"; }
wkl() { sf-watch-k8s-label "$@"; }

# ============================================
# PROGRESS & CHANGES (human supervisor tools)
# ============================================

# See agent output / what it's doing
sf-progress() {
  local name=$1
  local lines=${2:-80}

  if [ -z "$name" ]; then
    echo "=== All Windows ==="
    tmux list-windows -F "  [#{window_index}] #{window_name}"
    echo ""
    echo "Usage: sf-progress <name> [lines]"
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

# Helper: find agent worktree path across all repos
_find_agent_worktree() {
  local name=$1

  # Check SHELLFLOW_PROJECTS_ROOT first (multi-repo mode)
  if [ -n "$SHELLFLOW_PROJECTS_ROOT" ] && [ -d "$SHELLFLOW_PROJECTS_ROOT/worktrees" ]; then
    for repo_dir in "$SHELLFLOW_PROJECTS_ROOT/worktrees"/*/; do
      if [ -d "$repo_dir/$name" ]; then
        echo "$repo_dir/$name"
        return 0
      fi
    done
  fi

  # Check legacy location
  local repo_root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
  local legacy_path="$repo_root/../worktrees/$name"
  if [ -d "$legacy_path" ]; then
    echo "$legacy_path"
    return 0
  fi

  return 1
}

# Helper: get repo name from agent worktree path
_get_repo_from_worktree() {
  local worktree_path=$1
  if [ -n "$SHELLFLOW_PROJECTS_ROOT" ]; then
    # Extract repo name from path like /projects/worktrees/REPO/agent
    local relative="${worktree_path#$SHELLFLOW_PROJECTS_ROOT/worktrees/}"
    echo "${relative%%/*}"
  else
    echo ""
  fi
}

# Diff agent branch vs main (works from anywhere)
sf-diff-agent() {
  local name=$1
  local repo=$2

  if [ -z "$name" ]; then
    echo "Usage: diff-agent <agent-name> [repo-name]"
    echo ""
    echo "Shows diff between agent's branch and main"
    echo "Example: diff-agent fetcher deals-bot"
    return 1
  fi

  # Find the repo
  local repo_root=""

  if [ -n "$repo" ] && [ -n "$SHELLFLOW_PROJECTS_ROOT" ]; then
    repo_root="$SHELLFLOW_PROJECTS_ROOT/$repo"
  elif [ -n "$SHELLFLOW_PROJECTS_ROOT" ]; then
    # Search for the agent across all repos
    for repo_dir in "$SHELLFLOW_PROJECTS_ROOT/worktrees"/*/; do
      if [ -d "$repo_dir/$name" ]; then
        # Found it - get the actual repo root
        repo_root=$(git -C "$repo_dir/$name" rev-parse --show-toplevel 2>/dev/null)
        break
      fi
    done
  fi

  if [ -z "$repo_root" ]; then
    # Fallback to current repo
    repo_root=$(git rev-parse --show-toplevel 2>/dev/null)
  fi

  if [ -z "$repo_root" ]; then
    echo "Could not find repo. Specify repo name or set SHELLFLOW_PROJECTS_ROOT"
    return 1
  fi

  local repo_name=$(basename "$repo_root")

  # Find the main branch name
  local main_branch="main"
  if git -C "$repo_root" show-ref --verify --quiet refs/heads/master; then
    main_branch="master"
  fi

  echo "╔═══════════════════════════════════════════════════════════════╗"
  echo "║  DIFF: $name vs $main_branch [$repo_name]"
  echo "╚═══════════════════════════════════════════════════════════════╝"
  echo ""

  # Check if branch exists
  if ! git -C "$repo_root" show-ref --verify --quiet refs/heads/"$name"; then
    echo "Branch '$name' not found in $repo_name"
    return 1
  fi

  # Show commits
  echo "COMMITS:"
  git -C "$repo_root" log --oneline "$main_branch".."$name" 2>/dev/null || echo "(no commits)"
  echo ""

  # Show file changes
  echo "FILES CHANGED:"
  git -C "$repo_root" diff --stat "$main_branch".."$name" 2>/dev/null || echo "(no changes)"
  echo ""

  # Show diff
  echo "DIFF:"
  git -C "$repo_root" diff --color=always "$main_branch".."$name" 2>/dev/null
}

# Alias
da() { sf-diff-agent "$@"; }

# See code changes in agent worktree (nice colored diff)
sf-changes() {
  local name=$1

  if [ -z "$name" ]; then
    # Show changes for ALL agents
    echo "╔═══════════════════════════════════════════════════════════════╗"
    echo "║  ALL AGENT CHANGES                                            ║"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    echo ""

    local found_any=false

    # Check SHELLFLOW_PROJECTS_ROOT first (multi-repo mode)
    if [ -n "$SHELLFLOW_PROJECTS_ROOT" ] && [ -d "$SHELLFLOW_PROJECTS_ROOT/worktrees" ]; then
      for repo_dir in "$SHELLFLOW_PROJECTS_ROOT/worktrees"/*/; do
        if [ -d "$repo_dir" ]; then
          local repo_name=$(basename "$repo_dir")

          for agent_dir in "$repo_dir"/*/; do
            if [ -d "$agent_dir" ]; then
              found_any=true
              local agent_name=$(basename "$agent_dir")
              echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
              echo "AGENT: $agent_name [$repo_name]"
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
        fi
      done
    fi

    # Also check legacy location
    local repo_root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
    local legacy_worktrees="$repo_root/../worktrees"

    if [ -d "$legacy_worktrees" ]; then
      local skip_legacy=false
      if [ -n "$SHELLFLOW_PROJECTS_ROOT" ]; then
        local resolved_legacy=$(cd "$legacy_worktrees" 2>/dev/null && pwd)
        local resolved_projects="$SHELLFLOW_PROJECTS_ROOT/worktrees"
        if [[ "$resolved_legacy" == "$resolved_projects"* ]]; then
          skip_legacy=true
        fi
      fi

      if [ "$skip_legacy" = false ]; then
        for agent_dir in "$legacy_worktrees"/*/; do
          if [ -d "$agent_dir" ]; then
            found_any=true
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
      fi
    fi

    if [ "$found_any" = false ]; then
      echo "No worktrees found"
    fi
    return
  fi

  # Show changes for specific agent - find it across all repos
  local worktree_path=$(_find_agent_worktree "$name")

  if [ -z "$worktree_path" ]; then
    echo "Agent worktree '$name' not found"
    return 1
  fi

  local repo_name=$(_get_repo_from_worktree "$worktree_path")
  local header="CHANGES: $name"
  if [ -n "$repo_name" ]; then
    header="CHANGES: $name [$repo_name]"
  fi

  echo "╔═══════════════════════════════════════════════════════════════╗"
  echo "║  $header"
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

sf-status() {
  echo "╔═══════════════════════════════════════════════════════════════╗"
  echo "║                    SHELLFLOW STATUS                           ║"
  echo "╚═══════════════════════════════════════════════════════════════╝"
  echo ""

  echo "TMUX WINDOWS:"
  tmux list-windows -F "  [#{window_index}] #{window_name} #{?window_active,← YOU,}"
  echo ""

  echo "AGENT WORKTREES:"
  local found_any=false

  # Check SHELLFLOW_PROJECTS_ROOT first (multi-repo mode)
  if [ -n "$SHELLFLOW_PROJECTS_ROOT" ] && [ -d "$SHELLFLOW_PROJECTS_ROOT/worktrees" ]; then
    for repo_dir in "$SHELLFLOW_PROJECTS_ROOT/worktrees"/*/; do
      if [ -d "$repo_dir" ]; then
        local repo_name=$(basename "$repo_dir")
        local has_agents=false

        for agent_dir in "$repo_dir"/*/; do
          if [ -d "$agent_dir" ]; then
            if [ "$has_agents" = false ]; then
              echo "  [$repo_name]"
              has_agents=true
              found_any=true
            fi
            local agent_name=$(basename "$agent_dir")
            local changed=$(git -C "$agent_dir" diff --stat --shortstat 2>/dev/null | tail -1)
            if [ -n "$changed" ]; then
              echo "    $agent_name: $changed"
            else
              echo "    $agent_name: (no changes)"
            fi
          fi
        done
      fi
    done
  fi

  # Also check current repo's worktrees (backwards compatible)
  local repo_root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
  local legacy_worktrees="$repo_root/../worktrees"

  # Only show legacy if not already covered by SHELLFLOW_PROJECTS_ROOT
  if [ -d "$legacy_worktrees" ]; then
    local skip_legacy=false
    if [ -n "$SHELLFLOW_PROJECTS_ROOT" ]; then
      local resolved_legacy=$(cd "$legacy_worktrees" 2>/dev/null && pwd)
      local resolved_projects="$SHELLFLOW_PROJECTS_ROOT/worktrees"
      if [[ "$resolved_legacy" == "$resolved_projects"* ]]; then
        skip_legacy=true
      fi
    fi

    if [ "$skip_legacy" = false ]; then
      for agent_dir in "$legacy_worktrees"/*/; do
        if [ -d "$agent_dir" ]; then
          found_any=true
          local agent_name=$(basename "$agent_dir")
          local changed=$(git -C "$agent_dir" diff --stat --shortstat 2>/dev/null | tail -1)
          if [ -n "$changed" ]; then
            echo "  $agent_name: $changed"
          else
            echo "  $agent_name: (no changes)"
          fi
        fi
      done
    fi
  fi

  if [ "$found_any" = false ]; then
    echo "  (no agents)"
  fi
  echo ""

  echo "COMMANDS:"
  echo "  sf-progress <name>  - see agent output"
  echo "  sf-changes [name]   - see code changes"
  echo "  sf-cleanup <name>   - remove agent"
  echo "  sf-peek <name>      - switch to window"
}

# Peek at a window
sf-peek() {
  local name=$1
  if [ -z "$name" ]; then
    echo "Usage: peek <window>"
    return 1
  fi
  tmux select-window -t "$name"
}

# Cleanup agent (kill window + remove worktree)
sf-cleanup() {
  local name=$1
  if [ -z "$name" ]; then
    echo "Usage: cleanup <agent-name>"
    return 1
  fi

  tmux kill-window -t "$name" 2>/dev/null

  # Find the worktree across all repos
  local worktree_path=$(_find_agent_worktree "$name")

  if [ -n "$worktree_path" ]; then
    # Get the repo root from the worktree to run git commands
    local repo_root=$(git -C "$worktree_path" rev-parse --show-toplevel 2>/dev/null)
    if [ -n "$repo_root" ]; then
      git -C "$repo_root" worktree remove --force "$worktree_path" 2>/dev/null
      git -C "$repo_root" branch -D "$name" 2>/dev/null
    fi
  else
    # Fallback to legacy behavior
    local repo_root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
    git worktree remove --force "$repo_root/../worktrees/$name" 2>/dev/null
    git branch -D "$name" 2>/dev/null
  fi

  echo "✓ Cleaned up '$name'"
}

# Cleanup all agents
sf-cleanup-all() {
  echo "Cleaning up all agents..."
  local found_any=false

  # Check SHELLFLOW_PROJECTS_ROOT first (multi-repo mode)
  if [ -n "$SHELLFLOW_PROJECTS_ROOT" ] && [ -d "$SHELLFLOW_PROJECTS_ROOT/worktrees" ]; then
    for repo_dir in "$SHELLFLOW_PROJECTS_ROOT/worktrees"/*/; do
      if [ -d "$repo_dir" ]; then
        for agent_dir in "$repo_dir"/*/; do
          if [ -d "$agent_dir" ]; then
            found_any=true
            local agent_name=$(basename "$agent_dir")
            sf-cleanup "$agent_name"
          fi
        done
      fi
    done
  fi

  # Also check legacy location
  local repo_root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
  local legacy_worktrees="$repo_root/../worktrees"

  if [ -d "$legacy_worktrees" ]; then
    local skip_legacy=false
    if [ -n "$SHELLFLOW_PROJECTS_ROOT" ]; then
      local resolved_legacy=$(cd "$legacy_worktrees" 2>/dev/null && pwd)
      local resolved_projects="$SHELLFLOW_PROJECTS_ROOT/worktrees"
      if [[ "$resolved_legacy" == "$resolved_projects"* ]]; then
        skip_legacy=true
      fi
    fi

    if [ "$skip_legacy" = false ]; then
      for agent_dir in "$legacy_worktrees"/*/; do
        if [ -d "$agent_dir" ]; then
          found_any=true
          local agent_name=$(basename "$agent_dir")
          cleanup "$agent_name"
        fi
      done
    fi
  fi

  if [ "$found_any" = false ]; then
    echo "No agents to clean up"
    return
  fi

  echo "✓ All agents cleaned up"
}

# ============================================
# ALIASES
# ============================================

alias st='sf-status'
alias cu='sf-cleanup'

# List all agents across all repos (works from anywhere)
sf-list-agents() {
  echo "╔═══════════════════════════════════════════════════════════════╗"
  echo "║  ALL AGENTS                                                   ║"
  echo "╚═══════════════════════════════════════════════════════════════╝"
  echo ""

  local found_any=false

  if [ -z "$SHELLFLOW_PROJECTS_ROOT" ]; then
    echo "Set SHELLFLOW_PROJECTS_ROOT to use this command from anywhere"
    echo "Example: export SHELLFLOW_PROJECTS_ROOT=~/projects"
    return 1
  fi

  if [ ! -d "$SHELLFLOW_PROJECTS_ROOT/worktrees" ]; then
    echo "(no agents)"
    return
  fi

  printf "%-15s %-20s %-10s %s\n" "REPO" "AGENT" "STATUS" "CHANGES"
  printf "%-15s %-20s %-10s %s\n" "────" "─────" "──────" "───────"

  for repo_dir in "$SHELLFLOW_PROJECTS_ROOT/worktrees"/*/; do
    if [ -d "$repo_dir" ]; then
      local repo_name=$(basename "$repo_dir")

      for agent_dir in "$repo_dir"/*/; do
        if [ -d "$agent_dir" ]; then
          found_any=true
          local agent_name=$(basename "$agent_dir")

          # Check if tmux window exists (agent still running)
          local agent_status="done"
          if tmux list-windows -F "#{window_name}" 2>/dev/null | grep -q "^${agent_name}$"; then
            agent_status="running"
          fi

          # Count changed files
          local changed_count=$(git -C "$agent_dir" diff --name-only 2>/dev/null | wc -l | tr -d ' ')
          local committed_count=$(git -C "$agent_dir" log --oneline main..HEAD 2>/dev/null | wc -l | tr -d ' ')

          local changes_info="${changed_count} uncommitted"
          if [ "$committed_count" -gt 0 ]; then
            changes_info="$changes_info, ${committed_count} commits"
          fi

          printf "%-15s %-20s %-10s %s\n" "$repo_name" "$agent_name" "$agent_status" "$changes_info"
        fi
      done
    fi
  done

  if [ "$found_any" = false ]; then
    echo "(no agents)"
  fi

  echo ""
  echo "Commands:"
  echo "  sf-changes <agent>       - see uncommitted changes"
  echo "  sf-diff-agent <agent>    - see branch vs main"
  echo "  sf-progress <agent>      - see agent output"
}

alias la='sf-list-agents'

# ============================================
# TAB COMPLETION
# ============================================

_shellflow_windows() {
  local windows
  windows=($(tmux list-windows -F "#{window_name}" 2>/dev/null))
  _describe 'windows' windows
}

_shellflow_agents() {
  local agents=()

  # Check SHELLFLOW_PROJECTS_ROOT first (multi-repo mode)
  if [ -n "$SHELLFLOW_PROJECTS_ROOT" ] && [ -d "$SHELLFLOW_PROJECTS_ROOT/worktrees" ]; then
    for repo_dir in "$SHELLFLOW_PROJECTS_ROOT/worktrees"/*/; do
      if [ -d "$repo_dir" ]; then
        for agent_dir in "$repo_dir"/*/; do
          if [ -d "$agent_dir" ]; then
            agents+=($(basename "$agent_dir"))
          fi
        done
      fi
    done
  fi

  # Also check legacy location
  local repo_root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
  local legacy_worktrees="$repo_root/../worktrees"

  if [ -d "$legacy_worktrees" ]; then
    local skip_legacy=false
    if [ -n "$SHELLFLOW_PROJECTS_ROOT" ]; then
      local resolved_legacy=$(cd "$legacy_worktrees" 2>/dev/null && pwd)
      local resolved_projects="$SHELLFLOW_PROJECTS_ROOT/worktrees"
      if [[ "$resolved_legacy" == "$resolved_projects"* ]]; then
        skip_legacy=true
      fi
    fi

    if [ "$skip_legacy" = false ]; then
      agents+=($(ls "$legacy_worktrees" 2>/dev/null))
    fi
  fi

  _describe 'agents' agents
}

_shellflow_repos() {
  local repos=()
  if [ -n "$SHELLFLOW_PROJECTS_ROOT" ] && [ -d "$SHELLFLOW_PROJECTS_ROOT" ]; then
    for dir in "$SHELLFLOW_PROJECTS_ROOT"/*/; do
      if [ -d "$dir/.git" ]; then
        repos+=($(basename "$dir"))
      fi
    done
  fi
  _describe 'repos' repos
}

if type compdef &>/dev/null; then
  compdef _shellflow_windows sf-progress sf-peek
  compdef _shellflow_agents sf-changes sf-cleanup
fi

# ============================================
# SPEC BUILDER & SPAWN FROM SPEC
# ============================================

# Interactive spec builder wizard
sf-build-specs() {
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
sf-spawn-from-spec() {
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
          sf-spawn-agent "$current_name" "$current_task" --model "$current_model" --tools "$current_tools"
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
      sf-spawn-agent "$current_name" "$current_task" --model "$current_model" --tools "$current_tools"
      echo ""
    fi
  fi

  echo "Done! Use 'sf-status' to see all agents."
}

# Alias
alias bs='sf-build-specs'
alias sfs='sf-spawn-from-spec'

# ============================================
# HELP
# ============================================

sf-help() {
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
║   sf-build-specs (bs)         Create agent specs interactively   ║
║   sf-spawn-from-spec (sfs)    Spawn agents from spec file        ║
║                                                                   ║
║ SPAWN AGENTS (autonomous, non-interactive):                       ║
║   sf-spawn-agent <name> <task> [--model X] [--tools Y] [--repo R]║
║   sa auth "implement oauth" --model haiku                        ║
║   sa api-fix "fix bug" --repo notetaker-api                      ║
║                                                                   ║
║ MULTI-REPO MODE:                                                  ║
║   export SHELLFLOW_PROJECTS_ROOT=~/projects                      ║
║   sf-spawn-agent auth "task" --repo notetaker-api                ║
║   sf-spawn-agent rec "task" --repo notetaker-recorder            ║
║                                                                   ║
║ SPAWN WATCHERS:                                                   ║
║   sf-spawn-watcher <name> <cmd>  Generic watcher                 ║
║   sf-watch-k8s pod1 pod2      K8s pod logs (set K8S_NAMESPACE)   ║
║   sf-watch-k8s-label app=api  K8s pods by label                  ║
║                                                                   ║
║ MONITOR & CONTROL:                                                ║
║   sf-status                   Overview of all agents             ║
║   sf-list-agents (la)         List all agents (works from anywhere)║
║   sf-progress <name>          See agent output                   ║
║   sf-changes [name]           See uncommitted changes in worktree║
║   sf-diff-agent <name> (da)   See branch vs main (committed work)║
║   sf-peek <name>              Switch to window                   ║
║   sf-cleanup <name>           Remove agent + worktree            ║
║   sf-cleanup-all              Remove all agents                  ║
╚═══════════════════════════════════════════════════════════════════╝
EOF
}

echo "Shellflow loaded. Type 'sf-help' for commands."
