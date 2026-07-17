# claude-statusline

Status line for **Claude Code** (`claude`) — displays the active model with thinking effort level, git branch, CPU load percentage, host memory (RAM), session context usage (with detailed input/output tokens), and real-time quota consumption.

## What it shows

The statusline renders exactly 3 lines (or 2 if quotas are not present), automatically padding elements inside a structured box frame that scales seamlessly when you resize your terminal (without elements wrapping or splitting into extra lines):

### Rendering Example (Terminal width: 100 columns)
```text
╭─Sonnet 5 (high) │ main* │ CPU:17% · RAM:65%                                                       
├─ctx ▒░░░░░░░░░ 8% (15K/200K) │ in 12K · out 3K                                                    
╰─5H ███████▒ 95% · 2h 45m │ 7D █████░░░ 65% · 3d 4h                                                
```

| Line | Left Side Component | Right Side Component |
|------|---------------------|----------------------|
| **Line 1** | Active Model ID / Display Name with thinking effort configured (e.g. `Sonnet 5 (high)`), Git branch name (`*` = uncommitted changes, green/red status), CPU percentage (`CPU:XX%`), and RAM percentage (`RAM:XX%`) (starts with `╭─`) | Empty (left-aligned ribbon) |
| **Line 2** | Context Bar & Tokens Counter: Context Bar (`ctx`), context percentage (`XX%`), raw tokens used/limit `(XXK/XXK)`, and total input/output tokens (`in XXK  out XXK`) (starts with `├─` or `╰─`) | Empty |
| **Line 3** | Quotas progress bars (`5H` & `7D`) & remaining/reset times (starts with `╰─`, read from `~/.cache/ccstatusline/usage.json`) | Empty |

> Quotas are automatically integrated from `ccstatusline` cache for Claude Code. If no quota cache is available or quotas are disabled, this line is cleanly omitted and the box collapses to 2 lines.

## Color and Formatting Rules

- **CPU and RAM**: Displayed in bright white by default, turning red (`197`, matching git dirty red) when usage/load is >= 80%.
- **Context details**: `ctx`, `in` and `out` text labels are highlighted in standard yellow (`FG_YELLOW`).
- **Quota Bars**:
  - `5H`: Always styled with cian/green color (`37`/`FG_BRIGHT_CYAN`) for the label, bar, and percentage.
  - `7D`: Always styled with purple color (`135`/`FG_BRIGHT_MAGENTA`) for the label, bar, and percentage.
- **Integers everywhere**: All percentage numbers and token counts are displayed as integers with no decimal places (e.g., `8%` instead of `7.5%`, `15K/200K` instead of `15.0K/200.0K`).

## Requirements

- [`jq`](https://jqlang.github.io/jq/) — for JSON parsing
- `git` — for branch info
- Claude Code (`claude`) installed and configured

## Installation

```bash
git clone https://github.com/your-username/claude-statusline
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
