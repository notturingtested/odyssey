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

step() { echo -e "\n${CYAN}>> $1${NC}"; }
ok() { echo -e "   ${GREEN}OK: $1${NC}"; }
warn() { echo -e "   ${YELLOW}WARN: $1${NC}"; }

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
if ! grep -q 'odyssey_banner' ~/.zshrc 2>/dev/null; then
	cat >> ~/.zshrc << 'BANNER'

# Odyssey banner
odyssey_banner() {
  echo '\033[0;35m'
  echo '  ████╗   ███████═╗ ██╗   ██╗ ███████╗ ███████╗  ███████╗ ██╗   ██╗'
  echo '██╔═══██╗ ██╔═══██║ ╚██╗ ██╔╝ ██╔════╝ ██╔════╝  ██╔════╝ ╚██╗ ██╔╝'
  echo '██║   ██║ ██║   ██║  ╚████╔╝  ███████╗ ███████╗  █████╗    ╚████╔╝'
  echo '██║   ██║ ██║   ██║   ╚██╔╝   ╚════██║ ╚════██║  ██╔══╝     ╚██╔╝'
  echo '╚═████╔═╝ ███████╔╝    ██║    ███████║ ███████║  ███████╗    ██║'
  echo '  ╚═══╝   ╚══════╝     ╚═╝    ╚══════╝ ╚══════╝  ╚══════╝    ╚═╝'
  echo '   ,(   ,(   ,(   ,(   ,(   ,(   ,(   ,(   ,(   ,(   ,(   ,(   ,('
  echo '`-'\''  `-'\''  `-'\''  `-'\''  `-'\''  `-'\''  `-'\''  `-'\''  `-'\''  `-'\''  `-'\''  `-'\''  `-'\''  `-'
  echo '\033[0m'
}
odyssey_banner
BANNER
	ok "Odyssey banner added to .zshrc"
else
	ok "Odyssey banner already in .zshrc"
fi
