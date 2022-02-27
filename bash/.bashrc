[ -f ~/.fzf.bash ] && source ~/.fzf.bash

PATH=$PATH:~/.npm-global:~/.cargo/bin

TERM=xterm

EDITOR=nvim

# emulatate pbcopy and paste on linux
# depends on xclip package
if [[ $(uname) == Linux ]]; then
  alias pbcopy='xclip -selection clipboard'
  alias pbpaste='xclip -selection clipboard -o'
fi

FZF_THEME="--color='bg+:-1,fg+:-1,fg:#AEACAA,fg+:#FFFBF6'"
export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --extended ${FZF_THEME}"
export FZF_DEFAULT_COMMAND="fd --type file --hidden --follow --exclude .git"
export FZF_CTRL_T_COMMAND="${FZF_DEFAULT_COMMAND}"
export FZF_ALT_C_COMMAND="fd --type directory --hidden"
# Jump Edge
je() {
  cd ~/dev/moixa/gridshare-edge
  cd $(fd . --type directory | fzf)
}

eval "$(direnv hook bash)"

# tabtab source for packages
# uninstall by removing these lines
[ -f ~/.config/tabtab/__tabtab.bash ] && . ~/.config/tabtab/__tabtab.bash || true

# tabtab source for packages
# uninstall by removing these lines
[ -f ~/.config/tabtab/bash/__tabtab.bash ] && . ~/.config/tabtab/bash/__tabtab.bash || true

eval "$(starship init bash)"
