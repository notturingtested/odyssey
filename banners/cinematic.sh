#!/usr/bin/env zsh

# Odyssey banner: full cinematic reveal
# Phase 1: Border reveals left to right (~1.2s)
# Phase 2: Logo reveals line by line (~1.8s)
# Phase 3: Border + waves animate (remaining time)

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

# Build colored wave/border units
cu_crest="${c1},${rst}${t}(${rst}   "
cu_trough="${m}\`${rst}${c2}-${rst}${m}'${rst}  "
cu_border="${t}ψ${rst} ${v}∿∿∿${rst} "

reps=16
full_crest=""
full_trough=""
full_border=""
for (( i=0; i<reps; i++ )); do
  full_crest+="$cu_crest"
  full_trough+="$cu_trough"
  full_border+="$cu_border"
done

# Phase prefixes
typeset -a crest_prefix trough_prefix border_prefix
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
border_prefix=(
  ""
  " ${v}∿∿∿${rst} "
  "${v}∿∿∿${rst} "
  "${v}∿∿${rst} "
  "${v}∿${rst} "
  " "
)

# Max width
max_w=0
for line in "${logo_raw[@]}"; do
  w=${#line}
  (( w > max_w )) && max_w=$w
done
border_w=$(( 6 * 13 + 1 ))
(( border_w > max_w )) && max_w=$border_w

# Terminal centering
cols=$(tput cols)
pad=$(( (cols - max_w) / 2 ))
(( pad < 0 )) && pad=0
spacing=""
(( pad > 0 )) && spacing=$(printf "%${pad}s" "")

# Clear screen
printf '\033[2J\033[H'

# ── Phase 1: Border reveals left to right (~1.2s) ──
border_static=$(printf "${t}ψ ${v}∿∿∿ %.0s" $(seq 1 13))$(printf "${t}ψ")
esc=$(printf '\033')
border_chars=()
# Split border into individual visible characters for progressive reveal
border_stripped=$(printf '%b' "$border_static" | sed "s/${esc}\[[0-9;]*m//g")
border_total=${#border_stripped}

for (( step=1; step<=8; step++ )); do
  reveal=$(( (border_total * step) / 8 ))
  # Build partial border up to reveal chars
  partial=""
  shown=0
  for (( p=0; p < reveal; p++ )); do
    bidx=$(( p % 6 ))
    case $bidx in
      0) partial+="${t}ψ${rst}" ;;
      2|3|4) partial+="${v}∿${rst}" ;;
      *) partial+=" " ;;
    esac
  done
  printf "\033[1;1H"
  printf '%s%b' "$spacing" "$partial"
  sleep 0.15
done

# ── Phase 2: Logo reveals line by line (~1.8s) ──
printf "\033[2;1H\n"
for (( li=1; li<=6; li++ )); do
  row=$(( li + 2 ))
  printf "\033[${row};1H"
  printf '%s%b%s%b' "$spacing" "${logo_colors[$li]}" "${logo_raw[$li]}" "$rst"
  sleep 0.3
done

# ── Phase 3: Waves flow (remaining time) ──
wave_row=9

remaining=$(( duration - 3.0 ))
(( remaining < 1 )) && remaining=1
wave_frames=$(( int(remaining * 5.0 + 0.5) ))

# Draw initial waves
printf "\033[${wave_row};1H"
printf '%s%b\n' "$spacing" "${crest_prefix[1]}${full_crest}"
printf '%s%b\n' "$spacing" "${trough_prefix[1]}${full_trough}"

# Animate border + waves
for (( frame=0; frame<wave_frames; frame++ )); do
  widx=$(( (frame % 5) + 1 ))
  bidx=$(( (frame % 6) + 1 ))

  printf "\033[1;1H"
  printf '%s%b' "$spacing" "${border_prefix[$bidx]}${full_border}"

  printf "\033[${wave_row};1H"
  printf '%s%b' "$spacing" "${crest_prefix[$widx]}${full_crest}"
  printf "\033[$(( wave_row + 1 ));1H"
  printf '%s%b' "$spacing" "${trough_prefix[$widx]}${full_trough}"

  sleep 0.2
done

# Move cursor below banner
printf "\033[$(( wave_row + 2 ));1H"
printf '%b' "$rst"
