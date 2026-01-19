#!/bin/bash
# Shellflow Spec Builder - Interactive wizard for creating agent specs
# Usage: build-specs [output-file]

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Default output
SPECS_DIR="${SPECS_DIR:-./specs}"
OUTPUT_FILE=""

# Arrays to store agent data
declare -a AGENT_NAMES
declare -a AGENT_TASKS
declare -a AGENT_MODELS
declare -a AGENT_SCOPES
declare -a AGENT_EXCLUDES
declare -a AGENT_VERIFIES
declare -a AGENT_TOOLS

# ============================================
# Helper Functions
# ============================================

print_header() {
  echo ""
  echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${BLUE}║${NC}${BOLD}                    SHELLFLOW SPEC BUILDER                     ${NC}${BLUE}║${NC}"
  echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════╝${NC}"
  echo ""
}

print_section() {
  echo ""
  echo -e "${CYAN}─────────────────────────────────────────────────────────────────${NC}"
  echo -e "${BOLD}$1${NC}"
  echo -e "${CYAN}─────────────────────────────────────────────────────────────────${NC}"
}

prompt() {
  local var_name=$1
  local prompt_text=$2
  local default=$3

  if [ -n "$default" ]; then
    echo -en "${GREEN}?${NC} $prompt_text ${YELLOW}[$default]${NC}: "
    read input
    eval "$var_name=\"${input:-$default}\""
  else
    echo -en "${GREEN}?${NC} $prompt_text: "
    read input
    eval "$var_name=\"$input\""
  fi
}

prompt_required() {
  local var_name=$1
  local prompt_text=$2
  local value=""

  while [ -z "$value" ]; do
    echo -en "${GREEN}?${NC} $prompt_text: "
    read value
    if [ -z "$value" ]; then
      echo -e "${RED}  This field is required${NC}"
    fi
  done
  eval "$var_name=\"$value\""
}

prompt_multiline() {
  local var_name=$1
  local prompt_text=$2

  echo -e "${GREEN}?${NC} $prompt_text"
  echo -e "  ${YELLOW}(Enter each item on a new line, empty line to finish)${NC}"

  local lines=""
  while true; do
    echo -n "  > "
    read line
    if [ -z "$line" ]; then
      break
    fi
    if [ -n "$lines" ]; then
      lines="$lines|$line"
    else
      lines="$line"
    fi
  done
  eval "$var_name=\"$lines\""
}

# ============================================
# Main Flow
# ============================================

print_header

# Ask for number of agents
prompt num_agents "How many agents do you need?" "2"

if ! [[ "$num_agents" =~ ^[0-9]+$ ]] || [ "$num_agents" -lt 1 ]; then
  echo -e "${RED}Invalid number. Please enter a positive integer.${NC}"
  exit 1
fi

echo ""
echo -e "${BOLD}Creating specs for $num_agents agent(s)${NC}"

# Collect info for each agent
for ((i=1; i<=num_agents; i++)); do
  print_section "AGENT $i of $num_agents"

  # Name
  prompt_required name "Name (short, no spaces, e.g., 'auth', 'api', 'db')"
  AGENT_NAMES+=("$name")

  # Task description
  echo ""
  echo -e "${GREEN}?${NC} What should this agent do?"
  echo -e "  ${YELLOW}(Be specific - what files to create/modify, what functionality)${NC}"
  echo -n "  > "
  read task
  while [ -z "$task" ]; do
    echo -e "${RED}  Task description is required${NC}"
    echo -n "  > "
    read task
  done
  AGENT_TASKS+=("$task")

  # Scope - what files/dirs to work on
  echo ""
  prompt_multiline scope "Which files/directories will this agent modify?"
  AGENT_SCOPES+=("$scope")

  # Excludes - what to avoid
  echo ""
  prompt_multiline excludes "Which files/directories should it NOT touch? (optional)"
  AGENT_EXCLUDES+=("$excludes")

  # Verification command
  echo ""
  prompt verify "How do we verify it worked? (test command)" "npm test"
  AGENT_VERIFIES+=("$verify")

  # Model selection
  echo ""
  echo -e "${GREEN}?${NC} Which model? ${YELLOW}[1=haiku, 2=sonnet, 3=opus]${NC} (default: 2)"
  echo -n "  > "
  read model_choice
  case "$model_choice" in
    1) model="haiku" ;;
    3) model="opus" ;;
    *) model="sonnet" ;;
  esac
  AGENT_MODELS+=("$model")

  # Tools (use default or customize)
  echo ""
  prompt tools "Allowed tools" "Read,Glob,Grep,Edit,Write,Bash"
  AGENT_TOOLS+=("$tools")

  echo ""
  echo -e "${GREEN}✓${NC} Agent '${BOLD}$name${NC}' configured"
done

# ============================================
# Collision Detection
# ============================================

print_section "COLLISION CHECK"

has_collision=false
declare -A scope_map

