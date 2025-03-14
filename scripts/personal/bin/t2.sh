#!/bin/bash
PATH=./node_modules/.bin:$PATH

###### MAIN TASKS

install() { ## install task not implemented
  echo "install task not implemented"
}

build() { ## build task not implemented
  echo "build task not implemented"
}

start() { ## start task not implemented
  echo "start task not implemented"
}

###### UTILS

default() {
  start
}

help() { ## print this help (default)
  echo "$0 <task> <args>"
  grep -E '^([a-zA-Z_-]+\(\) {.*?## .*|######* .+)$$' $0 |
    sed 's/######* \(.*\)/\n               \1/g' |
    sed 's/\([a-zA-Z-]\+\)()/\1/' |
    awk 'BEGIN {FS = "{.*?## "}; {printf "\033[93m%-30s\033[0m %s\033[0m\n", $1, $2}'
}

TIMEFORMAT="Task completed in %3lR"
time ${@:-default}
