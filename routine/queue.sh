#!/bin/sh

set -eu

problem=''

problem_msg='
--- smth stuck in queue ---'

out=$( /usr/local/bin/qmailctl stat | grep 'messages in queue:' )
out_part=$( rev <<<"${out}" | cut -f 1 -d ' ' )

if (( "${out_part}" != 0 )) ; then
  out="${out}${problem_msg}"
  problem=1
fi

echo "${out}"

if [[ ${problem} -eq 1 ]]; then
 exit 10
else
 exit 0
fi
