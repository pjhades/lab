# Customized prompt
# add \T \d to show current time and date

PS1='\[\e[1;37m\]\u\[\e[0m\]@\[\e[1;36m\]\h \[\e[1;35m\]\W\[\e[0m\] \[\e[1;33m\]\$\[\e[0m\] '
#PS1='\[\e[1;32m\]\u\[\e[0m\] \[\e[1;35m\]\W\[\e[0m\]\[\e[1;33m\]\$\[\e[0m\] '
#PS1='\[\e[1;31m\]\u\[\e[0m\]@\[\e[1;35m\]\h \[\e[1;37m\]\W\[\e[0m\]\[\e[1;33m\]\$\[\e[0m\] '
PS2='\[\e[1;33m\]>\[\e[0m\] '

[ -z "$PS1" ] && return

# Aliases
alias ls='ls --color=auto'
alias ll='ls -l'
alias la='ls -a'
alias rm='rm -i'
alias mv='mv -i'
alias cp='cp -i'
alias vi='vim'

# Auto-completion
complete -cf sudo
complete -cf man
complete -cf pacman

[ -r /etc/bash_completion   ] && . /etc/bash_completion
[ -r ~/.git-completion.bash   ] && . ~/.git-completion.bash

# Set vi command line editing mode
set -o vi

# Exporting environment variables
#export CDPATH=":~/CS:~/Programming"
export GRE_HOME="/usr/lib/xulrunner-2.0/"

# fcitx
export GTK_IM_MODULE=xim
export QT_IM_MODULE=xim
export XMODIFIERS="@im=fcitx"
#export http_proxy="http://219.224.169.135:3128"

## color settings for less, man
export LESS_TERMCAP_mb=$'\E[01;32m'
export LESS_TERMCAP_md=$'\E[01;32m'
export LESS_TERMCAP_me=$'\E[0m'
export LESS_TERMCAP_se=$'\E[0m'
export LESS_TERMCAP_so=$'\E[01;44;33m'
export LESS_TERMCAP_ue=$'\E[0m'
export LESS_TERMCAP_us=$'\E[01;33m'

#export LESS_TERMCAP_mb=$'\E[01;31m'
#export LESS_TERMCAP_md=$'\E[01;31m'
#export LESS_TERMCAP_me=$'\E[0m'
#export LESS_TERMCAP_se=$'\E[0m'
#export LESS_TERMCAP_so=$'\E[01;44;37m'
#export LESS_TERMCAP_ue=$'\E[0m'
#export LESS_TERMCAP_us=$'\E[01;38m'
