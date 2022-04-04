# ~/.bashrc

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# Set primary prompt variable (bash prompt stuff)
PS1='\[\e[1;31m\]\u\[\e[m\]:\[\e[1;33m\]\w\[\e[m\]$ '

# Aliases
alias ls='ls --color=auto'
alias ll='ls -la'

