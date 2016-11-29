#!/bin/sh

dir="$HOME/scripts/routine"

SCRIPTS="${dir}/space.sh
${dir}/load.sh
${dir}/queue.sh"

V=$1

function fire {
  script=$1
  v=$2
  output="$( nice -n 10 mksh ${script} )"
  if [[ ! $? -eq 0 ]] || [[ ! -z ${v} ]]; then
    echo "${output}"
  fi
}

function cycle {
  while read script; do
    fire $script $V
  done <<<"${SCRIPTS}"
}

cycle