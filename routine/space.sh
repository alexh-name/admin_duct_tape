#!/bin/sh

set -eu

problem=''

problem_msg='
--- low disk space ---'

out="$( df | awk 'NR>1 {print $5,$6}' )"
out_part="${out}"

if grep -E -e "9[0-9]%" -e '100%' <<<"${out_part}" > /dev/null ; then
  out="${out}${problem_msg}"
  problem=1
fi

echo "${out}"

if [[ ${problem} -eq 1 ]]; then
 exit 10
else
 exit 0
fi
