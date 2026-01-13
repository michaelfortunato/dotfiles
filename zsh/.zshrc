# Benchmarking (see also https://github.com/romkatv/zsh-bench):
# zmodload zsh/zprof # put at top of .zshrc
# zprof # put at bottom of .zshrc
#

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
(( ${+commands[direnv]} )) && emulate zsh -c "$(direnv export zsh)"
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi
(( ${+commands[direnv]} )) && emulate zsh -c "$(direnv hook zsh)"

MNF_OS=$(uname -s)

# HomeBrew completions See here: https://docs.brew.sh/Shell-Completion
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
plugins=(git gpg-agent fzf-tab)
source $ZSH/oh-my-zsh.sh

# setopt settings -- putting it here because oh-my-zsh.sh plugings may override them 
# otherwise 
# -----------------------------------------------------------------------------
# 1) Make globs and (most) completion include dotfiles by default
setopt GLOB_DOTS
# 2) Hide "." and ".." in completion menus
zstyle ':completion:*' special-dirs false
# 3) Sort by last accessed time
zstyle ':completion:*' file-sort modification
# Separate non‑dot and dot directories into different tags ??
# Generate two tags This does not work 
# zstyle ':completion:*:cd:*' file-patterns \
#   '*(/):directories' \
#   '.*(/):dot-dirs'
# # Hide dot entries from the first tag explicitly
# zstyle ':completion:*:cd:*:directories' ignored-patterns '.*'
# # Order: non-dot first, then dot
# zstyle ':completion:*:cd:*' tag-order dot-dirs
#
# I like this, it mimicks ctrl-y in blink.cmp
## NOTE: fzf-tab does not follow FZF_DEFAULT_OPTS by default
# This is necessarily because fzf-tab hijacks native tab completion in zsh
# Note I could have it use the default ops with zstyle ':fzf-tab:*' use-fzf-default-opts yes
# fzf-bindindgs need to be done all at once
zstyle ':fzf-tab:*' fzf-bindings 'ctrl-y:accept,ctrl-b:preview-page-up,ctrl-f:preview-page-down,ctrl-u:clear-query,ctrl-d:half-page-down' # note ctrl-d is not super useful
# fzf flags cannot handle more than one flag it seems, no matter if
# I use spaces commas or add them speratresly (gets overriden them)
zstyle ':fzf-tab:*' fzf-flags '--ansi' #could add --bind-ctrl-y:accept here but the quotest get me
# See https://github.com/Aloxaf/fzf-tab/wiki/Preview for info about $word etc.
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'tree -C $word'
zstyle ':fzf-tab:complete:ls:*' fzf-preview 'bat -n --color=always $word'

# keybindings to be like bash
## ^U in bash is ^W on zsh, I want to stick with bash
bindkey \^U backward-kill-line
## NOTE: This is needed to work in neovim's integrated terminal with zsh.
## I confirmed that cat -v is sending \x1b[1;3C in both terminals
## so I really think the problem is zsh, anyway this works
bindkey "^[[1;3C" forward-word      # ALT-RIGHT
bindkey "^[[1;3D" backward-word     # ALT-LEFT
bindkey "^[[1;3A" up-line-or-history    # ALT-UP
bindkey "^[[1;3B" down-line-or-history  # ALT-DOWN
bindkey '\C-h' backward-kill-word

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
    [[ $MNF_OS == "Darwin" ]] || export MANROFFOPT="-c"
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
export MNF_TEMPLATE_DIR=$HOME/dotfiles/_templates #TODO: should be $HOME/.templates via symlink
export MNF_BIB_DIR=$HOME/.local/share/zotero/bib
export BIBINPUTS=$MNF_BIB_DIR


#==============================================================================
# NOTE: Only set path here!
# 1. MNF_BIN_DIR is my directory for personal scripts
# 2. `$HOME/.local/bin` is the XDG's recommendation for personal scripts might oneday merge with MNF_BIN_DIR
# 3. `$HOME/.local/share/nvim/mason/bin` is the directory holding all lsps managed by mason.nvim--sometimes I like seeing their CLI features!
export PATH=$PATH:$MNF_BIN_DIR:$HOME/.local/bin:$HOME/.local/share/nvim/mason/bin
if [[ $MNF_OS != "Darwin" ]]; then
  export PATH=/usr/local/cuda-12.8/bin${PATH:+:${PATH}}
  export LD_LIBRARY_PATH="/usr/local/cuda-12.8/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}"
