#!/bin/bash
# statusline.sh - Resilient and Maximized Telemetry Statusline for Claude Code
# Built with premium 256-color powerline theme & instant system diagnostics

set -euo pipefail

# ─── ANSI Helpers (Standard colors) ───────────────────────────────────────────
R="\033[0m"         # Reset
B="\033[1m"         # Bold
D="\033[2m"         # Dim
I="\033[3m"         # Italic

# Foreground standard colors for classic fallback
FG_BLACK="\033[30m"
FG_RED="\033[31m"
FG_GREEN="\033[32m"
FG_YELLOW="\033[33m"
FG_BLUE="\033[34m"
FG_MAGENTA="\033[35m"
FG_CYAN="\033[36m"
FG_WHITE="\033[37m"

FG_GRAY="\033[90m"
FG_BRIGHT_RED="\033[91m"
FG_BRIGHT_GREEN="\033[92m"
FG_BRIGHT_YELLOW="${FG_YELLOW}"
FG_BRIGHT_BLUE="\033[94m"
FG_BRIGHT_MAGENTA="\033[95m"
FG_BRIGHT_CYAN="\033[96m"
FG_BRIGHT_WHITE="\033[97m"

NUM_COLOR="${FG_BRIGHT_WHITE}${B}"

# ─── Parse CLI Arguments first (prevents blocking on stdin for legend) ────────
USE_CLASSIC_ICONS=false
for arg in "$@"; do
  if [ "$arg" = "--classic" ] || [ "$arg" = "--no-nerdfont" ] || [ "$arg" = "--compatibility" ]; then
    USE_CLASSIC_ICONS=true
  fi
  if [ "$arg" = "--legend" ] || [ "$arg" = "-l" ] || [ "$arg" = "legend" ]; then
    echo -e "${FG_BRIGHT_GREEN}${B}🚀 Claude Code Maximized Statusline Legend${R}"
    echo -e "This statusline adapts dynamically to terminal width and displays high-density system & agent telemetry."
    echo -e ""
    echo -e "${B}LAYOUTS:${R}"
    echo -e "  - ${B}Wide Layout (>= 180 chars):${R} Single-row powerline segment dashboard."
    echo -e "  - ${B}Medium-Wide Layout (140-179 chars):${R} Double-line boxed telemetry block."
    echo -e "  - ${B}Medium Layout (100-139 chars):${R} Triple-line boxed telemetry block."
    echo -e "  - ${B}Small Layout (< 100 chars):${R} Quad-line stacked telemetry dashboard."
    echo -e ""
    echo -e "${B}COMPONENTS & ICONS:${R}"
    echo -e "  ${B}Field                Nerd Font   Classic     Description${R}"
    echo -e "  --------------------------------------------------------------------------------"
    echo -e "  State: READY                   ●           Agent is idle, ready for user requests."
    echo -e "  State: THINKING                ◆           Agent is processing/thinking."
    echo -e "  State: WORKING                 ⚙           Agent is executing background operations."
    echo -e "  State: TOOL                    🔧          Agent is running a tool."
    echo -e "  VCS Branch                     ╱           Current Git branch name (Red + * if dirty)."
    echo -e "  Model                          (None)      Current active LLM model name/ID."
    echo -e "  Sandbox Network                ON (net)    Sandbox enabled with internet access."
    echo -e "  Sandbox Restricted             ON (no-net) Sandbox enabled with network disabled."
    echo -e "  Sandbox Off                    sandbox off Sandbox is disabled (runs on host)."
    echo -e "  Context Bar                    ctx         Context window usage bar (10 or 20 segments)."
    echo -e "  Tokens Sum                     (None)      Total input/output tokens parsed."
    echo -e "  Sys resources                  sys         Host CPU load average & memory utilization."
    echo -e "  Artifacts                      artifacts   Number of active output artifacts."
    echo -e "  Subagents                      subagents   Number of spawned active subagents."
    echo -e "  Background Tasks               tasks       Number of background tasks running."
    echo -e "  Current Directory              ╱           Current working directory path (shortened)."
    echo -e "  Conversation ID                ╱           Short prefix of the current session ID."
    echo -e "  Power Mains (AC)               AC          Host is connected to external AC power."
    echo -e "  Power Battery (UPS)            BAT         Host is running on battery (shows charge %)."
    exit 0
  fi
done

# Read JSON from stdin or fallback to empty JSON if stdin is a terminal
if [ -t 0 ]; then
  INPUT_JSON="{}"
else
  INPUT_JSON=$(cat)
  echo "$INPUT_JSON" > "$HOME/.claude/stdin_debug.json" 2>/dev/null || true
fi

