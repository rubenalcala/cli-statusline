# claude-statusline

Status line for **Claude Code** (`claude`) — displays the active model, session context usage, git branch, host memory (RAM & CPU), and real-time quota consumption.

## What it shows

The statusline renders exactly 3 lines (or 2 if quotas are not present), automatically padding elements to the left and right edges of the terminal inside a structured box frame that scales seamlessly when you resize your terminal (without elements wrapping or splitting into extra lines):

### Rendering Example (Terminal width: 80 columns)
```text
╭─Claude 3.5 Sonnet                                                        main*
├─ctx ██▒░░░░░░░ 27.5%                                                   RAM:59%
╰─5H ██░░░░░░ 29.4% 1h 28m  7D ███████░ 88.2% 6d 20h                            
```

### Rendering Example (Terminal width: 110 columns)
```text
╭─Claude 3.5 Sonnet                                                                                      main*
├─ctx ██▒░░░░░░░ 27.5% (20.0K/200.0K)                                                                  RAM:59%
╰─5H ██░░░░░░ 29.4% 1h 28m  7D ███████░ 88.2% 6d 20h                                                          
```

| Line | Left Side Component | Right Side Component |
|------|---------------------|----------------------|
| **Line 1** | Active Model ID / Display Name (starts with `╭─`) | Git branch name (`*` = uncommitted changes, green/red status) |
| **Line 2** | Context Bar & Tokens Counter (starts with `├─` or `╰─`, auto-scales on narrow screens) | Host memory utilization (`RAM:XX%`) |
| **Line 3** | Quotas progress bars (`5H` & `7D`) & reset times (starts with `╰─`, read from `~/.cache/ccstatusline/usage.json`) | Empty (right aligned) |

> Quotas are automatically integrated from `ccstatusline` cache for Claude Code. If no quota cache is available or quotas are disabled, this line is cleanly omitted and the box collapses to 2 lines.

## Requirements

- [`jq`](https://jqlang.github.io/jq/) — for JSON parsing
- `git` — for branch info
- Claude Code (`claude`) installed and configured

## Installation

```bash
git clone https://github.com/rubenalcala/claude-statusline)
cd claude-statusline
bash bin/install.sh
```

Restart `claude` to see the status line.

## Uninstall

```bash
bash bin/uninstall.sh
```

This restores your previous statusline (if any) and removes the `statusLine` entry from `settings.json`.

## Project structure

```
claude-statusline/
├── bin/
│   ├── statusline.sh   # Main script (copied to ~/.claude/)
│   ├── install.sh      # Installer
│   └── uninstall.sh    # Uninstaller
└── README.md
```

## How it works

`claude` runs the command configured under `statusLine` in `settings.json`, passing the current session state as JSON via stdin. The script parses it and returns ANSI-colored text for the terminal.

The installer configures the following in `~/.claude/settings.json`:

```json
"statusLine": {
  "type": "command",
  "command": "bash \"$HOME/.claude/statusline.sh\"",
  "enabled": true
}
```

You can also toggle the status line at any time from within `claude` using `/statusline`.