fi
#==============================================================================

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes.
# aliases
alias vi=nvim
alias vim=nvim
alias n="mnf daily" # This one is aggressive!
alias e="nvim" # This one is aggressive!
alias c="clear"
alias la='ls -lAht' #long list,show almost all,show type,human readable,sorted by date
alias l='ls -ht'  #human readable,sorted by date
alias lr='ls -ht'  #human readable,sorted by date
alias 'cd-'='cd -'
alias 'cd-1'='cd -1'
alias 'cd-2'='cd -2'
alias 'cd-3'='cd -3'
alias py="ipython" # better python shell
alias ipy="ipython" # better python shell
alias lg="lazygit" # lazygit
alias lt="tree -a" #TODO: Choose
alias l1="tree -a -L 1"
alias l2="tree -a -L 2"
alias l3="tree -a -L 2"
alias t="tree -a -L 1"
alias tt="tree -a"
alias t1="tree -a -L 1"
alias t2="tree -a -L 2"
alias t3="tree -a -L 2"
alias daily="mnf d"
alias gist="mnf gist"
#------------------------------------------------------------------------------
# NOTE: See function git_ignore_local defined here by me
alias git-ignore-local="git_ignore_local"
alias glo='git log --pretty=format:"%C(auto)%h %C(blue)%ad %C(auto)%d %Creset%s" --date=format:"%Y-%m-%d %H:%M"'
alias gcm='git commit -m'
#------------------------------------------------------------------------------
alias shconf="nvim $HOME/.zshrc"
alias shellconf="nvim $HOME/.zshrc"
alias shellconfig="nvim $HOME/.zshrc"
alias nvimconf="cd $HOME/.config/nvim && nvim"
alias nvimconfig="cd $HOME/.config/nvim && nvim"
alias termconf="cd $HOME/.config/ghostty && nvim config"
alias termconfig="cd $HOME/.config/ghostty && nvim config"
alias termconf-kitty="cd $HOME/.config/kitty && nvim kitty.conf"
alias termconfig-kitty="cd $HOME/.config/kitty && nvim kitty.conf"
alias conf="cd $HOME/dotfiles"
alias dotconf="cd $HOME/dotfiles && nvim"
alias dotconfig="cd $HOME/dotfiles && nvim"
alias uva="source .venv/bin/activate" #TODO: Do we need to make this smarter?
#TODO: Do we need to make this smarter?
alias yazi="y"
alias htop="btm" # You are crazy for this one!
alias icat="kitten icat" # to see images
# be more like bash
alias help='run-help'
# py-spy should be call pyspy imo
alias pyspy='py-spy'
# Experimental
alias kickstart-nvim='NVIM_APPNAME="kickstart-nvim" nvim'
#---unaliases-------------------------------------------------------------------
unalias gap


git-hooks() {
  if ! git rev-parse --git-dir &>/dev/null; then
    echo "git-hooks: not inside a git repository" >&2
    return 1
  fi

  local hook_dir template_dir
  hook_dir="$(git rev-parse --git-path hooks)" || return 1
  template_dir="$HOME/.config/git/git-templates/default/hooks"

  _git_hooks_add() {
    local name="$1"
    if [[ -z "$name" ]]; then
      echo "usage: git-hooks add <hook-name>" >&2
      return 1
    fi
    local hook_path template_path
    hook_path="$hook_dir/$name"
    template_path="$template_dir/$name"

    if [[ -f "$template_path" ]]; then
      cp "$template_path" "$hook_path"
    else
      printf '#!/bin/bash\n\n' >"$hook_path"
    fi
    chmod +x "$hook_path"
    echo "git-hooks: installed $name at $hook_path"
  }

  case "$1" in
    list|"")
      echo "Available templates (${template_dir}):"
      if [[ -d "$template_dir" ]]; then
        (cd "$template_dir" && ls)
      else
        echo "  <none>"
      fi
      echo
      echo "Active hooks ($(realpath "$hook_dir" 2>/dev/null)):"
      local active
      active=$(find "$hook_dir" -maxdepth 1 -type f ! -name '*.sample' -print)
      if [[ -n "$active" ]]; then
        sed 's/^/  /' <<<"$active"
      else
        echo "  <none>"
      fi
      ;;
    add)
      shift
      _git_hooks_add "$1"
      ;;
    edit)
      shift
      if [[ -z "$1" ]]; then
        echo "usage: git-hooks edit <hook-name>" >&2
        return 1
      fi
      if [[ ! -f "$hook_dir/$1" ]]; then
        _git_hooks_add "$1" || return 1
      fi
      "${EDITOR:-nvim}" "$hook_dir/$1"
      ;;
    *)
      echo "usage: git-hooks [list|add <hook>|edit <hook>]" >&2
      return 1
      ;;
  esac
}

