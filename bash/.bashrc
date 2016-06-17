PS1_MAIN='\n\[\e[1;32m\]\u\[\e[0m\] \[\e[1;77m\]@\[\e[0m\] \[\e[1;35m\]\h\[\e[0m\]: \[\e[1;33m\]\W\[\e[0m\]'
PS1_ARROW='\[\e[1;77m\]→ \[\e[0m\]'

PS1="$PS1_MAIN $PS1_ARROW "
PS2='\[\e[1;31m\]>\[\e[0m\] '

show_git_branch() {
    if [ "$(git rev-parse --is-inside-work-tree 2>/dev/null)" == "true" ]; then
        export PS1="$PS1_MAIN \[\e[1;36m\]($(git branch | grep '*' | cut -d' ' -f2))\[\e[0m\] $PS1_ARROW "
    else
        export PS1="$PS1_MAIN $PS1_ARROW "
    fi
}

PROMPT_COMMAND='show_git_branch'

[ -z "$PS1" ] && return

alias ls='ls -G'
alias ll='ls -l'
alias la='ls -a'
alias rm='rm -i'
alias mv='mv -i'
alias cp='cp -i'
alias vi='vim'

set -o vi

export GOPATH='/Users/pjhades/code/go'
export GOBIN="$GOPATH/bin"
export PATH="$PATH:$GOPATH/bin"

export HISTCONTROL=ignoredups
export TERM=xterm-256color

# color settings for less, man
export LESS_TERMCAP_mb=$'\E[01;38;5;12m'
export LESS_TERMCAP_md=$'\E[01;38;5;80m' # section titles
export LESS_TERMCAP_me=$'\E[0m'
export LESS_TERMCAP_se=$'\E[0m'
export LESS_TERMCAP_so=$'\E[01;48;5;52m' # command line
export LESS_TERMCAP_ue=$'\E[0m'
export LESS_TERMCAP_us=$'\E[01;38;5;68m' # option argument

# fuck the fn key binding under tmux
if [ -n "$TMUX" ]; then
    export TERM="screen-256color"
fi
