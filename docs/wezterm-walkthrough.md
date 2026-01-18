# WezTerm Terminal Walkthrough

WezTerm is a GPU-accelerated cross-platform terminal emulator and multiplexer written in Rust. Its standout feature is Lua-based configuration, making it highly programmable.

## Installation

```bash
brew install --cask wezterm
```

## Why WezTerm?

- **Lua configuration**: Full programming language for config
- **Built-in multiplexer**: Can replace tmux for some workflows
- **Cross-platform**: Identical config works on macOS, Linux, Windows
- **SSH integration**: First-class remote workflow support
- **Programmable**: Events, callbacks, dynamic behavior

## Configuration

WezTerm uses Lua config at `~/.wezterm.lua`

```bash
touch ~/.wezterm.lua
```

### Basic Configuration

```lua
-- ~/.wezterm.lua
local wezterm = require 'wezterm'
local config = wezterm.config_builder()

-- Font
config.font = wezterm.font('JetBrains Mono')
config.font_size = 14.0

-- Color scheme
config.color_scheme = 'Tokyo Night'

-- Window
config.window_decorations = "RESIZE"
config.window_padding = {
  left = 10,
  right = 10,
  top = 10,
  bottom = 10,
}

-- Tab bar
config.hide_tab_bar_if_only_one_tab = true
config.tab_bar_at_bottom = false

-- Cursor
config.default_cursor_style = 'SteadyBlock'

-- Scrollback
config.scrollback_lines = 50000

-- Performance
config.animation_fps = 60
config.max_fps = 120

return config
```

### Keyboard Shortcuts (Default)

| Action | Shortcut |
|--------|----------|
| New Tab | `Cmd+T` |
| Close Tab | `Cmd+W` |
| Next Tab | `Cmd+Shift+]` |
| Previous Tab | `Cmd+Shift+[` |
| Split Horizontal | `Cmd+Shift+\` |
| Split Vertical | `Cmd+\` |
| Navigate Panes | `Cmd+Arrow` |
| Toggle Fullscreen | `Cmd+Enter` |
| Copy | `Cmd+C` |
| Paste | `Cmd+V` |
| Search | `Cmd+F` |
| Command Palette | `Cmd+Shift+P` |

### Custom Keybindings

```lua
config.keys = {
  -- Split panes like tmux
  {
    key = '|',
    mods = 'CMD|SHIFT',
    action = wezterm.action.SplitHorizontal { domain = 'CurrentPaneDomain' },
  },
  {
    key = '-',
    mods = 'CMD',
    action = wezterm.action.SplitVertical { domain = 'CurrentPaneDomain' },
  },
  -- Navigate panes with vim keys
  {
    key = 'h',
    mods = 'CMD|SHIFT',
    action = wezterm.action.ActivatePaneDirection 'Left',
  },
  {
    key = 'l',
    mods = 'CMD|SHIFT',
    action = wezterm.action.ActivatePaneDirection 'Right',
  },
  {
    key = 'k',
    mods = 'CMD|SHIFT',
    action = wezterm.action.ActivatePaneDirection 'Up',
  },
  {
    key = 'j',
    mods = 'CMD|SHIFT',
    action = wezterm.action.ActivatePaneDirection 'Down',
  },
  -- Clear scrollback
  {
    key = 'k',
    mods = 'CMD',
    action = wezterm.action.ClearScrollback 'ScrollbackAndViewport',
  },
}
```

## Built-in Multiplexer

WezTerm has a built-in multiplexer, eliminating the need for tmux in some workflows:

```lua
-- Enable built-in multiplexer
config.unix_domains = {
  {
    name = 'unix',
  },
}

-- Default to multiplexer domain
config.default_gui_startup_args = { 'connect', 'unix' }
```

### Multiplexer Commands

```bash
# Start background mux server
wezterm start --daemon

# Connect to existing session
wezterm connect unix

# List sessions
wezterm cli list

