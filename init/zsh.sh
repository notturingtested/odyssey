#! /usr/bin/env zsh
###################################################################
#Name          zsh.sh
#Description   Configures Zsh, oh-my-zsh, aliases, and shell startup
#Author        Braydn Tanner
###################################################################

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

step() { printf "\n${CYAN}>> %s${NC}\n" "$1"; }
ok() { printf "   ${GREEN}OK: %s${NC}\n" "$1"; }
warn() { printf "   ${YELLOW}WARN: %s${NC}\n" "$1"; }

step "Checking oh-my-zsh..."
if [ -d ~/.oh-my-zsh ]; then
	ok "oh-my-zsh is installed"
else
	step "Installing oh-my-zsh..."
	sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
	ok "oh-my-zsh installed"
fi

step "Adding aliases..."
cd ~/.oh-my-zsh/custom
echo "alias ls='eza -a'
alias cat='bat'
alias grep='rg'
alias find='fd'
alias ipw='ipconfig getifaddr en0'
alias ipe='ipconfig getifaddr en1'
" >aliases.zsh
ok "Aliases written to aliases.zsh"

step "Configuring NVM..."
if ! grep -q 'export NVM_DIR' ~/.zshrc 2>/dev/null; then
	{
		echo 'export NVM_DIR="$HOME/.nvm"'
		echo '[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"  # This loads nvm'
		echo '[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion'
	} >>~/.zshrc
	ok "NVM configured"
else
	ok "NVM already configured"
fi

step "Configuring direnv..."
if ! grep -q 'direnv hook zsh' ~/.zshrc 2>/dev/null; then
	echo 'eval "$(direnv hook zsh)"' >>~/.zshrc
	ok "direnv hook added"
else
	ok "direnv hook already present"
fi

step "Adding Odyssey banner to shell startup..."
if grep -q 'odyssey_banner' ~/.zshrc 2>/dev/null; then
	sed -i '' '/^# Odyssey banner$/,/^odyssey_banner$/d' ~/.zshrc
	ok "Removed old Odyssey banner"
fi
cat >> ~/.zshrc << 'BANNER'

# Odyssey banner
odyssey_banner() {
  local cols=$(tput cols)

  # Helper: pads a string to center it (strips ANSI to measure visible width)
  center() {
    local stripped=$(echo -e "$1" | sed 's/\x1b\[[0-9;]*m//g')
    local len=${#stripped}
    local pad=$(( (cols - len) / 2 ))
    [ $pad -lt 0 ] && pad=0
    printf "%${pad}s" ""
    echo -e "$1"
  }

  echo ""
  local t='\033[38;2;140;180;255m'
  local v='\033[38;2;60;120;240m'
  local border=$(printf "${t}ψ ${v}∿∿∿ %.0s" $(seq 1 12))$(printf "${t}ψ")
  center "$border"
  echo ""

  center '   \033[38;2;80;140;255m  ████╗   ███████═╗ ██╗   ██╗ ███████╗ ███████╗  ███████╗ ██╗   ██╗'
  center '  \033[38;2;100;120;255m██╔═══██╗ ██╔═══██║ ╚██╗ ██╔╝ ██╔════╝ ██╔════╝  ██╔════╝ ╚██╗ ██╔╝'
  center ' \033[38;2;120;100;250m██║   ██║ ██║   ██║  ╚████╔╝  ███████╗ ███████╗  █████╗    ╚████╔╝'
  center ' \033[38;2;140;80;240m██║   ██║ ██║   ██║   ╚██╔╝   ╚════██║ ╚════██║  ██╔══╝     ╚██╔╝'
  center '\033[38;2;160;60;225m╚═████╔═╝ ███████╔╝    ██║    ███████║ ███████║  ███████╗    ██║'
  center '\033[38;2;180;50;210m  ╚═══╝   ╚══════╝     ╚═╝    ╚══════╝ ╚══════╝  ╚══════╝    ╚═╝'

  local c1='\033[38;2;100;170;255m'
  local c2='\033[38;2;30;70;180m'
  local m='\033[38;2;70;120;220m'
  local line1='' line2=''
  for i in $(seq 0 13); do
    if [ $i -lt 13 ]; then
      line1+="${c1},${t}(   "
      line2+="${m}\`${c2}-${m}'  "
    else
      line1+="${c1},${t}("
      line2+="${m}\`${c2}-${m}'  ${m}\`${c2}-${m}'"
    fi
  done
  center "$line1"
  center "$line2"
  echo -e '\033[0m'
}
odyssey_banner
BANNER
ok "Odyssey banner added to .zshrc"
