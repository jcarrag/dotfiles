[ -f ~/.fzf.bash ] && source ~/.fzf.bash

PATH=$PATH:~/.npm-global:~/.cargo/bin

TERM=xterm

EDITOR=nvim

alias cls='printf "\033c"'

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
  local -r DIR=$(fd . --type directory --base-directory ~/dev/lunar/gridshare-edge | fzf)
  if [[ -n "$DIR" ]]; then
    cd ~/dev/lunar/gridshare-edge/"$DIR"
  fi
}

eval "$(direnv hook bash)"

# tabtab source for packages
# uninstall by removing these lines
[ -f ~/.config/tabtab/__tabtab.bash ] && . ~/.config/tabtab/__tabtab.bash || true

# tabtab source for packages
# uninstall by removing these lines
[ -f ~/.config/tabtab/bash/__tabtab.bash ] && . ~/.config/tabtab/bash/__tabtab.bash || true

eval "$(starship init bash)"

source "$(blesh-share)/ble.sh"

eval "$(atuin init bash --disable-up-arrow)"
