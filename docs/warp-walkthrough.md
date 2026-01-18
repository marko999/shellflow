# Warp Terminal Walkthrough

Warp is a modern, Rust-based terminal with built-in AI assistance, block-based output, and collaboration features. It's designed for developer productivity.

## Installation

```bash
brew install --cask warp
```

Or download from [warp.dev](https://www.warp.dev)

## Why Warp?

- **Built-in AI**: Ask questions with `#` prefix
- **Block-based output**: Commands and outputs are grouped
- **Modern editing**: IDE-like text editing in the terminal
- **Command palette**: Searchable commands
- **Workflows**: Shareable command sequences
- **Collaboration**: Share terminal sessions (paid feature)

## Pricing

| Tier | AI Features | Cost |
|------|-------------|------|
| Free | Limited AI requests/month | $0 |
| Pro | More AI requests | $15/mo |
| Enterprise | Bring your own API keys | Custom |

**Note**: You cannot use your own Claude/OpenAI API key on Free/Pro tiers.

## Configuration

Warp uses a GUI for most settings: `Cmd+,`

Settings location: `~/.warp/`

### Theme

1. Open Settings (`Cmd+,`)
2. Go to Appearance
3. Select theme or create custom

Custom themes: `~/.warp/themes/`

```yaml
# ~/.warp/themes/custom.yaml
name: "My Custom Theme"
accent: "#89b4fa"
background: "#1e1e2e"
foreground: "#cdd6f4"
details: "darker"
terminal_colors:
  normal:
    black: "#45475a"
    red: "#f38ba8"
    green: "#a6e3a1"
    yellow: "#f9e2af"
    blue: "#89b4fa"
    magenta: "#f5c2e7"
    cyan: "#94e2d5"
    white: "#bac2de"
  bright:
    black: "#585b70"
    red: "#f38ba8"
    green: "#a6e3a1"
    yellow: "#f9e2af"
    blue: "#89b4fa"
    magenta: "#f5c2e7"
    cyan: "#94e2d5"
    white: "#a6adc8"
```

## Keyboard Shortcuts

### Essential Shortcuts

| Action | Shortcut |
|--------|----------|
| Command Palette | `Cmd+P` |
| Settings | `Cmd+,` |
| New Tab | `Cmd+T` |
| Close Tab | `Cmd+W` |
| Split Pane Right | `Cmd+D` |
| Split Pane Down | `Cmd+Shift+D` |
| Navigate Panes | `Cmd+Option+Arrow` |
| Clear Terminal | `Cmd+K` |
| Search | `Cmd+F` |
| AI Assistant | `Cmd+Shift+Space` or type `#` |

### Block Navigation

| Action | Shortcut |
|--------|----------|
| Select Block | Click on block |
| Copy Block Output | `Cmd+Shift+C` (with block selected) |
| Rerun Block | `Cmd+Shift+R` |
| Navigate Blocks | `Cmd+Up/Down` |
| Pin Block | `Cmd+Shift+P` |

### Editing

| Action | Shortcut |
|--------|----------|
| Multi-cursor | `Cmd+Click` |
| Select Word | `Double-click` |
| Move Cursor by Word | `Option+Arrow` |
| Delete Word | `Option+Backspace` |
| Jump to Start | `Cmd+Left` |
| Jump to End | `Cmd+Right` |

## AI Assistant

Warp's AI is triggered with `#`:

```bash
# How do I find large files on my system?
# What's the kubectl command to see pod logs?
# Explain this error: <paste error>
```

### AI Features

1. **Command suggestions**: Type `#` then your question
2. **Error explanation**: Click "Explain" on error output
3. **Command generation**: Describe what you want
4. **Documentation lookup**: Ask about tools

### Limitations (Free Tier)

- Limited requests per month
- Cannot use your own API keys
- Some features require Pro

## Blocks

Commands and outputs are grouped into "blocks":

### Block Actions

- **Copy output**: Click block → `Cmd+Shift+C`
- **Rerun command**: Click block → `Cmd+Shift+R`
- **Share block**: Right-click → Share
- **Bookmark block**: Click star icon
- **Pin block**: Keep visible while scrolling

### Block Navigation

```bash
# Jump to specific block
Cmd+G → enter block number

# Search within blocks
Cmd+F → search text
```

## Workflows

Workflows are shareable command sequences.

### Create a Workflow

1. `Cmd+P` → "Create Workflow"
2. Define steps
3. Add parameters
4. Save

### Example Workflow

```yaml
name: Deploy to Staging
steps:
  - command: git pull origin main
  - command: npm run build
  - command: npm run test
  - command: npm run deploy:staging
parameters:
  - name: branch
    default: main
```

### Run a Workflow

1. `Cmd+P` → Search workflow name
2. Or use Workflows panel

## Warp Drive

Warp Drive is the cloud sync feature:

- Sync themes across devices
- Share workflows with team
- Sync settings

Enable in Settings → Warp Drive

## tmux Integration

Warp works with tmux but has some quirks:

```bash
# tmux in Warp loses some features:
# - Block-based output becomes linear
# - AI assistant still works
# - Some shortcuts conflict
```

Recommendation: Use Warp's built-in splits OR tmux, not both.

### If using tmux with Warp

```bash
# ~/.tmux.conf additions for Warp
set -g default-terminal "xterm-256color"
set -ga terminal-overrides ",xterm-256color:Tc"

# Remap conflicting shortcuts
unbind C-d  # Warp uses Cmd+D
```

## Warp vs Claude Code

Since you're using Claude Code, here's how they compare:

| Feature | Warp AI | Claude Code |
|---------|---------|-------------|
| Quick questions | `#` prefix | `claude -p` |
| Cost | Limited free / $15 Pro | Your API key |
| Depth | Simple commands | Full coding assistant |
| Integration | Built into terminal | Separate CLI |

**Recommendation**: Use Claude Code for AI (free with your API key), use Warp just as a terminal if you like its UI.

## Shellflow with Warp

For agentic workflows, Warp can work but has limitations:

### What works well:
- Block-based output helps track agent responses
- AI for quick command help
- Modern editing

### What doesn't work well:
- tmux integration is awkward
- No native way to broadcast to panes
- AI quota limits

### Recommended Setup

If using Warp with Shellflow:

1. Use Warp's native splits instead of tmux
2. Use Claude Code for AI (unlimited with your API)
3. Use Warp's command palette for navigation

```bash
# In Warp, instead of tmux:
Cmd+D          # Split right (new agent)
Cmd+Shift+D    # Split down (new agent)
Cmd+Option+←→  # Navigate agents
```

## Customization

### Input Position

Settings → Features → Input position
- Bottom (default)
- Top
- Floating

### Font

Settings → Appearance → Font
- Supports ligatures
- Configurable line height

### Prompt

Warp has its own prompt or can use yours:

Settings → Features → Prompt
- Warp prompt (modern look)
- Your shell prompt (PS1)

## Privacy Considerations

Warp collects telemetry by default:

Settings → Privacy
- Disable telemetry if concerned
- AI queries go to Warp's servers

## Troubleshooting

### Slow startup
```bash
# Check shell startup time
time zsh -i -c exit

# Warp-specific: disable features
Settings → Features → disable unused
```

### SSH not working well
Warp has known issues with some SSH configs. Use standard Terminal/iTerm2 for SSH if needed.

### tmux issues
Many features break in tmux. Either:
- Don't use tmux with Warp
- Use Warp's native multiplexing

## Resources

- [Official Website](https://www.warp.dev)
- [Documentation](https://docs.warp.dev)
- [Keyboard Shortcuts](https://docs.warp.dev/features/keyboard-shortcuts)
- [Workflows Guide](https://docs.warp.dev/features/warp-drive/workflows)
