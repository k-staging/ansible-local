############################
# history
############################
HISTSIZE=10000
HISTTIMEFORMAT='%y/%m/%d %H:%M:%S '

##################
# プロンプト設定
##################
export GIT_PS1_SHOWDIRTYSTATE=1
export GIT_PS1_SHOWUPSTREAM=1
export GIT_PS1_SHOWUNTRACKEDFILES=1
export GIT_PS1_SHOWSTASHSTATE=1
if [ -f ~/bin/git-completion.bash ] && [ -f ~/bin/git-prompt.sh ]; then
    source ~/bin/git-completion.bash
    source ~/bin/git-prompt.sh
    export PS1='\[\033[1;34m\]\u\[\033[00m\]:\[\033[1;33m\]\W\[\033[1;31m\]$(__git_ps1)\[\033[00m\]\$ '
else
    export PS1='\[\033[1;34m\]\u\[\033[00m\]:\[\033[1;33m\]\W\[\033[00m\]\$ '
fi

###############
# ls
###############
alias ls='ls -G'
[ -e /etc/lsb-release ] && alias ls='ls --color=auto'
alias ll='ls -laF'

###############
# vim/nvim
###############
alias vim='nvim'

#####################
# goenv
#####################
export GOENV_ROOT="$HOME/.goenv"
[ -e ~/.goenv/bin/goenv ] && eval "$(goenv init -)"
export PATH="$GOROOT/bin:$PATH"
export PATH="$PATH:$GOPATH/bin"

#####################
# nodenv
#####################
[ -e ~/.nodenv/bin/nodenv ] && eval "$(nodenv init -)"

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
# llvm
#################
if [ "$(which brew)" != "" ]; then
  LLVM_PREFIX_PATH=$(brew --prefix llvm)
  [ -e "${LLVM_PREFIX_PATH}/bin" ] && export PATH="${LLVM_PREFIX_PATH}/bin:$PATH" && export LDFLAGS="-L${LLVM_PREFIX_PATH}/lib" && export CPPFLAGS="-I${LLVM_PREFIX_PATH}/include"
fi

#################
# openssl
#################
if [ "$(which brew)" != "" ]; then
  OPENSSL_PREFIX_PATH=$(brew --prefix openssl@3)
  [ -e "${OPENSSL_PREFIX_PATH}/bin" ] && export PATH="${OPENSSL_PREFIX_PATH}/bin:$PATH"
fi

#################
# imagemagick
#################
if [ "$(which brew)" != "" ]; then
  IMAGE_MAGIC_PREFIX_PATH=$(brew --prefix imagemagick@6)
  [ -e "${IMAGE_MAGIC_PREFIX_PATH}/lib/pkgconfig" ] && export PKG_CONFIG_PATH="${IMAGE_MAGIC_PREFIX_PATH}/lib/pkgconfig"
fi

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
