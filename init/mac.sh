#! /usr/bin/env zsh
###################################################################
#Name          mac.sh
#Description   Installs all dependencies on new Mac
#Author        Braydn Tanner
###################################################################

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
MAGENTA='\033[0;35m'
NC='\033[0m'

step() { echo -e "\n${CYAN}>> $1${NC}"; }
ok() { echo -e "   ${GREEN}OK: $1${NC}"; }
warn() { echo -e "   ${YELLOW}WARN: $1${NC}"; }
fail() { echo -e "   ${RED}FAIL: $1${NC}"; exit 1; }

print_banner() {
  echo -e "${MAGENTA}"
  echo '  ████╗   ███████═╗ ██╗   ██╗ ███████╗ ███████╗  ███████╗ ██╗   ██╗'
  echo '██╔═══██╗ ██╔═══██║ ╚██╗ ██╔╝ ██╔════╝ ██╔════╝  ██╔════╝ ╚██╗ ██╔╝'
  echo '██║   ██║ ██║   ██║  ╚████╔╝  ███████╗ ███████╗  █████╗    ╚████╔╝'
  echo '██║   ██║ ██║   ██║   ╚██╔╝   ╚════██║ ╚════██║  ██╔══╝     ╚██╔╝'
  echo '╚═████╔═╝ ███████╔╝    ██║    ███████║ ███████║  ███████╗    ██║'
  echo '  ╚═══╝   ╚══════╝     ╚═╝    ╚══════╝ ╚══════╝  ╚══════╝    ╚═╝'
  echo '   ,(   ,(   ,(   ,(   ,(   ,(   ,(   ,(   ,(   ,(   ,(   ,(   ,('
  echo '`-'"'"'  `-'"'"'  `-'"'"'  `-'"'"'  `-'"'"'  `-'"'"'  `-'"'"'  `-'"'"'  `-'"'"'  `-'"'"'  `-'"'"'  `-'"'"'  `-'"'"'  `-'
  echo -e "${NC}"
}

install_brew_packages() {
  step "Installing Homebrew packages..."
  brew bundle --file ~/.odyssey/init/Brewfile
  ok "Homebrew packages installed"

  echo ""
  read "reply?Install work packages? (y/n) "
  if [[ "$reply" =~ ^[Yy]$ ]]; then
    step "Installing work packages..."
    brew bundle --file ~/.odyssey/init/Brewfile.work
    ok "Work packages installed"
  fi
  echo ""
  warn "Remember to install Bitwarden from the App Store!"
}

setup_zsh() {
  step "Setting up Zsh..."
  bash ./zsh.sh
  ok "Zsh configured"
}

symlink() {
  step "Creating symlinks..."
  ln -sf ~/.odyssey/alacritty ~/.config/alacritty
  ok "alacritty -> ~/.config/alacritty"
  ln -sf ~/.odyssey/nvim ~/.config/nvim
  ok "nvim -> ~/.config/nvim"
  ln -sf ~/.odyssey/ssh ~/.ssh
  ok "ssh -> ~/.ssh"
  ln -sf ~/.odyssey/tmux/tmux.conf ~/.tmux.conf
  ok "tmux.conf -> ~/.tmux.conf"
  ln -sf ~/.odyssey/kitty ~/.config/kitty
  ok "kitty -> ~/.config/kitty"
  ln -sf ~/.odyssey/git/gitconfig ~/.gitconfig
  ok "gitconfig -> ~/.gitconfig"
}

npmPackages() {
  step "Installing global npm packages..."
  npm install -g prettier
  ok "prettier installed"
}

main() {
  print_banner
  echo -e "${CYAN}===== Odyssey: Mac Setup =====${NC}"

  install_brew_packages
  setup_zsh
  symlink
  npmPackages

  echo ""
  echo -e "${GREEN}===== Setup Complete =====${NC}"
  echo ""
  echo -e "${YELLOW}NEXT STEPS:${NC}"
  echo -e "  1. Restart your terminal to load the new shell config"
  echo -e "  2. Open Neovim — plugins will auto-install on first launch"
  echo -e "  3. Install Bitwarden from the App Store for Touch ID support"
  echo ""
}

main $@
