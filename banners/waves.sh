#!/usr/bin/env zsh

# Odyssey banner with animated bottom waves

# Duration in seconds (default 10, pass as argument: ./waves.sh 5)
duration=${1:-10}
total_frames=$(( int(${duration} * 5.0 + 0.5) ))
(( total_frames < 1 )) && total_frames=1

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

# Border
border=$(printf "${t}ψ ${v}∿∿∿ %.0s" $(seq 1 13))$(printf "${t}ψ")

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

# Build colored wave units (repeat pre-colored strings, no per-char loop)
cu_crest="${c1},${rst}${t}(${rst}   "
cu_trough="${m}\`${rst}${c2}-${rst}${m}'${rst}  "

reps=16
full_crest=""
full_trough=""
for (( i=0; i<reps; i++ )); do
  full_crest+="$cu_crest"
  full_trough+="$cu_trough"
done

# Phase prefixes for each offset
typeset -a crest_prefix trough_prefix
crest_prefix=(
  "   "
  "  "
  " "
  ""
  "${t}(${rst}   "
)
trough_prefix=(
  ""
  "${c2}-${rst}${m}'${rst}  "
  "${m}'${rst}  "
  "  "
  " "
)

# Measure max width
max_w=0
for line in "${logo_raw[@]}"; do
  w=${#line}
  (( w > max_w )) && max_w=$w
done
esc=$(printf '\033')
border_plain=$(printf '%b' "$border" | sed "s/${esc}\[[0-9;]*m//g")
w=${#border_plain}
(( w > max_w )) && max_w=$w

# Terminal centering
cols=$(tput cols)
pad=$(( (cols - max_w) / 2 ))
(( pad < 0 )) && pad=0
spacing=""
(( pad > 0 )) && spacing=$(printf "%${pad}s" "")

# Clear screen and draw static parts
printf '\033[2J\033[H'

printf '%s%b%b\n' "$spacing" "$border" "$rst"
printf '\n'
for (( li=1; li<=6; li++ )); do
  printf '%s%b%s%b\n' "$spacing" "${logo_colors[$li]}" "${logo_raw[$li]}" "$rst"
done

# Wave lines at rows 9 and 10
wave_row=9
printf '%s%b\n' "$spacing" "${crest_prefix[1]}${full_crest}"
printf '%s%b\n' "$spacing" "${trough_prefix[1]}${full_trough}"

# Animate
for (( frame=0; frame<total_frames; frame++ )); do
  idx=$(( (frame % 5) + 1 ))

  printf "\033[${wave_row};1H"
  printf '%s%b' "$spacing" "${crest_prefix[$idx]}${full_crest}"
  printf "\033[$(( wave_row + 1 ));1H"
  printf '%s%b' "$spacing" "${trough_prefix[$idx]}${full_trough}"

  sleep 0.2
done

# Move cursor below banner
printf "\033[$(( wave_row + 2 ));1H"
printf '%b' "$rst"
