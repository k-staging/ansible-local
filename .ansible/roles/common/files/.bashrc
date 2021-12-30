############################
# ホームディレクトリに移動
############################
cd ${HOME}/src

############################
# history
############################
HISTSIZE=10000
HISTTIMEFORMAT='%y/%m/%d %H:%M:%S '

##################
# プロンプト設定
##################
[ -f ~/bin/.git-completion.bash ] && source ~/bin/.git-completion.bash
[ -f ~/bin/.git-prompt.sh ] && source ~/bin/.git-prompt.sh
export GIT_PS1_SHOWDIRTYSTATE=1
export GIT_PS1_SHOWUPSTREAM=1
export GIT_PS1_SHOWUNTRACKEDFILES=1
export GIT_PS1_SHOWSTASHSTATE=1
export PS1='\[\033[1;34m\]\u\[\033[00m\]:\[\033[1;33m\]\w\[\033[1;31m\]$(__git_ps1)\[\033[00m\] \$ '

###############
# ls
###############
alias ls='ls -G'
[ -e /etc/lsb-release ] && alias ls='ls --color=auto'
alias ll='ls -laF'

#####################
# goenv
#####################
export GOENV_ROOT="$HOME/.goenv"
[ -e ~/.goenv/bin/goenv ] && eval "$(goenv init -)"
export PATH="$GOROOT/bin:$PATH"
export PATH="$PATH:$GOPATH/bin"

#####################
# nvm
#####################
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

#####################
# pyenv
#####################
export PYENV_ROOT="$HOME/.pyenv"
export PYENV_VIRTUALENV_DISABLE_PROMPT=1
if [ -e ~/.pyenv ]; then
    eval "$(pyenv init --path)"
    eval "$(pyenv init -)"
    eval "$(pyenv virtualenv-init -)"
fi

#################
# rbenv
#################
[ -e ~/.rbenv/bin/rbenv ] && eval "$(rbenv init - bash)"

#################
# fzf
#################
[ -f ~/.fzf.bash ] && source ~/.fzf.bash

###################################
# MacOS 固有のエラー回避
# alias 登録してエラーを回避する
###################################
if [ -e /usr/bin/sw_vers ]; then
    if [ `sw_vers | grep -i "mac" | wc -l` = 1 ]; then
        alias bash='bash -O expand_aliases'
        alias sh='bash'
        alias zcat='gzcat'
        alias sed='gsed'
        export BASH_ENV='~/.bash_aliases'
    fi
fi