git_ignore_local() {
  local git_dir
  git_dir="$(git rev-parse --git-dir)" || return -1
  mkdir -p "${git_dir}/info"  # in case it does not exist, I have seen that.
  if [[ ${#} -gt 0 ]]; then 
    echo ${@} | tee -a "${git_dir}/info/exclude"
  else 
    $EDITOR "${git_dir}/info/exclude"
  fi
}

function yazi() {
	# 1. Signal Neovim: Enter TUI Mode (Only if in NVIM)
	[[ -n "$NVIM" ]] && printf "\033_yazi:tui=1\033\\"
	command yazi "$@"
	local ret=$?
	# 2. Signal Neovim: Leave TUI Mode (Only if in NVIM)
	[[ -n "$NVIM" ]] && printf "\033_yazi:tui=0\033\\"
	return $ret
}

function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	# 1. Signal Neovim: Enter TUI Mode (Only if in NVIM)
  [[ -n "$NVIM" ]] && printf '\033_yazi:tui=1\033\\'
	command yazi "$@" --cwd-file="$tmp"
	# 2. Signal Neovim: Leave TUI Mode (Only if in NVIM)
  [[ -n "$NVIM" ]] && printf '\033_yazi:tui=0\033\\'
	if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		builtin cd -- "$cwd"
	fi
	rm -f -- "$tmp"
}

lazygit() {
  [[ -n "$NVIM" ]] && printf '\033_yazi:tui=1\033\\'
	command lazygit "$@"
  [[ -n "$NVIM" ]] && printf '\033_yazi:tui=0\033\\'
}

lst() {
  #FIXME: `lst -a` does not work
  (cd "$MNF_TEMPLATE_DIR" && ls "$@")
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
# Only applies to `**<Tab>` sequence `cd <Tab>` is entirely different.
_fzf_compgen_path() {
  bfs . "$1" -color -mindepth 1  \
     -exclude \( \
    -name ".git" \
    -or -name "node_modules" \
    -or -name "target/debug" \
    -or -name "target/release" \
    -or -name "obj" \
    -or -name "build" \
    -or -name "dist" \
    -or -name "__pycache__"  \) -type f \
    -unique
}

# Use bfs to generate the list for directory completion
_fzf_compgen_dir() {
  bfs . "$1" -color -mindepth 1  \
     -exclude \( \
    -name ".git" \
    -or -name "node_modules" \
    -or -name "target/debug" \
    -or -name "target/release" \
    -or -name "obj" \
    -or -name "build" \
    -or -name "dist" \
    -or -name "__pycache__"  \) -type d \
}
#export FZF_DEFAULT_COMMAND='fd --type f --strip-cwd-prefix --hidden --follow --exclude .git'
# NOTE: Improve this. Its not create rn vs. the amazing aliaes cdj cdi ei ...
export FZF_DEFAULT_COMMAND="bfs . $HOME -color -mindepth 1  -exclude \( -name '.git' -or -name 'node_modules' -or -name 'target/debug' -or -name 'target/release' -or -name 'obj' -or -name 'build' -or -name 'dist' -or -name '__pycache__'  \)"
# NOTE: Consider adding --ignore-case, though probably best per command
export FZF_DEFAULT_OPTS="--ansi --bind 'ctrl-y:accept' --bind 'ctrl-b:preview-page-up' --bind 'ctrl-f:preview-page-down' --bind 'ctrl-d:half-page-down' --bind 'ctrl-u:clear-query'"
export FZF_ALT_C_COMMAND="fd --type d --hidden --full-path --follow --exclude .git --exclude .git --exclude 'node_modules'  --exclude 'target/debug' --exclude 'target/release' --exclude 'obj' --exclude 'build' --exclude 'dist' --exclude '__pycache__' . $HOME "
export FZF_ALT_C_OPTS="
  --walker-skip .git,node_modules,target,obj,build,dist
  --ansi
  --bind=ctrl-y:accept
  --cycle
  --preview 'tree -C {}'"
export FZF_CTRL_T_COMMAND="command cat <(fd -t d) <(fd -t d . $HOME)"
export FZF_CTRL_T_OPTS="
  --walker-skip .git,node_modules,target,obj,build,dist
  --preview 'bat -n --color=always {}'
  --bind=ctrl-y:accept
  --cycle
  --bind 'ctrl-/:change-preview-window(down|hidden|)'"
# CTRL-Y to copy the command into clipboard using pbcopy
# --bind 'ctrl-y:execute-silent(echo -n {2..} | pbcopy)+abort'
export FZF_CTRL_R_OPTS="
  --color header:italic
  --bind=ctrl-y:accept
  --cycle
  --header 'Press CTRL-Y to copy command into clipboard'"
# Nice idea, pretty buggy
# fzf - https://github.com/junegunn/fzf
bindkey '\C-f' fzf-cd-widget

gri() {
  # NOTE: at start:reload place --hidden before q if you want it to be default
  # TODO: Toggle hidden ? --bind "ctrl-h:reload:sleep 0.1; $RG_PREFIX '--hidden' {q} || true" \
  RG_PREFIX="rg --column --line-number --no-heading --color=always --smart-case"
  INITIAL_QUERY="${1:-}"
  fzf --ansi --disabled --query "$INITIAL_QUERY" \
      --bind "start:reload:$RG_PREFIX {q}" \
      --bind "change:reload:sleep 0.1; $RG_PREFIX {q} || true" \
      --bind "alt-enter:unbind(change,alt-enter)+change-prompt(2. fzf> )+enable-search+clear-query" \
      --color "hl:-1:underline,hl+:-1:underline:reverse" \
      --cycle \
      --prompt '1. ripgrep> ' \
      --delimiter : \
      --preview 'bat --color=always {1} --highlight-line {2}' \
      --preview-window 'up,60%,border-bottom,+{2}+3/3,~3' \
      --bind 'enter:become($EDITOR {1} +{2})' \
      --bind 'ctrl-y:become($EDITOR {1} +{2})'
}

cdj() {
  local search_dirs
  if [[ $# -eq 0 ]]; then
    if [[ "$PWD" != "$HOME" ]]; then
      search_dirs=("$PWD" "$HOME")
    else
      search_dirs=("$HOME")
    fi
  else
    search_dirs=("$@")  # Use all provided arguments as base directories
  fi
  # If no arguments are provided, use fzf to select a directory
    # Find directories and pipe to fzf, then cd into the selected one
    local dir
    dir=$(bfs "${search_dirs[@]}" -color -mindepth 1  \
     -exclude \( \
    -name ".git" \
    -or -name "node_modules" \
    -or -name "target/debug" \
    -or -name "target/release" \
    -or -name "obj" \
    -or -name "build" \
    -or -name "dist" \
    -or -name ".cache" \
    -or -name ".Trash" \
    -or -name "$HOME/Library/Caches" \
    -or -name "__pycache__"  \) -type d \
    2>/dev/null | fzf --ignore-case --scheme=path --tiebreak='pathname,length,end' --ansi --walker-skip .git,node_modules,target,obj,build,dist \
    --preview 'tree -C {}' \
    --cycle \
    --bind 'ctrl-y:accept' \
    --bind 'ctrl-/:change-preview-window(down|hidden|)'
) && builtin cd "$dir"
}

cdi() {
  local search_dirs
  if [[ $# -eq 0 ]]; then
    if [[ "$PWD" != "$HOME" ]]; then
      search_dirs=("$PWD" "$HOME")
    else
      search_dirs=("$HOME")
    fi
  else
    search_dirs=("$@")  # Use all provided arguments as base directories
  fi
  # If no arguments are provided, use fzf to select a directory
    # Find directories and pipe to fzf, then cd into the selected one
    local file
    file=$(bfs "${search_dirs[@]}" -color -mindepth 1  \
     -exclude \( \
    -name ".git" \
    -or -name "node_modules" \
    -or -name "target/debug" \
    -or -name "target/release" \
    -or -name "obj" \
    -or -name "build" \
    -or -name "dist" \
    -or -name ".cache" \
    -or -name ".Trash" \
    -or -name "$HOME/Library/Caches" \
    -or -name "__pycache__"  \) -type f \
    2>/dev/null | fzf --ignore-case --scheme=path --tiebreak='pathname,length,end' --ansi --walker-skip .git,node_modules,target,obj,build,dist \
    --preview 'bat -n --color=always {}' \
    --cycle \
    --bind 'ctrl-y:accept' \
    --bind 'ctrl-/:change-preview-window(down|hidden|)'
) || return $?
  local dir=${file:h}
  builtin cd -- $dir
  $EDITOR "$file"
# not sure if I want that&& builtin cd "$dir"
}

# edit file
ei() {
  local search_dirs
  if [[ $# -eq 0 ]]; then
    if [[ "$PWD" != "$HOME" ]]; then
      search_dirs=("$PWD" "$HOME")
    else
      search_dirs=("$HOME")
    fi
  else
    search_dirs=("$@")  # Use all provided arguments as base directories
  fi
  bfs "${search_dirs[@]}" -color -mindepth 1  \
    -exclude \( \
  -name ".git" \
  -or -name "node_modules" \
  -or -name "target/debug" \
  -or -name "target/release" \
  -or -name "obj" \
  -or -name "build" \
  -or -name "dist" \
  -or -name ".cache" \
  -or -name ".Trash" \
  -or -name "$HOME/Library/Caches" \
  -or -name "__pycache__"  \) -type f \
  2>/dev/null | fzf --ignore-case --scheme=path --tiebreak='pathname,length,end' --ansi --walker-skip .git,node_modules,target,obj,build,dist \
  --preview 'bat -n --color=always {}' \
  --cycle \
  --bind 'ctrl-/:change-preview-window(down|hidden|)' \
  --bind 'ctrl-y:become($EDITOR {})' \
  --bind 'enter:become($EDITOR {})'
}

# Consider this
# ei() {
#   local -a search_dirs
#   if (( $# == 0 )); then
#     if [[ "$PWD" != "$HOME" ]]; then
#       search_dirs=("$PWD" "$HOME")
#     else
#       search_dirs=("$HOME")
#     fi
#   else
#     search_dirs=("$@")
#   fi
#
#   bfs "${search_dirs[@]}" -color -mindepth 1 \
#     -exclude \( \
#       -name ".git" \
#       -or -name "node_modules" \
#       -or -name "target/debug" \
#       -or -name "target/release" \
#       -or -name "obj" \
#       -or -name "build" \
#       -or -name "dist" \
#       -or -name ".cache" \
#       -or -name ".Trash" \
#       -or -name "__pycache__" \
#     \) -type f 2>/dev/null |
#   fzf --ignore-case --scheme=path --tiebreak='pathname,length,end' --ansi \
#     --preview 'bat --paging=never -n --color=always --line-range :200 {}' \
#     --cycle \
#     --bind 'ctrl-/:change-preview-window(down|hidden|)' \
#     --print0 |
#   xargs -0 -o ${=EDITOR:-nvim} --
# }

# fkill - kill process
ki() {
  local pid
  pid=$(ps -ef | sed 1d | fzf -m | awk '{print $2}')

  if [ "x$pid" != "x" ]
  then
    echo $pid | xargs kill -${1:-15}
  fi
}
psi() {
  local pid
  pid=$(ps -ef | sed 1d | fzf -m | awk '{print $2}')
  echo pid
}

mani() {
  man -k . | fzf -q "$1" --prompt='man> '  --preview $'echo {} | tr -d \'()\' | awk \'{printf "%s ", $2} {print $1}\' | xargs -r man | col -bx | bat -l man -p --color always' | tr -d '()' | awk '{printf "%s ", $2} {print $1}' | xargs -r man
}

pueue-gui () {
    (
      local repo="$HOME/projects/pueue_webui"
      cd "$repo/v2" || exit 1
      if [ ! -d node_modules ]; then
        npm install || exit 1
      fi
      cd "$repo/v2/server" || exit 1
      cargo build || exit 1
      ./target/debug/pueue-gui
    )
}

# Custom cd function to integrate fzf
cd() {
  # If arguments provided, use normal cd
  if [[ $# -ne 0 ]]; then
    builtin cd "$@"
    return $?
  fi
  
  # Set up search directories
  local search_dirs
  if [[ "$PWD" != "$HOME" ]]; then
    search_dirs=("$PWD" "$HOME")
  else
    search_dirs=("$HOME")
  fi
  
  # Use fzf to select directory
  local dir
  dir=$(bfs "${search_dirs[@]}" -color -mindepth 1 \
    -exclude \( \
      -name ".git" \
      -or -name "node_modules" \
      -or -name "target/debug" \
      -or -name "target/release" \
      -or -name "obj" \
      -or -name "build" \
      -or -name "dist" \
      -or -name "__pycache__" \
    \) -type d 2>/dev/null | \
    fzf --scheme=path \
        --tiebreak='pathname,length,end' \
        --ansi \
        --walker-skip .git,node_modules,target,obj,build,dist \
        --preview 'tree -C {}' \
        --cycle \
        --bind 'ctrl-y:accept' \
        --bind 'ctrl-/:change-preview-window(down|hidden|)')
  
  # Only cd if a directory was selected (fzf wasn't cancelled)
  [[ -n "$dir" ]] && builtin cd "$dir"
}

##############################################################################
# Modal Aliases
##############################################################################
alias-profile() {
  if [[ -z "${1:-}" || "${1:-}" == "list" ]]; then
    local k p on icon desc
    for k in ${(ok)parameters[(I)MNF_ALIAS_PROFILE_*]}; do
      [[ "$k" == *_DESC || "$k" == *_ICON ]] && continue
      p="${k#MNF_ALIAS_PROFILE_}"
      on="${(P)k}"
      icon_key="MNF_ALIAS_PROFILE_${p}_ICON"; icon_val="${(P)icon_key-}"
      desc_key="MNF_ALIAS_PROFILE_${p}_DESC"; desc_val="${(P)desc_key-}"
      print "${on} ${p} --- ${desc_val} ${icon_val}"
    done
    return 0
  fi

  local p="$1"
  local flag="MNF_ALIAS_PROFILE_${p}"
  (( ${+parameters[$flag]} )) || { print "unknown profile: $p"; return 1; }

  if (( ${(P)flag} )); then
    "mnf_alias_profile_${p}_off" 2>/dev/null
    print "$p: off"
  else
    "mnf_alias_profile_${p}_on" 2>/dev/null
    print "$p: on"
  fi
}
## Cloud Aliases
typeset -g MNF_ALIAS_PROFILE_cloud=0
typeset -g MNF_ALIAS_PROFILE_cloud_DESC="nerdctl helpers"
typeset -g MNF_ALIAS_PROFILE_cloud_ICON="☁️"
mnf_alias_profile_cloud_on() {
  function nib() { 
    local containerfile="${1}" ctx="${2}" ref="${3:-}"
    local git_or_cwd=$(git -C "$ctx" rev-parse --show-toplevel 2>/dev/null || pwd)
    local repo=$(basename "$git_or_cwd" | tr '[:upper:]' '[:lower:]')
    if [ -z "$ref" ]; then
      ref="${repo}:latest"
    elif ! printf '%s' "$ref" | grep -q ':'; then
      ref="${repo}:${ref}"
    fi
    nerdctl build --progress=plain -f "$containerfile" -t "$ref" "$ctx" "${@:4}"
  }
  print 'nib=nerdctl build --progress=plain -f ${1} -t ${3:"<reponame>:latest"} ${2}; # usage: nib [Containerfile] [build-ctx] [ref] [args...]  # ref defaults to <repo>:latest'
  #
  function nid() { 
    local img="${1}"
    printf '%s' "$img" | grep -q ':' || img="${img}:latest"
    nerdctl image rm ${img} "${@:2}" 
  }
  print 'nid=nerdctl image rm ${1} # usage nid <image> [args ...]'
  #
  alias nil='nerdctl images'
  print 'nil="nerdctl images"'
  # nili: nerdctl image list (interactive) -> prints selected repo:tag
  nili() {
    nerdctl images -a --format '{{.Repository}}:{{.Tag}} {{.ID}} {{.Size}} {{.CreatedSince}}' \
    | fzf \
    | awk '{print $1}'
  }
  print 'ncli: nerdctl container list interactive. # usage: ncli'
  #
  alias nlog='nerdctl logs -f'
  print 'nlog="nerdctl logs -f"'
  #
  alias ncacheclear='nerdctl builder prune'
  print 'ncacheclear="nerdctl builder prune"'
  #
  alias ncachekill='nerdctl builder prune'
  print 'ncachekill="nerdctl builder prune"'
  #
  alias nps='nerdctl ps'
  print 'nps="nerdctl ps"'
  #
  alias ncl='nerdctl ps'
  print 'ncl="nerdctl ps"'
  #
  ncli() {
    nerdctl container list -a --format '{{.ID}} {{.Image}} {{.Command}} {{.Status}}' \
    | fzf \
    | awk '{print $1}'
  }
  print 'ncli: nerdctl container list interactive. # usage: ncli'
  #
  alias nck='nerdctl container kill'
  print 'nck="nerdctl container kill"'
  #
  ncd() {
    container="${1:-$(ncli)}"
    nerdctl container rm "$container"
  }
  print 'ncd="nerdctl container rm "${1:-$(ncli)}"'
  #
  #
  ncr() {
    if [ -z "${1}" ]; then
      img=$(nili)
      cmd="${2:-bash}"
      print -z "nerdctl run --rm -it "${img}" "${cmd}" "${@:3}""
    else
      img="${1}"
      cmd="${2:-bash}"
      printf "Running: nerdctl run --rm -it "${img}" "${cmd}" "${@:3}"\n" >&2;
      nerdctl run --rm -it "${img}" "${cmd}" "${@:3}"
    fi
  }
  print 'ncr=nerdctl run --rm -it ${1:-$(nili)} "${2:-}" ${@:3}" # usage: ncr [image] [cmd] [args...]'
  #
  nce() {
    if [ -z "${1}" ]; then
      container=$(ncli)
      cmd="${2:-bash}"
      print -z "nerdctl exec -it "${container}" "${cmd}" "${@:3}""
    else
      container="${1}"
      cmd="${2:-bash}"
      printf "Running: nerdctl exec -it "${container}" "${cmd}" "${@:3}"\n" >&2;
      nerdctl exec -it "${img}" "${cmd}" "${@:3}"
    fi
  }
  print 'nce=nerdctl exec -it "${1:-$(ncli)}" "${2:-bash}" "${@:3}" # usage: nce [container] [cmd] [args...]'
  # nca: nerdctl container attach (attach to PID 1 stdio)
  # usage: nca <container>
  nca() { nerdctl attach "${1:-$(ncli)}" "${@:2}"; }
  print 'nca=nerdctl attach "${1:-$(ncli)}" "${@:2}" # usage: nca [container] [args...]'
  MNF_ALIAS_PROFILE_cloud=1
}

mnf_alias_profile_cloud_off() {
  unalias nps ncl nck nib nil nca nrun ncacheclear ncachekill 2>/dev/null
  unfunction nib 2>/dev/null
  unfunction nca 2>/dev/null
  unfunction nce 2>/dev/null
  unfunction ncr 2>/dev/null
  MNF_ALIAS_PROFILE_cloud=0
}


eval "$(fzf --zsh)"
eval "$(codex completion zsh)"
eval "$(uv generate-shell-completion zsh)"
# ref: https://doc.rust-lang.org/nightly/cargo/reference/unstable.html#native-completions
source <(CARGO_COMPLETE=zsh cargo +nightly)
eval "$(pueue completions zsh)"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
