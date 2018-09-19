#!/bin/sh

set -eu

problem=''
NL='
'

problem_msg='
--- high load ---'

out="$( uptime )"
out_part="$(
  rev <<<"${out}" | awk '{print $2}' | rev | sed -e 's/\.//' -e 's/,//g'
)"

if [[ "${out_part}" -gt 85 ]] ; then
  out="${out}${problem_msg}"
  ps_out="$(
    ps -Ao user,pcpu,pmem,args | sort -nrk 2,2 | head -n 5
  )"
  out="${out}${NL}${ps_out}"
  problem=1
fi

echo "${out}"

if [[ ${problem} -eq 1 ]]; then
 exit 10
else
 exit 0
fi

