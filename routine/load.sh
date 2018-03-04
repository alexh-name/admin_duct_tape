#!/bin/sh

set -eu

problem=''

problem_msg='
--- high load ---'

out="$( uptime )"
out_part="$(
  rev <<<"${out}" | awk '{print $2}' | rev | sed -e 's/\.//' -e 's/,//g'
)"

if [[ "${out_part}" -gt 85 ]] ; then
  out="${out}${problem_msg}"
  problem=1
fi

echo "${out}"

if [[ ${problem} -eq 1 ]]; then
 exit 10
else
 exit 0
fi
