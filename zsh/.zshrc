# Benchmarking (see also https://github.com/romkatv/zsh-bench):
# zmodload zsh/zprof # put at top of .zshrc
# zprof # put at bottom of .zshrc
#

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# HomeBrew completions See here: https://docs.brew.sh/Shell-Completion
MNF_OS=$(uname -s)
if [[ $MNF_OS = "Darwin" ]]; then
  FPATH="$(brew --prefix)/share/zsh/site-functions:${FPATH}"
fi

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="powerlevel10k/powerlevel10k"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
ZSH_CUSTOM="$HOME/.oh-my-zsh-custom"

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
#export NVM_LAZY_LOAD=true # nvm is slow, see here: https://armno.in.th/blog/zsh-startup-time/
plugins=(git gpg-agent fzf-tab)


source $ZSH/oh-my-zsh.sh

# keybindings to be like bash
## ^U in bash is ^W on zsh, I want to stick with bash
bindkey \^U backward-kill-line

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8


# Set environment variables here
## Set system environment variables
export EDITOR=nvim
# Get the colors in the opened man page itself
if command -v bat &>/dev/null; then
    export MANPAGER="sh -c 'col -bx | bat -l man -p --paging=always'"
fi
## XDG Specs
### defines the base directory relative to which user-specific data files should be stored. If $XDG_DATA_HOME is either not set or empty, a default equal to $HOME/.local/share should be used.
#export XDG_DATA_HOME=$HOME/.local/share 
### $XDG_CONFIG_HOME defines the base directory relative to which user-specific configuration files should be stored. If $XDG_CONFIG_HOME is either not set or empty, a default equal to $HOME/.config should be used
#export XDG_CONFIG_HOME=$HOME/.config
### $XDG_STATE_HOME defines the base directory relative to which user-specific state files should be stored. If $XDG_STATE_HOME is either not set or empty, a default equal to $HOME/.local/state should be used.
### The $XDG_STATE_HOME contains state data that should persist between (application) restarts, but that is not important or portable enough to the user that it should be stored in $XDG_DATA_HOME. It may contain:
### actions history (logs, history, recently used files, …)
### current state of the application that can be reused on a restart (view, layout, open files, undo history, …)
#export XDG_STATE_HOME=$HOME/.local/state

## Set personal environment variables
export MNF_NOTES_DIR=$HOME/notes
export MNF_BIN_DIR=$HOME/bin
export MNF_TEMPLATE_DIR=$HOME/dotfiles/templates #TODO: should be $HOME/.templates
export MNF_BIB_DIR=$HOME/.local/share/zotero/bib
export BIBINPUTS=$MNF_BIB_DIR


############# PATH ############
# NOTE: Only set path here!
export PATH=$PATH:$MNF_BIN_DIR
###############################

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes.
# aliases
alias vi=nvim
alias vim=nvim
alias n="nvim" # This one is aggressive!
alias e="nvim" # This one is aggressive!
alias c="clear"
alias lt="tree" #TODO: Choose
alias l1="tree -a -L 1"
alias l2="tree -a -L 2"
alias l3="tree -a -L 2"
alias t="tree -a" #TODO: Decide on this
alias tt="tree -a -L 1" #TODO: Decide on this
alias t1="tree -a -L 1"
alias t2="tree -a -L 2"
alias t3="tree -a -L 2"
alias daily="mnf-daily"
alias gist="mnf-gist"
# NOTE: See function git_ignore_local defined here by me
alias git-ignore-local="git_ignore_local"
alias shconf="nvim $HOME/.zshrc"
alias shellconf="nvim $HOME/.zshrc"
alias shellconfig="nvim $HOME/.zshrc"
alias nvimconf="cd $HOME/.config/nvim && nvim ./"
alias nvimconfig="cd $HOME/.config/nvim && nvim ./"
alias termconf="cd $HOME/.config/kitty && nvim kitty.conf"
alias termconfig="cd $HOME/.config/kitty && nvim kitty.conf"
alias conf="cd $HOME/dotfiles"
alias dotconf="cd $HOME/dotfiles && nvim ./"
alias dotconfig="cd $HOME/dotfiles && nvim ./"
alias uva="source .venv/bin/activate" #TODO: Do we need to make this smarter?
alias yazi="y" #TODO: Do we need to make this smarter?
# be more like bash
alias help='run-help'
# Experimental
alias kickstart-nvim='NVIM_APPNAME="kickstart-nvim" nvim'
alias cdbin="cd $HOME/bin"


