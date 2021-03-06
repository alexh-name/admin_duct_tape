#!/bin/sh

set -eu

problem='0'

problem_msg='
--- smth stuck in queue ---'

out=$(
  find /var/qmail/queue/mess/ -type f \
  | while read msg; do
    msg_n="$( rev <<<"${msg}" | cut -d '/' -f -2 | rev )"
    birth="$( stat --printf="%Y\n" "${msg}" )"
    birth_f="$( stat --printf="%y\n" "${msg}" )"
    date="$( date +%s )"
    age="$(( ${date} - ${birth} ))"
    if (( "${age}" > '43200' )); then
      status='alarming'
    else
      status='fine'
    fi
    printf "msg %s: %s - %s\n" "${msg_n}" "${birth_f}" "${status}"
  done
 )
out_part="$( rev <<<"${out}" | cut -f 1 -d ' ' | rev )"

if grep -F 'alarming' <<<"${out_part}" > /dev/null; then
  out="${out}${problem_msg}"
  problem='1'
fi

echo "${out}"

if (( "${problem}" == '1' )); then
 exit 10
else
 exit 0
fi
