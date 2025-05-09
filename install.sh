#!/bin/bash

install() {
  #install_via_stow
  dev_install
  "WARN: Make sure you git stow your specific machine folder but never add nvim to it"
}

install_via_stow() {
  stow nvim kitty git
}

dev_install() {
  echo "Setting up dev environment..."
  echo "NOTE: Needs to be run after install (stow'ed etc)."
  dev_install_git_hooks

}

dev_install_git_hooks() {
  GIT_DIR="$(git rev-parse --git-dir)"
  GIT_HOOKS_DIR="$(git config --get core.hooksPath || git rev-parse --git-path hooks)"
  echo "Installling pre-push"
  GIT_HOOK_FILE="$GIT_HOOKS_DIR/pre-push"
  cat <<"EOF" >$GIT_HOOK_FILE
#!/bin/bash
source ~/.config/git/git-hooks/pre-push/dotfiles
EOF
  chmod +x $GIT_HOOK_FILE
}

install
