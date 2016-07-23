#!/bin/sh

# Check whether outgoing ports are allowed.
# Single or multiple ports and ranges are accepted.
# PORT / PORT1 PORT2 PORT3 ... / LOW_PORT-HIGH_PORT

set -eu

args=$@
url='portquiz.net'
cmd="nc -z ${url}"

if [[ $# -eq 1 ]]; then
  function="${cmd} ${args}"
else
  function='cycling_check'
fi

function cycling_check() {
  while read port; do
    ${cmd} ${port}
  done <<<"$( tr ' ' '\n' <<<${args})"
}

${function}
