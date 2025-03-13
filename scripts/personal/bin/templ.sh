#!/usr/bin/env bash
# Inspried by https://github.com/adriancooney/Taskfile

set -o errexit
set -o pipefail
set -o nounset

DC="${DC:-exec}"

# If we're running in CI we need to disable TTY allocation for docker compose
# commands that enable it by default, such as exec and run.
TTY=""
if [[ ! -t 1 ]]; then
  TTY="-T"
fi

# -----------------------------------------------------------------------------
# Helper functions start with _ and aren't listed in this script's help menu.
# -----------------------------------------------------------------------------

function _dc {
  docker compose "${DC}" ${TTY} "$@"
}

function _build_run_down {
  docker compose build
  docker compose run ${TTY} "$@"
  docker compose down
}

# -----------------------------------------------------------------------------

function cmd {
  # Run any command you want in the web container
  _dc web "$@"
}

function flask {
  # Run any Flask commands
  cmd flask "$@"
}

function lint:dockerfile {
  # Lint Dockerfile
  docker container run --rm -i hadolint/hadolint \
    hadolint --ignore DL3008 --ignore DL3029 - <Dockerfile
}

function lint:shellcheck {
  # Lint shell scripts
  docker container run --rm -it -v "$PWD:/mnt:ro" --workdir /mnt koalaman/shellcheck:stable \
    ./run bin/check-dumps bin/docker-entrypoint-web
}

function lint:python {
  # Lint Python code
  cmd ruff check "$@"
}

function format {
  # Format Python code
  cmd ruff format . "$@"
}

function test {
  # Run test suite
  cmd pytest test/
}

function test:coverage {
  # Get test coverage
  cmd pytest --cov test/ --cov-report term-missing "$@"
}

function shell {
  # Start a shell session in the web container
  cmd bash
}

function mysql {
  # Connect to MariaDB
  # shellcheck disable=SC1091
  . .env
  _dc mariadb mysql -u allthethings -ppassword allthethings
}

function mariapersist {
  # Connect to MariaDB
  # shellcheck disable=SC1091
  source .env
  _dc mariapersist mysql -u "${MARIAPERSIST_USER}" "-p${MARIAPERSIST_PASSWORD}" "${MARIAPERSIST_DATABASE}"
}

function mariapersistreplica {
  # Connect to MariaDB
  # shellcheck disable=SC1091
  source .env
  _dc mariapersistreplica mysql -u "${MARIAPERSIST_USER}" "-p${MARIAPERSIST_PASSWORD}" "${MARIAPERSIST_DATABASE}"
}

function check-translations {
  # Run smoke tests
  cmd bin/check-translations "$@"
}

# function redis-cli {
#   # Connect to Redis
#   _dc redis redis-cli "$@"
# }

function uv:lock {
  # Install python dependencies and write lock file
  _build_run_down web uv sync
}

function pip3:outdated {
  # List any installed packages that are outdated
  cmd uv run pip3 list --outdated
}

function yarn:install {
  # Install yarn dependencies and write lock file
  _build_run_down js yarn install
}

function yarn:outdated {
  # List any installed packages that are outdated
  _dc js yarn outdated
}

function yarn:build:js {
  # Build JS assets, this is meant to be run from within the assets container
  mkdir -p ../public/js
  node esbuild.config.js
}

function yarn:build:css {
  # Build CSS assets, this is meant to be run from within the assets container
  local args=()

  if [ "${NODE_ENV:-}" == "production" ]; then
    args=(--minify)
  else
    args=(--watch)
  fi

  mkdir -p ../public/css
  tailwindcss --postcss -i css/app.css -o ../public/css/app.css "${args[@]}"
}

function clean {
  # Remove cache and other machine generates files
  rm -rf public/*.* public/js public/css public/images public/fonts \
    .pytest_cache/ .coverage celerybeat-schedule

  touch public/.keep
}

function e2e {
  # Run end-to-end tests
  ./bin/wait-until "curl --fail http://localtest.me:8000/dyn/up/databases/"
  cmd pytest test-e2e/ "$@"
}

function check-dumps {
  cmd bin/check-dumps
}

function check:fix {
  # Basic checks in lieu of a full CI pipeline
  #
  # It's expected that your CI environment has these tools available:
  #   - https://github.com/koalaman/shellcheck
  lint:shellcheck
  lint:dockerfile
  lint:python --fix
  format --help
}

function check {
  # Basic checks in lieu of a full CI pipeline
  #
  # It's expected that your CI environment has these tools available:
  #   - https://github.com/koalaman/shellcheck
  printf "\n> Running basic checks...\n" >&2
  lint:shellcheck
  lint:dockerfile
  lint:python

  printf "\n> Verifying code formatting...\n" >&2
  # skipping this until we have reformatted the codebase
  # format --check

  printf "\n> Building docker images...\n" >&2
  if ! [ -f .env ]; then cp .env.dev .env; fi
  docker compose build

  printf "\n> Starting services in docker...\n" >&2
  docker compose up -d

  # shellcheck disable=SC1091
  source .env

  printf "\n> Waiting for services to start...\n" >&2
  ./bin/wait-until "docker compose exec -T mariadb mysql -u allthethings -ppassword allthethings -e 'SELECT 1'"
  ./bin/wait-until "curl --fail http://localtest.me:8000/dyn/up/databases/"

  # echo "Resetting local database..."
  # flask cli dbreset

  printf "\n> Running english and japanese translation tests...\n" >&2
  check-translations en jp

  printf "\n> Running python tests...\n" >&2
  test
}

function help {
  printf "%s <task> [args]\n\nTasks:\n" "${0}"

  compgen -A function | grep -v "^_" | cat -n

  printf "\nExtended help:\n  Each task has comments for general usage\n"
}

# This idea is heavily inspired by: https://github.com/adriancooney/Taskfile
TIMEFORMAT=$'\nTask completed in %3lR'
time "${@:-help}"