# Spawn new tab in existing session
wezterm cli spawn
```

## SSH Integration

WezTerm has excellent SSH support:

```lua
config.ssh_domains = {
  {
    name = 'dev-server',
    remote_address = 'dev.example.com',
    username = 'myuser',
  },
  {
    name = 'prod-server',
    remote_address = 'prod.example.com',
    username = 'admin',
  },
}
```

Connect with:
```bash
wezterm connect dev-server
```

## Workspaces

WezTerm supports workspaces (like tmux sessions):

```lua
config.keys = {
  -- Switch workspace
  {
    key = 's',
    mods = 'CMD|SHIFT',
    action = wezterm.action.ShowLauncherArgs { flags = 'WORKSPACES' },
  },
  -- Create new workspace
  {
    key = 'n',
    mods = 'CMD|SHIFT',
    action = wezterm.action.PromptInputLine {
      description = 'Enter new workspace name',
      action = wezterm.action_callback(function(window, pane, line)
        if line then
          window:perform_action(
            wezterm.action.SwitchToWorkspace { name = line },
            pane
          )
        end
      end),
    },
  },
}
```

## Dynamic Configuration

WezTerm can react to events:

```lua
-- Change color scheme based on time
wezterm.on('update-status', function(window, pane)
  local time = os.date('*t')
  if time.hour >= 18 or time.hour < 6 then
    window:set_config_overrides({ color_scheme = 'Tokyo Night' })
  else
    window:set_config_overrides({ color_scheme = 'Tokyo Night Day' })
  end
end)
```

## Tab Title Customization

```lua
-- Custom tab titles
wezterm.on('format-tab-title', function(tab, tabs, panes, config, hover, max_width)
  local title = tab.active_pane.title
  if tab.is_active then
    return {
      { Background = { Color = '#1e1e2e' } },
      { Foreground = { Color = '#89b4fa' } },
      { Text = ' ' .. title .. ' ' },
    }
  end
  return ' ' .. title .. ' '
end)
```

## Themes

```lua
-- Built-in schemes
config.color_scheme = 'Catppuccin Mocha'
config.color_scheme = 'Dracula'
config.color_scheme = 'Gruvbox Dark'
config.color_scheme = 'Nord'
config.color_scheme = 'One Dark'

-- List all available schemes
-- wezterm ls-colors
```

Custom colors:
```lua
config.colors = {
  foreground = '#cdd6f4',
  background = '#1e1e2e',
  cursor_bg = '#f5e0dc',
  cursor_fg = '#1e1e2e',
  selection_bg = '#585b70',
  selection_fg = '#cdd6f4',
  ansi = {
    '#45475a', '#f38ba8', '#a6e3a1', '#f9e2af',
    '#89b4fa', '#f5c2e7', '#94e2d5', '#bac2de',
  },
  brights = {
    '#585b70', '#f38ba8', '#a6e3a1', '#f9e2af',
    '#89b4fa', '#f5c2e7', '#94e2d5', '#a6adc8',
  },
}
```

## tmux Integration

If you prefer tmux over WezTerm's built-in multiplexer:

```lua
-- Disable WezTerm tab bar when using tmux
config.hide_tab_bar_if_only_one_tab = true

-- Better colors
config.term = 'xterm-256color'
```

## Performance Tips

```lua
-- Optimize for performance
config.front_end = 'WebGpu'  -- or 'OpenGL'
config.animation_fps = 60
config.max_fps = 120
config.scrollback_lines = 10000  -- Lower = less memory

-- Disable features you don't use
config.enable_scroll_bar = false
config.enable_wayland = false  -- macOS only
```

## Shellflow-Specific Config

For use with Shellflow agentic workflows:

```lua
-- ~/.wezterm.lua
local wezterm = require 'wezterm'
local config = wezterm.config_builder()

-- Font
config.font = wezterm.font('JetBrains Mono')
config.font_size = 13.0

-- Theme
config.color_scheme = 'Tokyo Night'

-- Window
config.window_padding = { left = 8, right = 8, top = 8, bottom = 8 }
config.window_decorations = "RESIZE"

-- Hide tab bar (using tmux)
config.hide_tab_bar_if_only_one_tab = true

-- Large scrollback for agent output
config.scrollback_lines = 100000

-- Performance
config.front_end = 'WebGpu'
config.animation_fps = 60

-- Term for tmux compatibility
config.term = 'xterm-256color'

-- Keybindings for Shellflow
config.keys = {
  -- Quick clear
  { key = 'k', mods = 'CMD', action = wezterm.action.ClearScrollback 'ScrollbackAndViewport' },
}

return config
```

## Troubleshooting

### Font rendering issues
```lua
-- Try different font backends
config.freetype_load_target = 'Light'
config.freetype_render_target = 'HorizontalLcd'
```

### High memory usage
```lua
config.scrollback_lines = 10000
config.front_end = 'OpenGL'  -- Instead of WebGpu
```

### Slow startup
```bash
# Check what's slow
wezterm --config-file /dev/null
```

## Resources

- [Official Website](https://wezterm.org)
- [GitHub](https://github.com/wezterm/wezterm)
- [Configuration Reference](https://wezfurlong.org/wezterm/config/files.html)
- [Lua API](https://wezfurlong.org/wezterm/config/lua/general.html)