git_ignore_local() {
  local git_dir
  git_dir="$(git rev-parse --git-dir)" || return -1
  if [[ ${#} -gt 0 ]]; then 
    echo ${@} | tee -a "${git_dir}/info/exclude"
  else 
    $EDITOR "${git_dir}/info/exclude"
  fi
}

function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	command yazi "$@" --cwd-file="$tmp"
	if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		builtin cd -- "$cwd"
	fi
	rm -f -- "$tmp"
}

lst() {
  #FIXME: `lst -a` does not work
  file=""
  rest=("")
  args=("$@")
  if [[ ${#} -gt 0 ]] then;
    file="${args[@]: -1:1}"
    rest="${args[@]:0:(($# -1))}"
    ls ${rest[@]} ${MNF_TEMPLATE_DIR}/${file}
  else
    ls ${MNF_TEMPLATE_DIR}
  fi
}

cpt() {
  args=("$@")
  num_args=$#
  if [[ num_args -lt 2 ]]; then
    echo "cpt needs at least two arguments"
    return 1
  fi
  capture_until=$((num_args - 2))
  first_n_minus_2=("")
  source_and_dest=("${args[@]:$capture_until:$num_args}")
  source_path="${source_and_dest[1]}"
  dest_path="${source_and_dest[2]}"
  if [[ $capture_until -gt 0 ]]; then
    first_n_minus_2=("${args[@]:0:$capture_until}")
    cp "${first_n_minus_2[@]}" "${MNF_TEMPLATE_DIR}/${source_path}" "${dest_path}"
  else 
    cp "${MNF_TEMPLATE_DIR}/${source_path}" "${dest_path}"
  fi
}


# NOTE: For bash only, but if I ever switch ...
# HISTTIMEFORMAT="%d/%m/%y %T "  # for e.g. “29/02/99 23:59:59”
# HISTTIMEFORMAT="%F %T "        # for e.g. “1999-02-29 23:59:59”
# INFO: You can use history -E in ZSH

# WARN: Issuing kill %1 will not kill the neovim process if its in the bg
_zsh_cli_fg() { fg; }
zle -N _zsh_cli_fg
bindkey '^Z' _zsh_cli_fg

# TODO: Detect kitty emulator using escape codes so this works over ssh
# See here https://github.com/kovidgoyal/kitty/issues/957#issuecomment-420318828
# `printf '\eP+q544e\e\\'`
if [[ -n $KITTY_WINDOW_ID ]]; then
  alias ssh="kitten ssh"
fi

# ** FZF Block **
# Use fd (https://github.com/sharkdp/fd) for listing path candidates.
# - The first argument to the function ($1) is the base path to start traversal
# - See the source code (completion.{bash,zsh}) for the details.
_fzf_compgen_path() {
  fd --hidden --follow  --full-path \
    --exclude "node_modules" \
    --exclude "target/debug" \
    --exclude "target/release" \
    --exclude "obj" \
    --exclude "build" \
    --exclude "*.o" \
    --exclude "*.obj" \
    --exclude "dist" \
    --exclude "__pycache__" \
    --exclude ".git" . "$1"
}

# Use fd to generate the list for directory completion
_fzf_compgen_dir() {
  fd --type d  --hidden --follow --full-path \
    --exclude ".git" \
    --exclude "node_modules" \
    --exclude "target/debug" \
    --exclude "target/release" \
    --exclude "obj" \
    --exclude "build" \
    --exclude "dist" \
    --exclude "__pycache__" \
    . "$1"
}
#export FZF_DEFAULT_COMMAND='fd --type f --strip-cwd-prefix --hidden --follow --exclude .git'
export FZF_DEFAULT_COMMAND="fd --hidden --full-path --follow --exclude .git --exclude 'node_modules'  --exclude 'target/debug' --exclude 'target/release' --exclude 'obj' --exclude 'build' --exclude 'dist' --exclude '__pycache__' . $HOME "
export FZF_ALT_C_COMMAND="fd --type d --hidden --full-path --follow --exclude .git --exclude .git --exclude 'node_modules'  --exclude 'target/debug' --exclude 'target/release' --exclude 'obj' --exclude 'build' --exclude 'dist' --exclude '__pycache__' . $HOME "
export FZF_ALT_C_OPTS="
  --walker-skip .git,node_modules,target,obj,build,dist
  --preview 'tree -C {}'"
export FZF_CTRL_T_COMMAND="command cat <(fd -t d) <(fd -t d . $HOME)"
export FZF_CTRL_T_OPTS="
  --walker-skip .git,node_modules,target,obj,build,dist
  --preview 'bat -n --color=always {}'
  --bind 'ctrl-/:change-preview-window(down|hidden|)'"
# CTRL-Y to copy the command into clipboard using pbcopy
export FZF_CTRL_R_OPTS="
  --bind 'ctrl-y:execute-silent(echo -n {2..} | pbcopy)+abort'
  --color header:italic
  --header 'Press CTRL-Y to copy command into clipboard'"
# Nice idea, pretty buggy
# fzf - https://github.com/junegunn/fzf
bindkey '\C-f' fzf-cd-widget

frg() {
  RG_PREFIX="rg --column --line-number --no-heading --color=always --smart-case "
  INITIAL_QUERY="${*:-}"
  fzf --ansi --disabled --query "$INITIAL_QUERY" \
      --bind "start:reload:$RG_PREFIX {q}" \
      --bind "change:reload:sleep 0.1; $RG_PREFIX {q} || true" \
      --bind "alt-enter:unbind(change,alt-enter)+change-prompt(2. fzf> )+enable-search+clear-query" \
      --color "hl:-1:underline,hl+:-1:underline:reverse" \
      --prompt '1. ripgrep> ' \
      --delimiter : \
      --preview 'bat --color=always {1} --highlight-line {2}' \
      --preview-window 'up,60%,border-bottom,+{2}+3/3,~3' \
      --bind 'enter:become(nvim {1} +{2})'

}
cdi() {

  local search_dirs
  if [[ $# -eq 0 ]]; then
    search_dirs=("$PWD" "$HOME")
  else
    search_dirs=("$@")  # Use all provided arguments as base directories
  fi
  # If no arguments are provided, use fzf to select a directory
    # Find directories and pipe to fzf, then cd into the selected one
    local dir
    dir=$(fd --type d \
    --hidden --follow \
    --exclude ".git" \
    --exclude "node_modules" \
    --exclude "target/debug" \
    --exclude "target/release" \
    --exclude "obj" \
    --exclude "build" \
    --exclude "dist" \
    --exclude "__pycache__" . "${search_dirs[@]}" \
    2>/dev/null | fzf --walker-skip .git,node_modules,target,obj,build,dist \
    --preview 'tree -C {}' \
    --bind 'ctrl-/:change-preview-window(down|hidden|)'
) && builtin cd "$dir"
}

# fkill - kill process
fkill() {
  local pid
  pid=$(ps -ef | sed 1d | fzf -m | awk '{print $2}')

  if [ "x$pid" != "x" ]
  then
    echo $pid | xargs kill -${1:-15}
  fi
}
fps() {
  local pid
  pid=$(ps -ef | sed 1d | fzf -m | awk '{print $2}')
  echo pid
}

fman() {
  man -k . | fzf -q "$1" --prompt='man> '  --preview $'echo {} | tr -d \'()\' | awk \'{printf "%s ", $2} {print $1}\' | xargs -r man | col -bx | bat -l man -p --color always' | tr -d '()' | awk '{printf "%s ", $2} {print $1}' | xargs -r man
}

# Custom cd function to integrate fzf
cd() {
  # If no arguments are provided, use fzf to select a directory
  if [[ $# -eq 0 ]]; then
    # Find directories and pipe to fzf, then cd into the selected one
    local dir
    dir=$(fd --type d \
    --hidden --follow \
    --exclude ".git" \
    --exclude "node_modules" \
    --exclude "target/debug" \
    --exclude "target/release" \
    --exclude "obj" \
    --exclude "build" \
    --exclude "dist" \
    --exclude "__pycache__" \
    2>/dev/null | fzf --walker-skip .git,node_modules,target,obj,build,dist \
    --preview 'tree -C {}' \
    --bind 'ctrl-/:change-preview-window(down|hidden|)'
) && builtin cd "$dir"
  else
    # Otherwise, pass arguments to the built-in cd
    builtin cd "$@"
  fi
}
if [[ $MNF_OS = "Darwin" ]]; then eval "$(fzf --zsh)"; fi


# direnv
eval "$(direnv hook zsh)"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
