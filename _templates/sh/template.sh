#!/usr/bin/env bash

set -Eeuo pipefail
trap cleanup SIGINT SIGTERM ERR

LOG_LEVEL=3

LOG_LEVEL_ERROR=1
LOG_LEVEL_WARN=2
LOG_LEVEL_INFO=3
LOG_LEVEL_DEBUG=4
LOG_LEVEL_TRACE=5

DEBUG=0

cleanup() {
  trap - SIGINT SIGTERM ERR
  if [[ $DEBUG == 1 ]]; then
    echo "Exiting"
    log_error "Script failed! See above messages for errors."
  fi
  # script cleanup here
}

setup_colors() {
  if [[ -t 2 ]] && [[ -z "${NO_COLOR-}" ]] && [[ "${TERM-}" != "dumb" ]]; then
    NOFORMAT='\033[0m' RED='\033[0;31m' GREEN='\033[0;32m' ORANGE='\033[0;33m' BLUE='\033[0;34m' PURPLE='\033[0;35m' CYAN='\033[0;36m' YELLOW='\033[1;33m'
    BOLD='\033[1m' ITALIC='\033[3m'
  else
    NOFORMAT='' RED='' GREEN='' ORANGE='' BLUE='' PURPLE='' CYAN='' YELLOW=''
    BOLD='' ITALIC=''
  fi
}
setup_colors

log_error() {
  if [[ $LOG_LEVEL -ge $LOG_LEVEL_ERROR ]]; then @echo "${RED}ERROR:${NOFORMAT} $1"; fi
}

log_warn() {
  if [[ $LOG_LEVEL -ge $LOG_LEVEL_WARN ]]; then @echo "${ORANGE}WARNING:${NOFORMAT} $1"; fi
}

log_info() {
  if [[ $LOG_LEVEL -ge $LOG_LEVEL_INFO ]]; then @echo "${GREEN}INFO:${NOFORMAT} $1"; fi
}

log_debug() {
  if [[ $LOG_LEVEL -ge $LOG_LEVEL_DEBUG ]]; then @echo "${BLUE}DEBUG:${NOFORMAT} $1"; fi
}

@echo() {
  echo >&2 -e "$@"
}

msg() {
  echo >&2 -e "${1-}"
}

abort() {
  local msg=$1
  local code=${2-1} # default exit status 1
  log_error "$msg"
  exit "$code"
}

# NOTE: We ball
"$@"