# ─── Parse JSON from stdin (Single jq pass for performance) ──────────────────
{
  read -r STATE
  read -r USED_PCT
  read -r VCS_BRANCH
  read -r VCS_DIRTY
  read -r VCS_TYPE
  read -r VCS_CLIENT
  read -r SANDBOX
  read -r SANDBOX_NET
  read -r ARTIFACTS
  read -r SUBAGENTS
  read -r BG_TASKS
  read -r MODEL_ID
  read -r MODEL_NAME
  read -r COLS
  read -r CWD
  read -r CONV_ID
  read -r PRODUCT
  read -r INPUT_TOKENS
  read -r OUTPUT_TOKENS
  read -r CTX_LIMIT
  read -r CTX_USED
  read -r REM_PCT
  read -r Q_5H
  read -r Q_WK
  read -r Q_5H_R
  read -r Q_WK_R
  read -r CLI_VERSION
  read -r PLAN_TIER
  read -r USER_EMAIL
  read -r TURN_INPUT_TOKENS
  read -r TURN_OUTPUT_TOKENS
} <<< "$(
  echo "$INPUT_JSON" | jq -r '
    (.agent_state // "idle"),
    (.context_window.used_percentage // 0),
    (.vcs.branch // ""),
    (.vcs.dirty // false),
    (.vcs.type // ""),
    (.vcs.client // ""),
    (.sandbox.enabled // false),
    (.sandbox.allow_network // false),
    (.artifact_count // 0),
    (if .subagents | type == "array" then (.subagents | length) else 0 end),
    (.task_count // 0),
    (.model.id // ""),
    (.model.display_name // ""),
    (.terminal_width // 80),
    (.cwd // ""),
    (.conversation_id // ""),
    (.product // ""),
    (.context_window.total_input_tokens // 0),
    (.context_window.total_output_tokens // 0),
    (.context_window.context_window_size // 0),
    ((.context_window.total_input_tokens // 0) + (.context_window.total_output_tokens // 0)),
    (.context_window.remaining_percentage // 100),
    (
      # Parse 5h rolling quota (used_percentage for Claude Code, remaining_fraction for Antigravity)
      if .rate_limits.five_hour.used_percentage != null then
        .rate_limits.five_hour.used_percentage
      elif (.quota["claude-5h"] // .quota["gemini-5h"] // .quota["3p-5h"] // .quota["5h"] | .remaining_fraction) != null then
        ((.quota["claude-5h"] // .quota["gemini-5h"] // .quota["3p-5h"] // .quota["5h"] | .remaining_fraction) * 1000 | round) / 10
      else
        -1
      end
    ),
    (
      # Parse weekly rolling quota
      if .rate_limits.seven_day.used_percentage != null then
        .rate_limits.seven_day.used_percentage
      elif (.quota["claude-weekly"] // .quota["gemini-weekly"] // .quota["3p-weekly"] // .quota["claude-7d"] // .quota["gemini-7d"] // .quota["weekly"] | .remaining_fraction) != null then
        ((.quota["claude-weekly"] // .quota["gemini-weekly"] // .quota["3p-weekly"] // .quota["claude-7d"] // .quota["gemini-7d"] // .quota["weekly"] | .remaining_fraction) * 1000 | round) / 10
      else
        -1
      end
    ),
    (
      # 5h quota resets_at / reset_in_seconds
      .rate_limits.five_hour.resets_at //
      .quota["claude-5h"].reset_in_seconds //
      .quota["gemini-5h"].reset_in_seconds //
      .quota["3p-5h"].reset_in_seconds //
      .quota["5h"].reset_in_seconds //
      -1
    ),
    (
      # Weekly quota resets_at / reset_in_seconds
      .rate_limits.seven_day.resets_at //
      .quota["claude-weekly"].reset_in_seconds //
      .quota["gemini-weekly"].reset_in_seconds //
      .quota["3p-weekly"].reset_in_seconds //
      .quota["claude-7d"].reset_in_seconds //
      .quota["gemini-7d"].reset_in_seconds //
      .quota["weekly"].reset_in_seconds //
      -1
    ),
    (.version // ""),
    (.plan_tier // ""),
    (.email // ""),
    (.context_window.current_usage.input_tokens // 0),
    (.context_window.current_usage.output_tokens // 0)
  ' 2>/dev/null || printf "idle\n0\n\nfalse\n\n\nfalse\nfalse\n0\n0\n0\n\n\n80\n\n\n\n0\n0\n0\n0\n100\n-1\n-1\n-1\n-1\n\n\n\n0\n0\n"
)"

# Set dynamic width boundaries
if [ "$COLS" -ge 180 ]; then
  BAR_LEN=20
  QUOTA_BAR_LEN=15
else
  BAR_LEN=10
  QUOTA_BAR_LEN=8
fi

# Define Theme Colors and Icons (Hourglass emoji removed)
if [ "$USE_CLASSIC_ICONS" = "true" ]; then
  DOT_L1="${FG_GRAY} ╱ ${R}"
  DOT_L2="${FG_GRAY} · ${R}"
  ICON_READY="●"
  ICON_THINKING="◆"
  ICON_WORKING="⚙"
  ICON_TOOL="🔧"
  ICON_STATE_UNKNOWN="⏳"
  ICON_VCS="╱"
  ICON_MODEL=""
  ICON_SANDBOX_NET="ON (net)"
  ICON_SANDBOX_NONET="ON (no-net)"
  ICON_SANDBOX_OFF="OFF"
  ICON_CONTEXT_BAR="ctx"
  ICON_ARTIFACTS="artifacts"
  ICON_SUBAGENTS="subagents"
  ICON_TASKS="tasks"
  ICON_DIR="╱"
  ICON_CONV="╱"
  ICON_TOK_SUM=""
  ICON_RESET=""
  ICON_AC="AC"
  ICON_BAT="BAT"
  ICON_SYS="sys"

  # Standard 16-color mappings for classic mode
  BG_READY="${FG_GREEN}"
  FG_READY_TEXT="${B}"
  BG_THINKING="${FG_YELLOW}"
  FG_THINKING_TEXT="${B}"
  BG_WORKING="${FG_CYAN}"
  FG_WORKING_TEXT="${B}"
  BG_TOOL="${FG_MAGENTA}"
  FG_TOOL_TEXT="${B}"
  BG_UNKNOWN="${FG_WHITE}"
  FG_UNKNOWN_TEXT="${B}"

  BG_GIT_CLEAN="${FG_BLUE}"
  FG_GIT_CLEAN_TEXT="${B}"
  BG_GIT_DIRTY="${FG_RED}"
  FG_GIT_DIRTY_TEXT="${B}"

  BG_MODEL="${FG_MAGENTA}"
  FG_MODEL_TEXT=""

  BG_DIR="${FG_CYAN}"
  FG_DIR_TEXT=""

  BG_META="${FG_GRAY}"
  FG_META_TEXT=""
  
  BAR_BG_COLOR=""
else
  DOT_L1="${FG_GRAY} | ${R}"
  DOT_L2="${FG_GRAY} | ${R}"
  ICON_READY=""
  ICON_THINKING=""
  ICON_WORKING=""
  ICON_TOOL=""
  ICON_STATE_UNKNOWN=""
  ICON_VCS=""
  ICON_MODEL=""
  ICON_SANDBOX_NET=""
  ICON_SANDBOX_NONET=""
  ICON_SANDBOX_OFF=""
  ICON_CONTEXT_BAR=""
  ICON_ARTIFACTS=""
  ICON_SUBAGENTS=""
  ICON_TASKS=""
  ICON_DIR=""
  ICON_CONV=""
  ICON_TOK_SUM=""
  ICON_RESET=""
  ICON_AC=""
  ICON_BAT=""
  ICON_SYS=""

  # Premium 256-color palette mappings
  BG_READY="\033[48;5;76m"
  FG_READY_TEXT="\033[38;5;232m\033[1m"
  
  BG_THINKING="\033[48;5;214m"
  FG_THINKING_TEXT="\033[38;5;232m\033[1m"
  
  BG_WORKING="\033[48;5;37m"
  FG_WORKING_TEXT="\033[38;5;232m\033[1m"
  
  BG_TOOL="\033[48;5;135m"
  FG_TOOL_TEXT="\033[38;5;255m\033[1m"
  
  BG_UNKNOWN="\033[48;5;244m"
  FG_UNKNOWN_TEXT="\033[38;5;255m\033[1m"
  
  BG_GIT_CLEAN="\033[48;5;33m"
  FG_GIT_CLEAN_TEXT="\033[38;5;255m\033[1m"
  
  BG_GIT_DIRTY="\033[48;5;197m"
  FG_GIT_DIRTY_TEXT="\033[38;5;255m\033[1m"
  
  BG_MODEL="\033[48;5;63m"
  FG_MODEL_TEXT="\033[38;5;255m\033[1m"
  
  BG_DIR="\033[48;5;38m"
  FG_DIR_TEXT="\033[38;5;232m\033[1m"
  
  # Soft slate grey matching the active palette (238)
  BG_META="\033[48;5;236m"
  FG_META_TEXT="\033[38;5;250m"
  
  BAR_BG_COLOR="238"
fi

# ─── Helper Functions ─────────────────────────────────────────────────────────

run_with_timeout() {
  if command -v timeout &>/dev/null; then
    timeout 1s "$@"
  else
    "$@"
  fi
}

human_format() {
  local num=$1
  if [ -z "$num" ] || [ "$num" -eq 0 ] 2>/dev/null; then
    echo "0"
    return
  fi
  if [ "$num" -ge 1000000 ] 2>/dev/null; then
    echo "$((num / 1000000)).$(((num % 1000000) / 100000))M"
  elif [ "$num" -ge 1000 ] 2>/dev/null; then
    echo "$((num / 1000)).$(((num % 1000) / 100))K"
  else
    echo "$num"
  fi
}

shorten_path() {
  local path=$1
  if [ -z "$path" ]; then
    echo ""
    return
  fi
  path="${path/#$HOME/\~}"
  if [ "${#path}" -gt 25 ]; then
    echo "...$(basename "$path")"
  else
    echo "$path"
  fi
}

visible_len() {
  printf '%s' "$(echo -e "$1" | sed 's/\x1b\[[0-9;]*m//g')" | wc -m
}

to_ansi_color() {
  local code="$1"
  case "$code" in
    75)  echo -n "${FG_BRIGHT_BLUE}" ;;
    37)  echo -n "${FG_BRIGHT_CYAN}" ;;
    135) echo -n "${FG_BRIGHT_MAGENTA}" ;;
    76)  echo -n "${FG_BRIGHT_GREEN}" ;;
    197) echo -n "${FG_BRIGHT_RED}" ;;
    214) echo -n "${FG_BRIGHT_YELLOW}" ;;
    244) echo -n "${FG_GRAY}" ;;
    *)   echo -n "" ;;
  esac
}

make_segment() {
  local bg_color="$1"
  local fg_text="$2"
  local text="$3"
  local next_bg="$4"
  
  if [ "$USE_CLASSIC_ICONS" = "true" ]; then
    echo -n "${bg_color}${text}${R} "
    return
  fi

  local current_bg_code="${bg_color}"
  local next_bg_code="${next_bg}"
  local fg_sep_code=$(echo -n "$current_bg_code" | sed 's/48;/38;/')
  
  if [ -n "$next_bg_code" ]; then
    echo -n "${current_bg_code}${fg_text} ${text} ${next_bg_code}${fg_sep_code}${R}"
  else
    echo -n "${current_bg_code}${fg_text} ${text} \033[0m${fg_sep_code}${R}"
  fi
}

# make_badge - transparent background for percentage stats (RAM)
make_badge() {
  local icon="$1"
  local val="$2"
  local icon_color="$3"
  
  if [ "$USE_CLASSIC_ICONS" = "true" ]; then
    local ansi_c=$(to_ansi_color "$icon_color")
    if [ -n "$icon" ]; then
      echo -n "${ansi_c}${icon} ${NUM_COLOR}${val}${R}"
    else
      echo -n "${NUM_COLOR}${val}${R}"
    fi
    return
  fi

  local ansi_color=$(to_ansi_color "$icon_color")
  if [ -z "$ansi_color" ] && [ -n "$icon_color" ]; then
    ansi_color="\033[38;5;${icon_color}m"
  fi

  if [ -n "$icon" ]; then
    echo -n "${ansi_color}${icon}${R} ${FG_BRIGHT_WHITE}${B}${val}${R}"
  else
    echo -n "${ansi_color}${B}${val}${R}"
  fi
}

format_reset_time() {
  local sec=$1
  if [ -z "$sec" ] || [ "$sec" -le 0 ]; then
    echo -n ""
    return
  fi

  local days=$((sec / 86400))
  local rem=$((sec % 86400))
  local hours=$((rem / 3600))
  rem=$((rem % 3600))
  local mins=$((rem / 60))

  if [ "$days" -gt 0 ]; then
    if [ "$hours" -gt 0 ]; then
      echo -n "${days}d ${hours}h"
    else
      echo -n "${days}d"
    fi
  elif [ "$hours" -gt 0 ]; then
    if [ "$mins" -gt 0 ]; then
      echo -n "${hours}h ${mins}m"
    else
      echo -n "${hours}h"
    fi
  elif [ "$mins" -gt 0 ]; then
    echo -n "${mins}m"
  else
    echo -n "<1m"
  fi
}

# make_quota_bar - only progress bar has the background, labels & percentages transparent (padding spaces removed)
make_quota_bar() {
  local val=$1
  local label=$2
  local bar_color_num=$3
  local reset_sec=$4
  local show_separator=${5:-true}
  
  local separator=""
  if [ "$show_separator" = "true" ]; then
    if [ "$USE_CLASSIC_ICONS" = "true" ]; then
      separator="${FG_GRAY} · ${R}"
    else
      separator="  "
    fi
  fi
  
  if [ -z "$val" ] || [[ "$val" == -* ]]; then
    local bar=""
    for ((i = 0; i < QUOTA_BAR_LEN; i++)); do
      if [ "$USE_CLASSIC_ICONS" = "true" ]; then
        bar="${bar}·"
      else
        bar="${bar}░"
      fi
    done
    echo -n "${separator}${FG_BRIGHT_WHITE}${B}${label}${R} ${FG_GRAY}${bar} N/A${R}"
    return
  fi

  local val_int=${val%.*}
  val_int=${val_int:-0}
  
  local text_color="76" # Default Green
  if [ "$IS_USED_PERCENTAGE" = "true" ]; then
    # Claude: low usage is good (green), high usage is bad (red)
    if [ "$val_int" -ge 90 ]; then
      text_color="197" # Red
    elif [ "$val_int" -ge 70 ]; then
      text_color="214" # Yellow
    else
      text_color="76" # Green
    fi
  else
    # Gemini: high remaining is good (green), low remaining is bad (red)
    if [ "$val_int" -lt 20 ]; then
      text_color="197" # Red
    elif [ "$val_int" -lt 50 ]; then
      text_color="214" # Yellow
    else
      text_color="76" # Green
    fi
  fi

  local filled=$((val_int * QUOTA_BAR_LEN / 100))
  local remainder=$(( (val_int * QUOTA_BAR_LEN) % 100 ))
  
  local bar=""
  for ((i = 0; i < QUOTA_BAR_LEN; i++)); do
    if [ "$i" -lt "$filled" ]; then
      if [ "$USE_CLASSIC_ICONS" = "true" ]; then
        bar="${bar}█"
      else
        bar="${bar}\033[38;5;${bar_color_num}m█\033[39m"
      fi
    elif [ "$i" -eq "$filled" ]; then
      if [ "$USE_CLASSIC_ICONS" = "true" ]; then
        if [ "$remainder" -ge 75 ]; then bar="${bar}▓"
        elif [ "$remainder" -ge 50 ]; then bar="${bar}▒"
        elif [ "$remainder" -ge 25 ]; then bar="${bar}░"
        else                               bar="${bar}·"
        fi
      else
        if [ "$remainder" -ge 75 ]; then
          bar="${bar}\033[38;5;${bar_color_num}m▓\033[39m"
        elif [ "$remainder" -ge 50 ]; then
          bar="${bar}\033[38;5;${bar_color_num}m▒\033[39m"
        elif [ "$remainder" -ge 25 ]; then
          bar="${bar}\033[38;5;${bar_color_num}m░\033[39m"
        else
          bar="${bar}\033[38;5;240m░\033[39m"
        fi
      fi
    else
      if [ "$USE_CLASSIC_ICONS" = "true" ]; then
        bar="${bar}·"
      else
        bar="${bar}\033[38;5;240m░\033[39m"
      fi
    fi
  done

  local reset_str=""
  if [ -n "$reset_sec" ] && [ "$reset_sec" -gt 0 ]; then
    reset_str=" ${FG_GRAY}$(format_reset_time "$reset_sec")${R}"
  fi

  if [ "$USE_CLASSIC_ICONS" = "true" ]; then
    local text_ansi=$(to_ansi_color "$bar_color_num")
    echo -n "${separator}${text_ansi}${B}${label}${R} ${text_ansi}${bar}${R} ${text_ansi}${val_int}%${R}${reset_str}"
  else
    local label_ansi=$(to_ansi_color "$bar_color_num")
    if [ -z "$label_ansi" ] && [ -n "$bar_color_num" ]; then
      label_ansi="\033[38;5;${bar_color_num}m"
    fi
    echo -n "${separator}${label_ansi}${B}${label}${R} \033[48;5;${BAR_BG_COLOR}m${bar}\033[0m ${label_ansi}${B}${val_int}%${R}${reset_str}"
  fi
}

get_seconds_remaining() {
  local val="$1"
  [ -z "$val" ] || [ "$val" = "none" ] || [ "$val" = "-1" ] && echo "-1" && return
  
  local epoch=""
  
  if [[ "$val" =~ ^[0-9]+$ ]]; then
    if [ "${#val}" -ge 12 ]; then
      val=$((val / 1000))
    fi
    if [ "$val" -lt 10000000 ]; then
      # Already remaining seconds
      echo "$val"
      return
    else
      # Absolute epoch seconds
      epoch="$val"
    fi
  else
    # ISO timestamp
    local clean_t
    clean_t=$(echo "$val" | sed -E 's/\.[0-9]+//; s/([+-][0-9]{2}):([0-9]{2})/\1\2/; s/Z$/+0000/')
    epoch=$(date -j -f "%Y-%m-%dT%H:%M:%S%z" "$clean_t" "+%s" 2>/dev/null || echo "")
  fi
  
  if [ -n "$epoch" ]; then
    local now
    now=$(date "+%s")
    local diff=$((epoch - now))
    if [ "$diff" -gt 0 ]; then
      echo "$diff"
    else
      echo "0"
    fi
  else
    echo "-1"
  fi
}

print_right_aligned() {
  local left="$1"
  local right="$2"
  local total_cols="$3"

  local left_vis right_vis pad
  left_vis=$(visible_len "$left")
  right_vis=$(visible_len "$right")

  pad=$(( total_cols - left_vis - right_vis ))
  [ "$pad" -lt 1 ] && pad=1

  printf "%b%*s%b\n" "$left" "$pad" "" "$right"
}

# ─── System Metrics Scanner ──────────────────────────────────────────────────

# VCS Info
GIT_DIR="${CWD:-.}"
local_branch=$(run_with_timeout git -C "$GIT_DIR" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
if [ -n "$local_branch" ]; then
  VCS_BRANCH="$local_branch"
  VCS_TYPE="git"
  if run_with_timeout git -C "$GIT_DIR" --no-optional-locks status --porcelain 2>/dev/null | grep -q .; then
    VCS_DIRTY="true"
  else
    VCS_DIRTY="false"
  fi
fi

# CPU Load & Memory Percentage
MEM_PCT=""
LOAD_1M=""
CPU_PCT=""
if [ -f /proc/meminfo ]; then
  mem_total=0
  mem_avail=0
  while read -r name value unit; do
    if [ "$name" = "MemTotal:" ]; then
      mem_total=$value
    elif [ "$name" = "MemAvailable:" ]; then
      mem_avail=$value
      break
    fi
  done < /proc/meminfo
  if [ "$mem_total" -gt 0 ]; then
    MEM_PCT=$(( (mem_total - mem_avail) * 100 / mem_total ))
  fi
elif command -v vm_stat &>/dev/null && command -v sysctl &>/dev/null; then
  mem_total_bytes=$(sysctl -n hw.memsize 2>/dev/null || echo "0")
  if [ "$mem_total_bytes" -gt 0 ]; then
    eval "$(vm_stat 2>/dev/null | awk -F':' '
      /page size/ {gsub(/[^0-9]/,"",$2); ps=$2}
      /Pages active/ {gsub(/[^0-9]/,"",$2); act=$2}
      /Pages speculative/ {gsub(/[^0-9]/,"",$2); spec=$2}
      /Pages wired down/ {gsub(/[^0-9]/,"",$2); wired=$2}
      /Pages occupied by compressor/ {gsub(/[^0-9]/,"",$2); comp=$2}
      END {
        if (!ps) ps=16384;
        used = (act + wired + comp) * ps;
        print "used_mem=" used "; page_size=" ps;
      }
    ')"
    if [ -n "${used_mem:-}" ] && [ "$mem_total_bytes" -gt 0 ]; then
      MEM_PCT=$(( used_mem * 100 / mem_total_bytes ))
    fi
  fi
fi

if [ -f /proc/loadavg ]; then
  read -r load_1m rest < /proc/loadavg
  LOAD_1M=$load_1m
elif command -v sysctl &>/dev/null; then
  load_out=$(sysctl -n vm.loadavg 2>/dev/null || echo "")
  if [[ "$load_out" =~ \{[[:space:]]*([0-9.]+)[[:space:]] ]]; then
    LOAD_1M="${BASH_REMATCH[1]}"
  fi
fi

if [ -f /proc/stat ]; then
  CPU_PCT=$(top -bn1 2>/dev/null | grep -i '^%Cpu' | awk '{print $2+$4}' | cut -d. -f1)
  if [ -z "$CPU_PCT" ]; then
    ncpu=$(nproc 2>/dev/null || grep -c ^processor /proc/cpuinfo 2>/dev/null || echo "1")
    if [ -n "$LOAD_1M" ]; then
      CPU_PCT=$(awk -v load="$LOAD_1M" -v ncpu="$ncpu" 'BEGIN {printf "%.0f\n", (load*100)/ncpu}')
    fi
  fi
elif command -v sysctl &>/dev/null; then
  ncpu=$(sysctl -n hw.ncpu 2>/dev/null || echo "1")
  CPU_PCT=$(ps -A -o %cpu 2>/dev/null | awk -v ncpu="$ncpu" '{s+=$1} END {printf "%.0f\n", s/ncpu}')
fi

if [ -n "$CPU_PCT" ]; then
  CPU_PCT=$(echo "$CPU_PCT" | tr -cd '0-9')
  if [ -n "$CPU_PCT" ]; then
    [ "$CPU_PCT" -gt 100 ] && CPU_PCT=100
  fi
fi

# Host Info & Tailscale
HOST_NAME=$(hostname 2>/dev/null || echo "")
TS_IP=$(ip -4 addr show dev tailscale0 2>/dev/null | grep -o 'inet [0-9.]*' | cut -d' ' -f2 || echo "")
HOST_INFO=""
if [ -n "$HOST_NAME" ]; then
  if [ -n "$TS_IP" ]; then
    HOST_INFO="${HOST_NAME} (${TS_IP})"
  else
    HOST_INFO="${HOST_NAME}"
  fi
fi

# Battery / Power Badge (Disabled)
POWER_FMT=""

# ─── Formatting Stats & Tokens ────────────────────────────────────────────────

PCT_FMT=$(LC_NUMERIC=C printf "%.0f" "$USED_PCT")
PCT_INT=${USED_PCT%.*}; PCT_INT=${PCT_INT:-0}

INPUT_TOK_FMT=$(human_format "$INPUT_TOKENS")
OUTPUT_TOK_FMT=$(human_format "$OUTPUT_TOKENS")
CTX_LIMIT_FMT=$(human_format "$CTX_LIMIT")
CTX_USED_FMT=$(human_format "$CTX_USED")
TURN_INPUT_FMT=$(human_format "$TURN_INPUT_TOKENS")
TURN_OUTPUT_FMT=$(human_format "$TURN_OUTPUT_TOKENS")
CWD_SHORT=$(shorten_path "$CWD")

# Context Bar Formatting
FILLED=$((PCT_INT * BAR_LEN / 100))
REMAINDER=$(( (PCT_INT * BAR_LEN) % 100 ))

if   [ "$PCT_INT" -ge 90 ]; then FILL_COLOR="$FG_BRIGHT_RED"
elif [ "$PCT_INT" -ge 60 ]; then FILL_COLOR="$FG_BRIGHT_YELLOW"
else                              FILL_COLOR="$FG_YELLOW"
fi

if [ "$USE_CLASSIC_ICONS" = "true" ]; then
  BAR=""
  for ((i = 0; i < BAR_LEN; i++)); do
    if   [ "$i" -lt "$FILLED" ]; then
      BAR="${BAR}█"
    elif [ "$i" -eq "$FILLED" ]; then
      if   [ "$REMAINDER" -ge 75 ]; then BAR="${BAR}▓"
      elif [ "$REMAINDER" -ge 50 ]; then BAR="${BAR}▒"
      elif [ "$REMAINDER" -ge 25 ]; then BAR="${BAR}░"
      else                               BAR="${BAR}·"
      fi
    else BAR="${BAR}·"
    fi
  done
  CTX_BAR="${FG_GRAY}ctx ${FILL_COLOR}${BAR} ${NUM_COLOR}${PCT_FMT}%${R}"
else
  if [ "$PCT_INT" -ge 90 ]; then bar_c="197"; else bar_c="214"; fi
  BAR=""
  for ((i = 0; i < BAR_LEN; i++)); do
    if   [ "$i" -lt "$FILLED" ]; then
      BAR="${BAR}\033[38;5;${bar_c}m█\033[39m"
    elif [ "$i" -eq "$FILLED" ]; then
      if   [ "$REMAINDER" -ge 75 ]; then
        BAR="${BAR}\033[38;5;${bar_c}m▓\033[39m"
      elif [ "$REMAINDER" -ge 50 ]; then
        BAR="${BAR}\033[38;5;${bar_c}m▒\033[39m"
      else
        BAR="${BAR}\033[38;5;${bar_c}m░\033[39m"
      fi
    else
      BAR="${BAR}\033[38;5;240m░\033[39m"
    fi
  done
  
  # Context bar formatting: ctx label and percentage transparent, only bar has BAR_BG_COLOR background (padding spaces removed)
  CTX_BAR="${FG_YELLOW}${B}ctx${R} \033[48;5;${BAR_BG_COLOR}m${BAR}\033[0m ${FG_YELLOW}${B}${PCT_FMT}%${R}"
fi

# Badges Formatting (CPU and RAM percentage transparent)
CPU_FMT=""
if [ -n "$CPU_PCT" ]; then
  if [ "$CPU_PCT" -ge 80 ] 2>/dev/null; then
    CPU_FMT="\033[38;5;197m${B}CPU:${CPU_PCT}%${R}"
  else
    CPU_FMT="${FG_BRIGHT_WHITE}${B}CPU:${CPU_PCT}%${R}"
  fi
fi

SYS_FMT=""
if [ -n "$MEM_PCT" ]; then
  if [ "$MEM_PCT" -ge 80 ] 2>/dev/null; then
    SYS_FMT="\033[38;5;197m${B}RAM:${MEM_PCT}%${R}"
  else
    SYS_FMT="${FG_BRIGHT_WHITE}${B}RAM:${MEM_PCT}%${R}"
  fi
fi

# Token Counters Details
TOK_DETAILS_WIDE=""
TOK_DETAILS_MED=""
if [ "$CTX_USED" -gt 0 ] 2>/dev/null; then
  turn_str=""
  if [ "$TURN_INPUT_TOKENS" -gt 0 ] || [ "$TURN_OUTPUT_TOKENS" -gt 0 ]; then
    turn_str=" | turn: +${TURN_INPUT_FMT}/${TURN_OUTPUT_FMT}"
  fi
  if [ "$USE_CLASSIC_ICONS" = "true" ]; then
    TOK_DETAILS_WIDE=" (${CTX_USED_FMT}/${CTX_LIMIT_FMT})${DOT_L2}(total: ${INPUT_TOK_FMT}/${OUTPUT_TOK_FMT}${turn_str})"
    TOK_DETAILS_MED=" (${CTX_USED_FMT}/${CTX_LIMIT_FMT})"
  else
    TOK_DETAILS_WIDE=" (${CTX_USED_FMT}/${CTX_LIMIT_FMT})${DOT_L2}${FG_YELLOW}${ICON_TOK_SUM} ${R} (total: ${INPUT_TOK_FMT}/${OUTPUT_TOK_FMT}${turn_str})"
    TOK_DETAILS_MED=" (${CTX_USED_FMT}/${CTX_LIMIT_FMT})"
  fi
fi

MODEL_DISP="${MODEL_NAME:-$MODEL_ID}"

# ─── Formatting First-Line as clean transparent text ───────────────────────
repo_text=""
if [ -n "$VCS_BRANCH" ]; then
  if [ "$USE_CLASSIC_ICONS" = "true" ]; then
    if [ "$VCS_DIRTY" = "true" ]; then
      repo_text="${VCS_BRANCH}*"
    else
      repo_text="${VCS_BRANCH}"
    fi
  else
    # Subtle green/red branch color inside clean white first line, no folder, no parentheses
    if [ "$VCS_DIRTY" = "true" ]; then
      repo_text="\033[38;5;197m${VCS_BRANCH}*\033[38;5;255m\033[1m"
    else
      repo_text="\033[38;5;76m${VCS_BRANCH}\033[38;5;255m\033[1m"
    fi
  fi
fi

# ─── Output Assembly ──────────────────────────────────────────────────────────
# Check if quotas are configured
HAS_QUOTAS=false
export IS_USED_PERCENTAGE=false

# 1. Check if quotas were passed via stdin (e.g. Antigravity or Claude Code rate_limits)
if { [ -n "$Q_5H" ] && [ "$Q_5H" != "-1" ] && [ "$Q_5H" != "" ]; } || { [ -n "$Q_WK" ] && [ "$Q_WK" != "-1" ] && [ "$Q_WK" != "" ]; }; then
  HAS_QUOTAS=true
  Q_5H_R=$(get_seconds_remaining "$Q_5H_R")
  Q_WK_R=$(get_seconds_remaining "$Q_WK_R")
  if echo "$INPUT_JSON" | jq -e '.rate_limits' &>/dev/null; then
    export IS_USED_PERCENTAGE=true
  fi
fi

# 2. Fall back to ccstatusline cache if stdin didn't provide them (e.g. Claude Code cache fallback)
if [ "$HAS_QUOTAS" = "false" ] && [ -f "$HOME/.cache/ccstatusline/usage.json" ]; then
  read -r S_USAGE S_RESET W_USAGE W_RESET <<< "$(jq -r '[.sessionUsage // -1, .sessionResetAt // "none", .weeklyUsage // -1, .weeklyResetAt // "none"] | @tsv' "$HOME/.cache/ccstatusline/usage.json" 2>/dev/null || echo "-1 none -1 none")"
  
  if [ "$S_USAGE" != "-1" ] && [ -n "$S_USAGE" ]; then
    Q_5H="$S_USAGE"
    Q_5H_R=$(get_seconds_remaining "$S_RESET")
    HAS_QUOTAS=true
    export IS_USED_PERCENTAGE=true
  fi
  if [ "$W_USAGE" != "-1" ] && [ -n "$W_USAGE" ]; then
    Q_WK="$W_USAGE"
    Q_WK_R=$(get_seconds_remaining "$W_RESET")
    HAS_QUOTAS=true
    export IS_USED_PERCENTAGE=true
  fi
fi

# Line prefixes definition
line_pref1=""
line_pref2=""
line_pref3=""

if [ "$USE_CLASSIC_ICONS" = "true" ]; then
  line_pref1=""
  line_pref2=""
  line_pref3=""
else
  line_pref1="${FG_GRAY}╭─${R}"
  if [ "$HAS_QUOTAS" = "true" ]; then
    line_pref2="${FG_GRAY}├─${R}"
  else
    line_pref2="${FG_GRAY}╰─${R}"
  fi
  line_pref3="${FG_GRAY}╰─${R}"
fi

# Line 1: Model (left), Git Branch, and RAM (all left-aligned, one after another)
LINE1_LEFT=""
if [ -n "$MODEL_DISP" ]; then
  LINE1_LEFT="${line_pref1}${FG_BRIGHT_WHITE}${B}${MODEL_DISP}${R}"
fi

if [ -n "$repo_text" ]; then
  if [ -n "$LINE1_LEFT" ]; then
    if [ "$USE_CLASSIC_ICONS" = "true" ]; then
      LINE1_LEFT="${LINE1_LEFT} · ${repo_text}"
    else
      LINE1_LEFT="${LINE1_LEFT}  ${repo_text}"
    fi
  else
    LINE1_LEFT="${line_pref1}${repo_text}"
  fi
fi

if [ -n "$CPU_FMT" ]; then
  if [ -n "$LINE1_LEFT" ]; then
    if [ "$USE_CLASSIC_ICONS" = "true" ]; then
      LINE1_LEFT="${LINE1_LEFT} · ${CPU_FMT}"
    else
      LINE1_LEFT="${LINE1_LEFT}  ${CPU_FMT}"
    fi
  else
    LINE1_LEFT="${line_pref1}${CPU_FMT}"
  fi
fi

if [ -n "$SYS_FMT" ]; then
  if [ -n "$LINE1_LEFT" ]; then
    if [ "$USE_CLASSIC_ICONS" = "true" ]; then
      LINE1_LEFT="${LINE1_LEFT} · ${SYS_FMT}"
    else
      LINE1_LEFT="${LINE1_LEFT}  ${SYS_FMT}"
    fi
  else
    LINE1_LEFT="${line_pref1}${SYS_FMT}"
  fi
fi

LINE1_RIGHT=""

# Line 2: Context Bar (left) and no right segment (RAM moved to line 1)
# Dynamically scale token details based on terminal width to prevent line wrapping
if [ "$COLS" -ge 150 ]; then
  LINE2_LEFT="${line_pref2}${CTX_BAR}${TOK_DETAILS_WIDE}"
elif [ "$COLS" -ge 110 ]; then
  LINE2_LEFT="${line_pref2}${CTX_BAR}${TOK_DETAILS_MED}"
else
  LINE2_LEFT="${line_pref2}${CTX_BAR}"
fi
line_pref2_right=""

# Line 3: 5H Quota (left) and 7D Quota (left, right next to it)
LINE3_LEFT=""
LINE3_RIGHT=""
if [ "$HAS_QUOTAS" = "true" ]; then
  LINE3_LEFT="${line_pref3}"
  if [ -n "$Q_5H" ] && [ "$Q_5H" != "-1" ] && [ "$Q_5H" != "" ]; then
    LINE3_LEFT="${LINE3_LEFT}$(make_quota_bar "$Q_5H" "5H" "37" "$Q_5H_R" false)"
  fi
  if [ -n "$Q_WK" ] && [ "$Q_WK" != "-1" ] && [ "$Q_WK" != "" ]; then
    LINE3_LEFT="${LINE3_LEFT}$(make_quota_bar "$Q_WK" "7D" "135" "$Q_WK_R" true)"
  fi
fi

# Print the lines right-aligned to terminal width
if [ -n "$LINE1_LEFT" ] || [ -n "$LINE1_RIGHT" ]; then
  print_right_aligned "$LINE1_LEFT" "$LINE1_RIGHT" "$COLS"
fi

if [ -n "$LINE2_LEFT" ] || [ -n "$line_pref2_right" ]; then
  print_right_aligned "$LINE2_LEFT" "$line_pref2_right" "$COLS"
fi

if [ "$HAS_QUOTAS" = "true" ] && [ -n "$LINE3_LEFT" ]; then
  print_right_aligned "$LINE3_LEFT" "$LINE3_RIGHT" "$COLS"
fi
