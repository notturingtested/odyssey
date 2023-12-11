#! /usr/bin/env zsh
if [ -d ~/.oh-my-zsh ]; then
	echo "oh-my-zsh is installed"
else
	echo "oh-my-zsh is not installed. Installing..."
  sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  echo "oh-my-zsh is installed"
fi

cd ~/.oh-my-zsh/custom
echo "alias ls='exa -a'
alias cat='bat'
alias grep='rg'
alias find='fd'
alias ipw='ipconfig getifaddr en0'
alias ipe='ipconfig getifaddr en1'
" > aliases.zsh

ln -sf ~/.odyssey/alacritty ~/.config/alacritty
ln -sf ~/.odyssey/nvim ~/.config/nvim
ln -sf ~/.odyssey/ssh ~/.ssh
ln -sf ~/.odyssey/tmux/tmux.conf ~/.tmux.conf
ln -sf ~/.odyssey/kitty ~/.config/kitty
