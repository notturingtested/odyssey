#! /usr/bin/env zsh
###################################################################
#Name          mac.sh
#Description   Installs all dependencies on new Mac
#Author        Braydn Tanner
###################################################################

set -e

install_brew_packages() {
  brew bundle --file ~/.odyssey/init/Brewfile
  # go to plugins custom and git clone https://github.com/lukechilds/zsh-nvm ~/.oh-my-zsh/custom/plugins/zsh-nvm
  # plugins+=(zsh-nvm)in .zshrc

  echo ""
  read "reply?Install work packages? (y/n) "
  if [[ "$reply" =~ ^[Yy]$ ]]; then
    brew bundle --file ~/.odyssey/init/Brewfile.work
  fi
}

setup_zsh() {
  bash ./zsh.sh
}

symlink() {
  echo 'SymLinking...'
  ln -sf ~/.odyssey/alacritty ~/.config/alacritty
  ln -sf ~/.odyssey/nvim ~/.config/nvim
  ln -sf ~/.odyssey/ssh ~/.ssh
  ln -sf ~/.odyssey/tmux/tmux.conf ~/.tmux.conf
  ln -sf ~/.odyssey/kitty ~/.config/kitty
  ln -sf ~/.odyssey/git/gitconfig ~/.gitconfig
  echo 'Complete!'
}

npmPackages() {
  npm install -g prettier
}

main() {
  install_brew_packages
  setup_zsh
  symlink
  npmPackages
}

main $@
