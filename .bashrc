# Sample .bashrc for SUSE Linux
# Copyright (c) SUSE Software Solutions Germany GmbH

# There are 3 different types of shells in bash: the login shell, normal shell
# and interactive shell. Login shells read ~/.profile and interactive shells
# read ~/.bashrc; in our setup, /etc/profile sources ~/.bashrc - thus all
# settings made here will also take effect in a login shell.
#
# NOTE: It is recommended to make language settings in ~/.profile rather than
# here, since multilingual X sessions would not work properly if LANG is over-
# ridden in every subshell.

test -s ~/.alias && . ~/.alias || true

. /etc/profile.d/vte.sh 

export HISTTIMEFORMAT="%d.%m.%y %T "

alias protontricks='flatpak run com.github.Matoking.protontricks'

source /usr/share/bash-completion/completions/git-prompt.sh

export GIT_PS1_SHOWDIRTYSTATE=1
export GIT_PS1_SHOWSTASHSTATE=1
export GIT_PS1_SHOWUNTRACKEDFILES=1
export GIT_PS1_SHOWUPSTREAM=1
export GIT_PS1_STATESEPARATOR=' '
export GIT_PS1_SHOWCONFLICTSTATE=1
export GIT_PS1_SHOWCOLORHINTS=1

#PS1='\[\e]133;D;$?\e\\\e]133;A\e\\\]\n\[\033[1;30m\]\342\224\214\342\224\200\[\033[1;30m\][\[\033[0;37m\]\t\[\033[1;30m\]]\[\033[1;30m\]\342\224\200\[\033[1;30m\][\[\033[1;34m\]\u\[\033[1;30m\]@\[\033[1;32m\]\h\[\033[1;30m\]]\[\033[1;30m\]\342\224\200[\[\033[0;34m\]\w\[\033[1;30m\]]$(__git_ps1 " (%s)")\n\[\033[1;30m\]\342\224\224\342\224\200\342\224\200> \[\033[0m\]\[\e]133;B\e\\\]'

PS1='\[\e]133;D;$?\e\\\e]133;A\e\\\]\n\[\e[1;30m\]┌─[\[\e[0;37m\]\t\[\e[1;30m\]]─[\[\e[1;34m\]\u\[\e[1;30m\]@\[\e[1;32m\]\h\[\e[1;30m\]]─[\[\e[0;34m\]\w\[\e[1;30m\]]\[\e[0m\]$(__git_ps1 " [%s]")\n\[\e[1;30m\]└─> \[\e[0m\]\$ \[\e]133;B\e\\\]'

source /usr/share/fzf/shell/key-bindings.bash

PATH=~/Applications:~/.cargo/bin:$PATH

# opencode
export PATH=/home/hannemann/.opencode/bin:$PATH

for file in ~/.bash_helpers/*.sh; do
    [[ -r "$file" ]] && source "$file"
done

