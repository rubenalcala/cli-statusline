#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
SETTINGS_FILE="$CLAUDE_DIR/settings.json"
STATUSLINE_DEST="$CLAUDE_DIR/statusline.sh"
STATUSLINE_SRC="$SCRIPT_DIR/statusline.sh"

blue='\033[38;2;0;153;255m'
green='\033[38;2;0;175;80m'
red='\033[38;2;255;85;85m'
yellow='\033[38;2;230;200;0m'
dim='\033[2m'
reset='\033[0m'

ok()   { echo -e "  ${green}✓${reset} $1"; }
warn() { echo -e "  ${yellow}!${reset} $1"; }
fail() { echo -e "  ${red}✗${reset} $1"; exit 1; }

echo
echo -e "  ${blue}claude-statusline installer${reset}"
echo -e "  ${dim}───────────────────────────${reset}"
echo

# ── Check deps ───────────────────────────────────────────
for dep in jq git; do
    command -v "$dep" >/dev/null 2>&1 || fail "Missing dependency: $dep  →  install it and retry"
done
ok "Dependencies found (jq, git)"

# ── Check/Create claude dir ──────────────────────────────
[ -d "$CLAUDE_DIR" ] || mkdir -p "$CLAUDE_DIR"
ok "Found/created Claude Code config folder at ${dim}$CLAUDE_DIR${reset}"

# ── Copy script ──────────────────────────────────────────
if [ -f "$STATUSLINE_DEST" ]; then
    cp "$STATUSLINE_DEST" "${STATUSLINE_DEST}.bak"
    warn "Backed up existing statusline to ${dim}statusline.sh.bak${reset}"
fi

cp "$STATUSLINE_SRC" "$STATUSLINE_DEST"
chmod +x "$STATUSLINE_DEST"
ok "Installed statusline to ${dim}$STATUSLINE_DEST${reset}"

# ── Update settings.json ─────────────────────────────────
if [ ! -f "$SETTINGS_FILE" ]; then
    echo '{}' > "$SETTINGS_FILE"
fi

STATUS_CMD='bash "$HOME/.claude/statusline.sh"'
CURRENT_CMD=$(jq -r '.statusLine.command // ""' "$SETTINGS_FILE" 2>/dev/null)

if [ "$CURRENT_CMD" = "$STATUS_CMD" ]; then
    ok "Settings already configured"
else
    tmp=$(mktemp)
    jq --arg cmd "$STATUS_CMD" \
        '.statusLine = {"type": "command", "command": $cmd, "enabled": true}' \
        "$SETTINGS_FILE" > "$tmp" && mv "$tmp" "$SETTINGS_FILE"
    ok "Updated ${dim}settings.json${reset} with statusLine config"
fi

echo
echo -e "  ${green}Done!${reset} Restart claude to see your status line."
echo
