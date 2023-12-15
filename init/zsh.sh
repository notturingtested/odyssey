#! /usr/bin/env zsh
if [ -d ~/.oh-my-zsh ]; then
	echo "oh-my-zsh is installed"
else
	echo "oh-my-zsh is not installed. Installing..."
	sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
	echo "oh-my-zsh is installed"
fi

cd ~/.oh-my-zsh/custom
echo 'Adding Aliases...'
echo "alias ls='exa -a'
alias cat='bat'
alias grep='rg'
alias find='fd'
alias ipw='ipconfig getifaddr en0'
alias ipe='ipconfig getifaddr en1'
" > aliases.zsh

{
echo 'export NVM_DIR="$HOME/.nvm"'
echo '[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"  # This loads nvm'
echo '[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion'
} >> ~/.zshrc

echo 'eval "$(direnv hook zsh)"' >> ~/.zshrc

echo 'SymLinking...'
ln -sf ~/.odyssey/alacritty ~/.config/alacritty
ln -sf ~/.odyssey/nvim ~/.config/nvim
ln -sf ~/.odyssey/ssh ~/.ssh
ln -sf ~/.odyssey/tmux/tmux.conf ~/.tmux.conf
ln -sf ~/.odyssey/kitty ~/.config/kitty
echo 'Complete!'
