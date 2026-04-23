#!/usr/bin/env zsh

# Odyssey banner with animated bottom waves

# Hide cursor and ensure cleanup on exit/interrupt
printf '\033[?25l'
trap 'printf "\033[?25h\033[0m"' EXIT INT TERM

# Colors
local t='\033[38;2;140;180;255m'
local v='\033[38;2;60;120;240m'
local c1='\033[38;2;100;170;255m'
local c2='\033[38;2;30;70;180m'
local m='\033[38;2;70;120;220m'
local rst='\033[0m'

# Wave character colors
local col_comma='\033[38;2;100;170;255m'   # c1
local col_paren='\033[38;2;140;180;255m'   # t
local col_tick='\033[38;2;70;120;220m'     # m
local col_dash='\033[38;2;30;70;180m'      # c2
local col_apos='\033[38;2;70;120;220m'     # m

# Border
local border=$(printf "${t}ψ ${v}∿∿∿ %.0s" $(seq 1 13))$(printf "${t}ψ")

# Logo lines (raw content for width measurement, with leading spaces as in spec)
local -a logo_raw
logo_raw=(
  '      ████╗   ███████═╗ ██╗   ██╗ ███████╗ ███████╗  ███████╗ ██╗   ██╗'
  '     ██╔═══██╗ ██╔═══██║ ╚██╗ ██╔╝ ██╔════╝ ██╔════╝  ██╔════╝ ╚██╗ ██╔╝'
  '     ██║   ██║ ██║   ██║  ╚████╔╝  ███████╗ ███████╗  █████╗    ╚████╔╝'
  '     ██║   ██║ ██║   ██║   ╚██╔╝   ╚════██║ ╚════██║  ██╔══╝     ╚██╔╝'
  '     ╚═████╔═╝ ███████╔╝    ██║    ███████║ ███████║  ███████╗    ██║'
  '       ╚═══╝   ╚══════╝     ╚═╝    ╚══════╝ ╚══════╝  ╚══════╝    ╚═╝'
)

local -a logo_colors
logo_colors=(
  '\033[38;2;80;140;255m'
  '\033[38;2;100;120;255m'
  '\033[38;2;120;100;250m'
  '\033[38;2;140;80;240m'
  '\033[38;2;160;60;225m'
  '\033[38;2;180;50;210m'
)

# Determine max visible width across all lines
# Strip ANSI from border for measurement
local border_plain
border_plain=$(printf '%s' "$border" | sed $'s/\033\\[[0-9;]*m//g')
local border_width=${#border_plain}

local max_width=$border_width

for line in "${logo_raw[@]}"; do
  local w=${#line}
  (( w > max_width )) && max_width=$w
done

# Wave unit is 5 chars, make wave line match max_width
local wave_visible=$max_width

# Terminal width for centering
local term_cols=$(tput cols)
local pad_n=$(( (term_cols - max_width) / 2 ))
(( pad_n < 0 )) && pad_n=0
local padding=""
(( pad_n > 0 )) && padding=$(printf "%${pad_n}s" "")

# Build oversized raw wave buffers (visible width + 5 extra chars for seamless wrap)
local buf_len=$(( wave_visible + 5 ))
local crest_unit=',(   '
local trough_unit='`-'"'"'  '

local crest_buf=""
local trough_buf=""
local i=0
while (( ${#crest_buf} < buf_len )); do
  crest_buf="${crest_buf}${crest_unit}"
  trough_buf="${trough_buf}${trough_unit}"
done

# Function: colorize a wave slice
# $1 = raw slice string, $2 = "crest" or "trough"
colorize_wave() {
  local raw="$1"
  local kind="$2"
  local result=""
  local ch
  local len=${#raw}
  for (( i=1; i<=len; i++ )); do
    ch="${raw[$i]}"
    if [[ "$kind" == "crest" ]]; then
      case "$ch" in
        ,) result+="${col_comma},${rst}" ;;
        '(') result+="${col_paren}(${rst}" ;;
        *) result+=" " ;;
      esac
    else
      case "$ch" in
        '`') result+="${col_tick}\`${rst}" ;;
        -) result+="${col_dash}-${rst}" ;;
        "'") result+="${col_apos}'${rst}" ;;
        *) result+=" " ;;
      esac
    fi
  done
  printf '%s' "$result"
}

# Clear screen and draw static parts
printf '\033[2J\033[H'

# Line 1: border
printf '%s%b%b\n' "$padding" "$border" "$rst"
# Line 2: blank
printf '\n'
# Lines 3-8: logo
for (( li=1; li<=6; li++ )); do
  printf '%s%b%s%b\n' "$padding" "${logo_colors[$li]}" "${logo_raw[$li]}" "$rst"
done

# Lines 9-10: wave lines (rows 9 and 10 from top of output = cursor rows 9 and 10)
# Initial wave at offset 0
local wave_row_1=9
local wave_row_2=10

local crest_slice="${crest_buf[1,$wave_visible]}"
local trough_slice="${trough_buf[1,$wave_visible]}"

printf '%s%s\n' "$padding" "$(colorize_wave "$crest_slice" crest)"
printf '%s%s\n' "$padding" "$(colorize_wave "$trough_slice" trough)"

# Animate: ~100 frames, sleep 0.05 each = ~5 seconds
local offset=0
local frame
for (( frame=0; frame<100; frame++ )); do
  offset=$(( (frame % 5) + 1 ))
  local start=$(( offset + 1 ))
  local end=$(( offset + wave_visible ))

  crest_slice="${crest_buf[$start,$end]}"
  trough_slice="${trough_buf[$start,$end]}"

  local colored_crest
  colored_crest="$(colorize_wave "$crest_slice" crest)"
  local colored_trough
  colored_trough="$(colorize_wave "$trough_slice" trough)"

  # Move cursor to wave rows and overwrite
  printf '\033[%d;1H%s%s' "$wave_row_1" "$padding" "$colored_crest"
  printf '\033[%d;1H%s%s' "$wave_row_2" "$padding" "$colored_trough"

  sleep 0.05
done

# Move cursor below the banner
printf '\033[%d;1H\n' "$(( wave_row_2 + 1 ))"
