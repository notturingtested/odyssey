#!/usr/bin/env zsh

# Odyssey banner with animated top border + bottom waves
# Both animate simultaneously.

# Duration in seconds (default 10, pass as argument: ./border.sh 5)
duration=${1:-10}
total_frames=$(( int(${duration} * 5.0 + 0.5) ))

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

# Pre-compute 5 wave frames
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

# Pre-compute 4 border frames (the ψ ∿∿∿ pattern shifts)
# Border unit: "ψ ∿∿∿ " = 6 chars (ψ, space, ∿, ∿, ∿, space)
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

# Clear screen and draw static parts
printf '\033[2J\033[H'

# Line 1: border (initial)
printf '%s%b\n' "$spacing" "${border_frames[1]}"
# Line 2: blank
printf '\n'
# Lines 3-8: logo
for (( li=1; li<=6; li++ )); do
  printf '%s%b%s%b\n' "$spacing" "${logo_colors[$li]}" "${logo_raw[$li]}" "$rst"
done

# Wave lines at rows 9 and 10
wave_row=9
printf '%s%b\n' "$spacing" "${crest_frames[1]}"
printf '%s%b\n' "$spacing" "${trough_frames[1]}"

# Animate both border and waves
for (( frame=0; frame<total_frames; frame++ )); do
  widx=$(( (frame % 5) + 1 ))
  bidx=$(( (frame % 6) + 1 ))

  # Border (row 1)
  printf "\033[1;1H"
  printf '%s%b' "$spacing" "${border_frames[$bidx]}"

  # Waves (rows 9-10)
  printf "\033[${wave_row};1H"
  printf '%s%b' "$spacing" "${crest_frames[$widx]}"
  printf "\033[$(( wave_row + 1 ));1H"
  printf '%s%b' "$spacing" "${trough_frames[$widx]}"

  sleep 0.2
done

# Move cursor below banner
printf "\033[$(( wave_row + 2 ));1H"
printf '%b' "$rst"
