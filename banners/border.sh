#!/usr/bin/env zsh

# Odyssey banner with animated top border + bottom waves

# Duration in seconds (default 10, pass as argument: ./border.sh 5)
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

# Build colored wave units (no per-char loop — just repeat pre-colored units)
# Wave cycle across both lines:
#   pos%5: 0=trough`, 1=trough-, 2=trough', 3=crest,  4=crest(
# Each "phase" rotates which character falls at pos 0

# The 5 crest variants (what appears when you start at each offset):
#   offset 0: "   ,(   ,(   ,( ..."  → 3 spaces then colored ,( repeating
#   offset 1: "  ,(   ,(   ,( ..."   → 2 spaces then colored ,( repeating
#   etc.
# Build them by repeating a colored 5-char unit at each phase

# Colored unit pieces
cu_crest="${c1},${rst}${t}(${rst}   "    # 5 visible chars: , ( sp sp sp
cu_trough="${m}\`${rst}${c2}-${rst}${m}'${rst}  "  # 5 visible chars: ` - ' sp sp

# Number of repetitions needed
reps=16

# Pre-build full repeated strings
full_crest=""
full_trough=""
for (( i=0; i<reps; i++ )); do
  full_crest+="$cu_crest"
  full_trough+="$cu_trough"
done

# Border colored unit: "ψ ∿∿∿ " = 6 chars
cu_border="${t}ψ${rst} ${v}∿∿∿${rst} "
full_border=""
for (( i=0; i<reps; i++ )); do
  full_border+="$cu_border"
done

# For each phase offset, we need to prepend the right number of leading chars
# from the middle of a unit. Pre-build the 5 crest/trough phase prefixes
# and the 6 border phase prefixes.

# Crest prefixes (what comes before the repeating unit at each offset)
# The wave cycle: idx3=, idx4=( idx0,1,2=space
# At offset 0: starts at idx0 → spaces first: "   " then repeating unit
# At offset 1: starts at idx1 → "  " then unit shifted
# etc.
# Easier: for offset N, the prefix is chars N..4 of one unit
typeset -a crest_prefix trough_prefix border_prefix
crest_prefix=(
  "   "                                    # offset 0: 3 spaces (idx 0,1,2)
  "  "                                     # offset 1: 2 spaces (idx 1,2)
  " "                                      # offset 2: 1 space (idx 2)
  ""                                       # offset 3: starts at , (no prefix)
  "${t}(${rst}   "                         # offset 4: starts at ( then 3 spaces
)
trough_prefix=(
  ""                                       # offset 0: starts at ` (no prefix)
  "${c2}-${rst}${m}'${rst}  "              # offset 1: starts at - ' sp sp
  "${m}'${rst}  "                          # offset 2: starts at ' sp sp
  "  "                                     # offset 3: 2 spaces
  " "                                      # offset 4: 1 space
)
border_prefix=(
  ""                                       # offset 0: starts at ψ
  " ${v}∿∿∿${rst} "                       # offset 1: sp ∿∿∿ sp
  "${v}∿∿∿${rst} "                        # offset 2: ∿∿∿ sp
  "${v}∿∿${rst} "                         # offset 3: ∿∿ sp
  "${v}∿${rst} "                          # offset 4: ∿ sp
  " "                                      # offset 5: sp
)

# Measure max width
esc=$(printf '\033')
max_w=0
for line in "${logo_raw[@]}"; do
  w=${#line}
  (( w > max_w )) && max_w=$w
done
# Border is typically widest — "ψ ∿∿∿ " x 13 + "ψ" = 79 chars
border_w=$(( 6 * 13 + 1 ))
(( border_w > max_w )) && max_w=$border_w

# Terminal centering
cols=$(tput cols)
pad=$(( (cols - max_w) / 2 ))
(( pad < 0 )) && pad=0
spacing=""
(( pad > 0 )) && spacing=$(printf "%${pad}s" "")

# Clear screen and draw everything immediately
printf '\033[2J\033[H'

# Line 1: border
printf '%s%b%b\n' "$spacing" "${crest_prefix[1]}${full_border}" "$rst"
# Actually draw the real border first
printf '\033[1;1H'
printf '%s%b%b' "$spacing" "${border_prefix[1]}${full_border}" "$rst"

# Line 2: blank
printf '\n\n'
# Lines 3-8: logo
for (( li=1; li<=6; li++ )); do
  printf '%s%b%s%b\n' "$spacing" "${logo_colors[$li]}" "${logo_raw[$li]}" "$rst"
done

# Lines 9-10: waves
wave_row=9
printf '%s%b\n' "$spacing" "${crest_prefix[1]}${full_crest}"
printf '%s%b\n' "$spacing" "${trough_prefix[1]}${full_trough}"

# Animate
for (( frame=0; frame<total_frames; frame++ )); do
  widx=$(( (frame % 5) + 1 ))
  bidx=$(( (frame % 6) + 1 ))

  # Border (row 1)
  printf "\033[1;1H"
  printf '%s%b' "$spacing" "${border_prefix[$bidx]}${full_border}"

  # Waves
  printf "\033[${wave_row};1H"
  printf '%s%b' "$spacing" "${crest_prefix[$widx]}${full_crest}"
  printf "\033[$(( wave_row + 1 ));1H"
  printf '%s%b' "$spacing" "${trough_prefix[$widx]}${full_trough}"

  sleep 0.2
done

# Move cursor below banner
printf "\033[$(( wave_row + 2 ));1H"
printf '%b' "$rst"
