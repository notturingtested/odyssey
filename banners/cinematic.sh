#!/usr/bin/env zsh

# Odyssey banner: full cinematic reveal
# Phase 1: Border animates in (~1.5s)
# Phase 2: Logo reveals line by line (~2s)
# Phase 3: Waves flow (~remaining time)

# Duration in seconds (default 10, pass as argument: ./cinematic.sh 5)
duration=${1:-10}

# Hide cursor and ensure cleanup on exit/interrupt
printf '\033[?25l'
trap 'printf "\033[?25h\033[0m"' EXIT INT TERM

# Colors
t='\033[38;2;140;180;255m'
v='\033[38;2;60;120;240m'
c1='\033[38;2;100;170;255m'
c2='\033[38;2;30;70;180m'
m='\033[38;2;70;120;220m'
rst='\033[0m'

# Logo
logo_raw=(
  '      ████╗   ███████═╗ ██╗   ██╗ ███████╗ ███████╗  ███████╗ ██╗   ██╗'
  '     ██╔═══██╗ ██╔═══██║ ╚██╗ ██╔╝ ██╔════╝ ██╔════╝  ██╔════╝ ╚██╗ ██╔╝'
  '     ██║   ██║ ██║   ██║  ╚████╔╝  ███████╗ ███████╗  █████╗    ╚████╔╝'
  '     ██║   ██║ ██║   ██║   ╚██╔╝   ╚════██║ ╚════██║  ██╔══╝     ╚██╔╝'
  '     ╚═████╔═╝ ███████╔╝    ██║    ███████║ ███████║  ███████╗    ██║'
  '       ╚═══╝   ╚══════╝     ╚═╝    ╚══════╝ ╚══════╝  ╚══════╝    ╚═╝'
)
logo_colors=(
  '\033[38;2;80;140;255m'
  '\033[38;2;100;120;255m'
  '\033[38;2;120;100;250m'
  '\033[38;2;140;80;240m'
  '\033[38;2;160;60;225m'
  '\033[38;2;180;50;210m'
)

# Measure widest line for centering
esc=$(printf '\033')
border_static=$(printf "${t}ψ ${v}∿∿∿ %.0s" $(seq 1 13))$(printf "${t}ψ")
border_plain=$(printf '%b' "$border_static" | sed "s/${esc}\[[0-9;]*m//g")
max_w=${#border_plain}
for line in "${logo_raw[@]}"; do
  w=${#line}
  (( w > max_w )) && max_w=$w
done

# Terminal centering
cols=$(tput cols)
pad=$(( (cols - max_w) / 2 ))
(( pad < 0 )) && pad=0
spacing=""
(( pad > 0 )) && spacing=$(printf "%${pad}s" "")

# Pre-compute wave frames
typeset -a crest_frames trough_frames

for offset in 0 1 2 3 4; do
  crest_line=""
  trough_line=""

  for (( pos=0; pos < max_w; pos++ )); do
    idx=$(( (pos + 5 - offset) % 5 ))

    case $idx in
      3) crest_line+="${c1},${rst}" ;;
      4) crest_line+="${t}(${rst}" ;;
      *) crest_line+=" " ;;
    esac

    case $idx in
      0) trough_line+="${m}\`${rst}" ;;
      1) trough_line+="${c2}-${rst}" ;;
      2) trough_line+="${m}'${rst}" ;;
      *) trough_line+=" " ;;
    esac
  done

  crest_frames+=("$crest_line")
  trough_frames+=("$trough_line")
done

# Pre-compute border frames
typeset -a border_frames

for offset in 0 1 2 3 4 5; do
  border_line=""
  for (( pos=0; pos < max_w; pos++ )); do
    bidx=$(( (pos + 6 - offset) % 6 ))
    case $bidx in
      0) border_line+="${t}ψ${rst}" ;;
      2|3|4) border_line+="${v}∿${rst}" ;;
      *) border_line+=" " ;;
    esac
  done
  border_frames+=("$border_line")
done

# Clear screen
printf '\033[2J\033[H'

# ── Phase 1: Border animates in (~1.5s) ──
# Reveal border progressively from left to right
border_full="${border_frames[1]}"
border_full_plain=$(printf '%b' "$border_full" | sed "s/${esc}\[[0-9;]*m//g")
border_len=${#border_full_plain}

# Build the border progressively over 8 frames
for (( step=1; step<=8; step++ )); do
  reveal_w=$(( (max_w * step) / 8 ))
  partial=""
  for (( pos=0; pos < max_w; pos++ )); do
    if (( pos < reveal_w )); then
      bidx=$(( pos % 6 ))
      case $bidx in
        0) partial+="${t}ψ${rst}" ;;
        2|3|4) partial+="${v}∿${rst}" ;;
        *) partial+=" " ;;
      esac
    else
      partial+=" "
    fi
  done
  printf "\033[1;1H"
  printf '%s%b' "$spacing" "$partial"
  sleep 0.15
done

# Blank line after border
printf '\n'

# ── Phase 2: Logo reveals line by line (~2s) ──
for (( li=1; li<=6; li++ )); do
  row=$(( li + 2 ))  # rows 3-8
  printf "\033[${row};1H"
  printf '%s%b%s%b' "$spacing" "${logo_colors[$li]}" "${logo_raw[$li]}" "$rst"
  sleep 0.3
done

# ── Phase 3: Waves flow (remaining time) ──
wave_row=9

# Calculate remaining frames
# Phase 1: ~1.2s, Phase 2: ~1.8s = ~3s elapsed
remaining=$(( duration - 3.0 ))
(( remaining < 1 )) && remaining=1
wave_frames=$(( int(remaining * 5.0 + 0.5) ))

# Draw initial wave
printf "\033[${wave_row};1H"
printf '%s%b' "$spacing" "${crest_frames[1]}"
printf "\033[$(( wave_row + 1 ));1H"
printf '%s%b' "$spacing" "${trough_frames[1]}"

# Animate border + waves together
for (( frame=0; frame<wave_frames; frame++ )); do
  widx=$(( (frame % 5) + 1 ))
  bidx=$(( (frame % 6) + 1 ))

  # Border
  printf "\033[1;1H"
  printf '%s%b' "$spacing" "${border_frames[$bidx]}"

  # Waves
  printf "\033[${wave_row};1H"
  printf '%s%b' "$spacing" "${crest_frames[$widx]}"
  printf "\033[$(( wave_row + 1 ));1H"
  printf '%s%b' "$spacing" "${trough_frames[$widx]}"

  sleep 0.2
done

# Move cursor below banner
printf "\033[$(( wave_row + 2 ));1H"
printf '%b' "$rst"
