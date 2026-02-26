#!/usr/bin/env bash
set -euo pipefail

export PATH="/opt/homebrew/bin:/usr/local/bin:/Users/michaelfortunato/.nix-profile/bin:/usr/bin:/bin:/usr/sbin:/sbin:${PATH:-}"

PORT="${ZOTERO_TRANSLATION_SERVER_PORT:-1969}"
CONTAINER_NAME="${ZOTERO_TRANSLATION_SERVER_CONTAINER:-zotero-translation-server}"
IMAGE="${ZOTERO_TRANSLATION_SERVER_IMAGE:-docker.io/zotero/translation-server}"
LOCAL_ENDPOINT="http://127.0.0.1:${PORT}/web"
TUNNEL_PATTERN="ssh -fN -L ${PORT}:127.0.0.1:1969"

log() {
  printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*"
}

need_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    log "Missing required command: $1"
    exit 1
  fi
}

colima_running() {
  colima status --json >/dev/null 2>&1
}

endpoint_reachable() {
  curl --silent --show-error --max-time 3 --output /dev/null \
    -d "https://example.com" \
    -H "Content-Type: text/plain" \
    "${LOCAL_ENDPOINT}" >/dev/null 2>&1
}

container_exists() {
  nerdctl container inspect "${CONTAINER_NAME}" >/dev/null 2>&1
}

container_running() {
  [[ "$(nerdctl inspect -f '{{.State.Status}}' "${CONTAINER_NAME}" 2>/dev/null || true)" == "running" ]]
}

ensure_colima_running() {
  if colima_running; then
    log "Colima already running."
    return
  fi

  log "Starting Colima..."
  colima start --runtime containerd >/dev/null
}

ensure_container_running() {
  if ! container_exists; then
    log "Creating container ${CONTAINER_NAME}..."
    nerdctl run -d --name "${CONTAINER_NAME}" -p "${PORT}:1969" --restart unless-stopped "${IMAGE}" >/dev/null
    return
  fi

  if container_running; then
    log "Container ${CONTAINER_NAME} already running."
    return
  fi

  log "Starting existing container ${CONTAINER_NAME}..."
  nerdctl start "${CONTAINER_NAME}" >/dev/null
}

kill_existing_tunnel() {
  if pgrep -f "${TUNNEL_PATTERN}" >/dev/null 2>&1; then
    log "Refreshing existing SSH tunnel for port ${PORT}."
    pkill -f "${TUNNEL_PATTERN}" || true
  fi
}

start_tunnel() {
  local ssh_cfg
  ssh_cfg="$(mktemp)"
  colima ssh-config > "${ssh_cfg}"
  ssh -fN -L "${PORT}:127.0.0.1:1969" -F "${ssh_cfg}" colima
  rm -f "${ssh_cfg}"
}

ensure_local_endpoint() {
  if endpoint_reachable; then
    log "Translation server is reachable on localhost:${PORT}."
    return
  fi

  log "Local endpoint unavailable. Creating Colima SSH tunnel."
  kill_existing_tunnel
  start_tunnel

  local i
  for i in $(seq 1 15); do
    if endpoint_reachable; then
      log "Translation server is reachable on localhost:${PORT}."
      return
    fi
    sleep 1
  done

  log "Failed to reach translation server on localhost:${PORT}."
  exit 1
}

main() {
  need_cmd colima
  need_cmd nerdctl
  need_cmd curl
  need_cmd ssh
  need_cmd pgrep
  need_cmd pkill

  ensure_colima_running
  ensure_container_running
  ensure_local_endpoint
}

main "$@"