for ((i=0; i<num_agents; i++)); do
  name="${AGENT_NAMES[$i]}"
  scope="${AGENT_SCOPES[$i]}"

  # Split scope by | and check each path
  IFS='|' read -ra paths <<< "$scope"
  for path in "${paths[@]}"; do
    path=$(echo "$path" | xargs)  # trim whitespace
    if [ -n "$path" ]; then
      if [ -n "${scope_map[$path]}" ]; then
        echo -e "${RED}⚠ COLLISION:${NC} '$path' claimed by both '${scope_map[$path]}' and '$name'"
        has_collision=true
      else
        scope_map[$path]="$name"
        echo -e "${GREEN}✓${NC} $name: $path"
      fi
    fi
  done
done

if [ "$has_collision" = true ]; then
  echo ""
  echo -e "${YELLOW}Warning: Collisions detected. Agents may conflict.${NC}"
  echo -n "Continue anyway? [y/N]: "
  read continue_anyway
  if [[ ! "$continue_anyway" =~ ^[Yy]$ ]]; then
    echo "Aborted. Please re-run and fix collisions."
    exit 1
  fi
else
  echo ""
  echo -e "${GREEN}✓ No collisions detected${NC}"
fi

# ============================================
# Generate YAML Spec File
# ============================================

print_section "GENERATING SPEC FILE"

mkdir -p "$SPECS_DIR"

# Generate filename
timestamp=$(date +%Y-%m-%d-%H%M)
agent_names_str=$(IFS=-; echo "${AGENT_NAMES[*]}")
OUTPUT_FILE="${SPECS_DIR}/${timestamp}-${agent_names_str}.yaml"

# Write YAML
cat > "$OUTPUT_FILE" << EOF
# Shellflow Agent Spec
# Generated: $(date -Iseconds)
# Spawn with: spawn-from-spec $OUTPUT_FILE

agents:
EOF

for ((i=0; i<num_agents; i++)); do
  name="${AGENT_NAMES[$i]}"
  task="${AGENT_TASKS[$i]}"
  model="${AGENT_MODELS[$i]}"
  scope="${AGENT_SCOPES[$i]}"
  excludes="${AGENT_EXCLUDES[$i]}"
  verify="${AGENT_VERIFIES[$i]}"
  tools="${AGENT_TOOLS[$i]}"

  cat >> "$OUTPUT_FILE" << EOF
  - name: $name
    model: $model
    tools: $tools
    verify: $verify
    task: |
      $task

      SCOPE (files you may modify):
EOF

  # Add scope items
  IFS='|' read -ra paths <<< "$scope"
  for path in "${paths[@]}"; do
    path=$(echo "$path" | xargs)
    if [ -n "$path" ]; then
      echo "        - $path" >> "$OUTPUT_FILE"
    fi
  done

  # Add excludes if any
  if [ -n "$excludes" ]; then
    echo "      " >> "$OUTPUT_FILE"
    echo "      DO NOT MODIFY:" >> "$OUTPUT_FILE"
    IFS='|' read -ra paths <<< "$excludes"
    for path in "${paths[@]}"; do
      path=$(echo "$path" | xargs)
      if [ -n "$path" ]; then
        echo "        - $path" >> "$OUTPUT_FILE"
      fi
    done
  fi

  echo "" >> "$OUTPUT_FILE"
done

echo -e "${GREEN}✓${NC} Spec saved to: ${BOLD}$OUTPUT_FILE${NC}"

# ============================================
# Show Summary & Offer to Spawn
# ============================================

print_section "SUMMARY"

echo ""
for ((i=0; i<num_agents; i++)); do
  name="${AGENT_NAMES[$i]}"
  model="${AGENT_MODELS[$i]}"
  task="${AGENT_TASKS[$i]}"
  echo -e "${BOLD}$name${NC} (${CYAN}$model${NC})"
  echo "  $task"
  echo ""
done

echo -e "${CYAN}─────────────────────────────────────────────────────────────────${NC}"
echo ""
echo -n "Spawn these agents now? [y/N]: "
read spawn_now

if [[ "$spawn_now" =~ ^[Yy]$ ]]; then
  echo ""
  echo -e "${BLUE}Spawning agents...${NC}"

  # Source shellflow if not already loaded
  if ! type spawn-from-spec &>/dev/null; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "$SCRIPT_DIR/../config/shellflow.zsh" 2>/dev/null || true
  fi

  if type spawn-from-spec &>/dev/null; then
    spawn-from-spec "$OUTPUT_FILE"
  else
    echo -e "${YELLOW}spawn-from-spec not available. Run manually:${NC}"
    echo "  source ~/.zshrc"
    echo "  spawn-from-spec $OUTPUT_FILE"
  fi
else
  echo ""
  echo "To spawn later, run:"
  echo -e "  ${BOLD}spawn-from-spec $OUTPUT_FILE${NC}"
fi

echo ""
echo -e "${GREEN}Done!${NC}"
