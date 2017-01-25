#!/bin/sh

set -eu

NL='
'
OUT=''
VAL=''

while getopts h:v name; do
  case $name in
    h)  HOST="${OPTARG}";;
    v)  VAL='1';;
    ?)  exit 2;;
  esac
done

OUT_ALL="$(
  echo \
  | openssl s_client -showcerts -servername "${HOST}" -connect "${HOST}":443 2>/dev/null \
  | openssl x509 -inform pem -noout -text
)"

if [[ "${VAL}" == '1' ]]; then
  OUT_VAL="$(
    grep -E "Not (Before|After)" <<<"${OUT_ALL}" \
    | sed 's/^\ +//g' \
    | cut -d ':' -f 2-
  )"
  OUT_BEF="$( awk 'NR == 1' <<<"${OUT_VAL}" )"
  OUT_AFT="$( awk 'NR == 2' <<<"${OUT_VAL}" )"
  AFT_EPOCH=$( date +%s -d "${OUT_AFT}" )
  NOW_EPOCH=$( date +%s )
  SEC_UNTIL=$(( ${AFT_EPOCH} - ${NOW_EPOCH} ))
  OUT_UNTIL="$(( ${SEC_UNTIL} / 86400 ))"
  OUT="${OUT}${NL}Valid since:${OUT_BEF}${NL}Valid until:${OUT_AFT}${NL}Days left: ${OUT_UNTIL}"
fi

printf "%s\n" "${OUT}"
