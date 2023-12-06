#! /usr/bin/env zsh
###################################################################
#Name          mac.sh
#Description   Installs all dependencies on new Mac
#Author        Braydn Tanner
###################################################################

set -e

install_brew_packages () {
  brew bundle --file ./Brewfile
  # go to plugins custom and git clone https://github.com/lukechilds/zsh-nvm ~/.oh-my-zsh/custom/plugins/zsh-nvm
  # plugins+=(zsh-nvm)in .zshrc
}

setup_zsh () {
  bash ./zsh.sh
}

symlink () {

}

main () {
  install_brew_packages
  setup_zsh
  symlink
}

main $@
