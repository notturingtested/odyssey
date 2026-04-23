# Animated Odyssey Banners Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Create 3 standalone zsh scripts in `banners/` that preview different animated versions of the Odyssey startup banner.

**Architecture:** Pure ANSI escape codes + printf + sleep. Each script clears the screen, runs an animation loop (~5s at 20fps), then leaves the final static banner on screen. Waves animate by shifting a read window across an oversized buffer of the 2-line wave pattern. Cursor is hidden during animation and restored on exit/interrupt.

**Tech Stack:** zsh, printf, ANSI escape sequences, sleep

---

## Shared Constants (all 3 scripts reuse these)

```zsh
# Colors
local t='\033[38;2;140;180;255m'
local v='\033[38;2;60;120;240m'
local c1='\033[38;2;100;170;255m'
local c2='\033[38;2;30;70;180m'
local m='\033[38;2;70;120;220m'
local rst='\033[0m'

# ODYSSEY text lines (6 lines, each with its own gradient color)
local logo=(
  '      \033[38;2;80;140;255m  ████╗   ███████═╗ ██╗   ██╗ ███████╗ ███████╗  ███████╗ ██╗   ██╗'
  '      \033[38;2;100;120;255m██╔═══██╗ ██╔═══██║ ╚██╗ ██╔╝ ██╔════╝ ██╔════╝  ██╔════╝ ╚██╗ ██╔╝'
  '      \033[38;2;120;100;250m██║   ██║ ██║   ██║  ╚████╔╝  ███████╗ ███████╗  █████╗    ╚████╔╝'
  '      \033[38;2;140;80;240m██║   ██║ ██║   ██║   ╚██╔╝   ╚════██║ ╚════██║  ██╔══╝     ╚██╔╝'
  '      \033[38;2;160;60;225m╚═████╔═╝ ███████╔╝    ██║    ███████║ ███████║  ███████╗    ██║'
  '      \033[38;2;180;50;210m  ╚═══╝   ╚══════╝     ╚═╝    ╚══════╝ ╚══════╝  ╚══════╝    ╚═╝'
)

# Border
local border=$(printf "${t}ψ ${v}∿∿∿ %.0s" $(seq 1 13))$(printf "${t}ψ")
```

## Wave Animation Technique

