############################
# 文字コードにUTF-8を使用
############################
export LANG=ja_JP.UTF-8

##############################
# テキストエディタを nvim へ
##############################
export EDITOR=nvim

##################
# ZSH 警告文対応
##################
export BASH_SILENCE_DEPRECATION_WARNING=1

#############
# git
#############
export GIT_PAGER="LESSCHARSET=utf-8 less"

##############
# PATH 設定
##############
ADD_ENVIRONMENT_PATH=$(cat << EOS
/usr/local/opt/libpq/bin
~/.goenv/bin
~/.nodenv/bin
~/.nodenv/shims
~/.pyenv/bin
~/.rbenv/bin
~/bin
~/go/bin
EOS
)
for ADD_PATH in ${ADD_ENVIRONMENT_PATH};do
    export PATH="$ADD_PATH:$PATH"
done

####################
# homebrew
####################
BREW_PATH="/opt/homebrew/bin"
if [ -e ${BREW_PATH} ]; then
    export PATH="$BREW_PATH:$PATH"
fi
if [ "$(which brew)" != "" ]; then
    eval $(brew shellenv)
    export PATH="$(brew --prefix)/opt/mysql-client@5.7/bin:$PATH"
fi

####################
# tmux
####################
alias tmux="TERM=xterm-256color tmux"
if [ $SHLVL = 1 ]; then
  tmux a -t default
fi

####################
# bash_completion
####################
[[ -r "/usr/local/etc/profile.d/bash_completion.sh" ]] && . "/usr/local/etc/profile.d/bash_completion.sh"

##################
# .bashrc 読込
##################
if [ -f ~/.bashrc ] ; then
. ~/.bashrc
fi

