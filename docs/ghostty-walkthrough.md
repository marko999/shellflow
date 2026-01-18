# Ghostty Terminal Walkthrough

Ghostty is a fast, feature-rich, cross-platform terminal emulator that uses platform-native UI and GPU acceleration. Built by Mitchell Hashimoto (creator of Vagrant, Terraform, Consul).

## Installation

```bash
brew install --cask ghostty
```

## Why Ghostty?

- **Native macOS feel**: Built with SwiftUI, uses Metal renderer
- **Fast**: 2-5x faster than WezTerm in benchmarks
- **Simple config**: Plain key-value text file (no Lua or complex formats)
- **Modern features**: Kitty graphics protocol, ligatures, true color
- **Lightweight**: Single binary, minimal dependencies

## Configuration

Ghostty uses a simple config file at `~/.config/ghostty/config`

```bash
mkdir -p ~/.config/ghostty
touch ~/.config/ghostty/config
```

### Basic Configuration

```ini
# ~/.config/ghostty/config

# Font
font-family = "JetBrains Mono"
font-size = 14

# Theme
theme = dark

# Window
window-decoration = true
window-padding-x = 10
window-padding-y = 10

# Cursor
cursor-style = block
cursor-style-blink = false

# Scrollback
scrollback-limit = 50000

# Shell integration
shell-integration = zsh

# Mouse
mouse-hide-while-typing = true

# Clipboard
clipboard-read = allow
clipboard-write = allow

# Performance
vsync = true
```

### Keyboard Shortcuts (Default)

| Action | Shortcut |
|--------|----------|
| New Tab | `Cmd+T` |
| Close Tab | `Cmd+W` |
| Next Tab | `Cmd+Shift+]` |
| Previous Tab | `Cmd+Shift+[` |
| Split Horizontal | `Cmd+D` |
| Split Vertical | `Cmd+Shift+D` |
| Navigate Panes | `Cmd+Option+Arrow` |
| Toggle Fullscreen | `Cmd+Enter` |
| Increase Font | `Cmd++` |
| Decrease Font | `Cmd+-` |
| Reset Font | `Cmd+0` |
| Search | `Cmd+F` |
| Copy | `Cmd+C` |
| Paste | `Cmd+V` |

### Custom Keybindings

```ini
# Custom keybindings
keybind = cmd+shift+t=new_window
keybind = cmd+k=clear_screen
keybind = cmd+shift+enter=toggle_split_zoom
```

## tmux Integration

Ghostty works great with tmux. Recommended settings:

```ini
# Better colors with tmux
term = xterm-256color

# Disable Ghostty tabs if using tmux
window-save-state = never
```

## Themes

Ghostty supports many built-in themes:

```ini
# Built-in themes
theme = Dracula
theme = Gruvbox Dark
theme = Nord
theme = One Dark
theme = Solarized Dark
theme = Tokyo Night
```

Or create a custom theme:

```ini
# Custom colors
background = 1e1e2e
foreground = cdd6f4
cursor-color = f5e0dc

# Normal colors
palette = 0=#45475a
palette = 1=#f38ba8
palette = 2=#a6e3a1
palette = 3=#f9e2af
palette = 4=#89b4fa
palette = 5=#f5c2e7
palette = 6=#94e2d5
palette = 7=#bac2de

# Bright colors
palette = 8=#585b70
palette = 9=#f38ba8
palette = 10=#a6e3a1
palette = 11=#f9e2af
palette = 12=#89b4fa
palette = 13=#f5c2e7
palette = 14=#94e2d5
palette = 15=#a6adc8
```

## Shell Integration

Ghostty has built-in shell integration for enhanced features:

```ini
shell-integration = zsh
shell-integration-features = cursor,sudo,title
```

Features:
- **cursor**: Jump to prompt
- **sudo**: Password prompt styling
- **title**: Automatic window title

## Quick Terminal (Quake Mode)

Ghostty supports a quick terminal that drops down from the top:

```ini
# Enable quick terminal
quick-terminal-position = top
quick-terminal-screen = main
quick-terminal-animation-duration = 0.2
```

Trigger with global hotkey (configure in System Settings or with third-party tool).

## Performance Tips

```ini
# Maximize performance
vsync = true
window-vsync = true

# Reduce memory for many tabs
scrollback-limit = 10000

# Disable unused features
mouse-scroll-multiplier = 1
```

## Useful Commands

```bash
# Check version
ghostty --version

# Validate config
ghostty +validate-config

# List available themes
ghostty +list-themes

# List available fonts
ghostty +list-fonts

# Show all config options
ghostty +help
```

## Shellflow-Specific Config

For use with Shellflow agentic workflows:

```ini
# ~/.config/ghostty/config

# Font
font-family = "JetBrains Mono"
font-size = 13

# Dark theme for long sessions
theme = Tokyo Night

# Large scrollback for agent output
scrollback-limit = 100000

# Window settings
window-padding-x = 8
window-padding-y = 8
window-decoration = true

# Disable tabs (using tmux instead)
window-save-state = never

# Term setting for tmux compatibility
term = xterm-256color

# Shell integration
shell-integration = zsh

# Performance
vsync = true

# Selection
copy-on-select = clipboard
```

## Troubleshooting

### Fonts not rendering
```bash
# List available fonts
ghostty +list-fonts | grep -i "mono"
```

### Colors look wrong in tmux
```ini
term = xterm-256color
```

Also add to `~/.tmux.conf`:
```bash
set -g default-terminal "screen-256color"
set -ga terminal-overrides ",xterm-256color:Tc"
```

### High memory usage
Reduce scrollback:
```ini
scrollback-limit = 10000
```

## Resources

- [Official Website](https://ghostty.org)
- [GitHub](https://github.com/ghostty-org/ghostty)
- [Configuration Reference](https://ghostty.org/docs/config)