The wave is a 2-line pattern with a 5-char repeating unit:
- Line 1 (crests): `,(   ` repeating — the `,` and `(` are the peaks
- Line 2 (troughs): `` `-'  `` repeating — the backtick, dash, quote form the valleys

To animate, build an oversized buffer (visible width + extra period for seamless wrap). Each frame, shift the read window start by 1 char position. Both lines shift in lockstep.

```
Frame 0:  ,(   ,(   ,(   ,(
          `-'  `-'  `-'  `-'
Frame 1:  (   ,(   ,(   ,(
          -'  `-'  `-'  `-'
Frame 2:    ,(   ,(   ,(   ,
          '  `-'  `-'  `-'  `
...etc wrapping around
```

The raw (uncolored) buffer approach:
- Build plain strings of `,(   ` and `` `-'  `` repeated ~20+ times
- Each frame: slice a window of visible_width chars starting at offset
- Apply colors char-by-char: `,` and `(` get c1/t colors, backtick and `'` get m color, `-` gets c2 color
- Print with cursor positioning to overwrite previous frame

---

### Task 1: Create `banners/waves.sh` — Bottom waves only

**Files:**
- Create: `banners/waves.sh`

**Step 1: Create the script with static banner + wave animation**

```zsh
#!/usr/bin/env zsh
# Odyssey Banner: Waves
# Bottom waves animate for ~5 seconds, everything else static.

set -e

main() {
  local cols=$(tput cols)

  # Colors
  local t='\033[38;2;140;180;255m'
  local v='\033[38;2;60;120;240m'
  local c1='\033[38;2;100;170;255m'
  local c2='\033[38;2;30;70;180m'
  local m='\033[38;2;70;120;220m'
  local rst='\033[0m'

  # Border
  local border=$(printf "${t}ψ ${v}∿∿∿ %.0s" $(seq 1 13))$(printf "${t}ψ")

  # Logo
  local logo=(
    '      \033[38;2;80;140;255m  ████╗   ███████═╗ ██╗   ██╗ ███████╗ ███████╗  ███████╗ ██╗   ██╗'
    '      \033[38;2;100;120;255m██╔═══██╗ ██╔═══██║ ╚██╗ ██╔╝ ██╔════╝ ██╔════╝  ██╔════╝ ╚██╗ ██╔╝'
    '      \033[38;2;120;100;250m██║   ██║ ██║   ██║  ╚████╔╝  ███████╗ ███████╗  █████╗    ╚████╔╝'
    '      \033[38;2;140;80;240m██║   ██║ ██║   ██║   ╚██╔╝   ╚════██║ ╚════██║  ██╔══╝     ╚██╔╝'
    '      \033[38;2;160;60;225m╚═████╔═╝ ███████╔╝    ██║    ███████║ ███████║  ███████╗    ██║'
    '      \033[38;2;180;50;210m  ╚═══╝   ╚══════╝     ╚═╝    ╚══════╝ ╚══════╝  ╚══════╝    ╚═╝'
  )

  # Measure widest line for centering
  local esc=$(printf '\033')
  local max_w=0
  for line in "$border" "${logo[@]}"; do
    local stripped=$(printf '%b' "$line" | sed "s/${esc}\[[0-9;]*m//g")
    local w=${#stripped}
    (( w > max_w )) && max_w=$w
  done

  local pad=$(( (cols - max_w) / 2 ))
  (( pad < 0 )) && pad=0
  local spacing=$(printf "%${pad}s" "")

  # Build raw wave buffers (oversized for scrolling)
  local raw_top="" raw_bot=""
  local visible_w=$max_w
  local repeats=$(( (visible_w / 5) + 6 ))
  for i in $(seq 1 $repeats); do
    raw_top+=",(\   "
    raw_bot+="\`-'  "
  done

  # Hide cursor, handle cleanup
  printf '\033[?25l'
  trap 'printf "\033[?25h\033[0m"' EXIT INT TERM

  clear

  # Print static parts
  printf '\n'
  printf '%s' "$spacing"; printf '%b\n' "$border"
  printf '\n'
  for line in "${logo[@]}"; do
    printf '%s' "$spacing"; printf '%b\n' "$line"
  done

  # Save wave line positions (logo is 6 lines, border=line2, blank=line3, logo=lines4-9, waves=lines10-11)
  # That's row 10 and 11 from top (1-indexed, after the initial \n)
  local wave_row=$(( 2 + 1 + 1 + ${#logo[@]} + 1 ))  # newline + border + blank + logo lines + 1

  # Animate waves for ~5 seconds (100 frames at 0.05s)
  local total_frames=100
  for frame in $(seq 0 $total_frames); do
    local offset=$(( frame % 5 ))

    # Build colored wave line 1 (crests)
    local w1="" w2=""
    local chunk1=${raw_top:$offset:$visible_w}
    local chunk2=${raw_bot:$offset:$visible_w}

    # Apply colors char by char for line 1
    local colored1="   "
    for (( j=0; j<${#chunk1}; j++ )); do
      local ch="${chunk1:$j:1}"
      case "$ch" in
        ,)  colored1+="${c1},";;
        '(') colored1+="${t}(";;
        *)   colored1+=" ";;
      esac
    done

    # Apply colors char by char for line 2
    local colored2=""
    for (( j=0; j<${#chunk2}; j++ )); do
      local ch="${chunk2:$j:1}"
      case "$ch" in
        '`') colored2+="${m}\`";;
        '-') colored2+="${c2}-";;
        "'") colored2+="${m}'";;
        *)   colored2+=" ";;
      esac
    done

    # Position cursor and draw
    printf "\033[${wave_row};1H"
    printf '%s%b%s\n' "$spacing" "$colored1" "$rst"
    printf '%s%b%s' "$spacing" "$colored2" "$rst"

    sleep 0.05
  done

  # Show cursor, final newlines
  printf '\033[?25h\n\n'
  printf '%s' "$rst"
}

main
```

**Step 2: Make it executable and test**

Run: `chmod +x banners/waves.sh && ./banners/waves.sh`
Expected: Static banner appears instantly, bottom waves ripple for ~5 seconds, then stop.

**Step 3: Commit**

```bash
git add banners/waves.sh
git commit -m "feat: add waves banner animation script"
```

---

### Task 2: Create `banners/border.sh` — Top border + bottom waves

**Files:**
- Create: `banners/border.sh`

**Step 1: Create the script**

Same as waves.sh but additionally animates the top `ψ ∿∿∿` border. The border animation shifts the `∿` characters similarly — build an oversized buffer of `∿` and slide a window, interspersing `ψ` at intervals.

Border animation technique:
- Raw buffer: `ψ ∿∿∿ ` repeated
- Each frame: shift by 1 char, redraw the border line
- Both border and waves animate simultaneously

**Step 2: Make it executable and test**

Run: `chmod +x banners/border.sh && ./banners/border.sh`
Expected: Top border and bottom waves both animate for ~5 seconds.

**Step 3: Commit**

```bash
git add banners/border.sh
git commit -m "feat: add border banner animation script"
```

---

### Task 3: Create `banners/cinematic.sh` — Full reveal

**Files:**
- Create: `banners/cinematic.sh`

**Step 1: Create the script**

Phased animation:
- Phase 1 (0-1.5s, ~30 frames): Border animates in from empty, `∿` characters appear progressively left to right
- Phase 2 (1.5-3.5s, ~40 frames): Logo lines reveal one at a time with a slight delay between each (~6 lines over 2s)
- Phase 3 (3.5-5.5s, ~40 frames): Bottom waves start flowing, border continues animating
- After phase 3: everything settles to static final state

Logo reveal technique: each line types in from left to right (reveal N chars per frame), or simply fades in line by line with ~0.3s between lines.

**Step 2: Make it executable and test**

Run: `chmod +x banners/cinematic.sh && ./banners/cinematic.sh`
Expected: Border builds in, logo reveals line by line, waves start flowing, then all settle.

**Step 3: Commit**

```bash
git add banners/cinematic.sh
git commit -m "feat: add cinematic banner animation script"
```

---

### Task 4: Final testing and cleanup

**Step 1: Test all 3 scripts in sequence**

Run:
```bash
./banners/waves.sh
./banners/border.sh
./banners/cinematic.sh
```
Expected: Each runs its animation and exits cleanly.

**Step 2: Test Ctrl+C handling**

Run each script and press Ctrl+C mid-animation.
Expected: Cursor reappears, colors reset, no terminal corruption.

**Step 3: Final commit**

```bash
git add -A banners/
git commit -m "feat: animated odyssey banner preview scripts"
```
