#!/bin/sh

# Split multiple complete mails (including headers) that are encapsuled into one
# and forward them to recipients defined in each single mail's "To" field.
# Form feed is our delimiter here.
# Usage e.g. in .qmail:
# | /usr/local/bin/split_multimail [-d] [-t TO_FILE] [-m MSG_FILE]
# -d: The multimail is considered base64 encoded.
# -t TO_FILE: All addresses we forwarded to are saved to TO_FILE
#             (TO_FILE must be writable by user owning .qmail.)
# -m MSG_FILE: Append text to each forwarded mail contained in MSG_FILE.
#             (MSG_FILE must be readable by user owning .qmail.)
# -e EXIT_CODE: Exit code to use if something goes wrong. Use 99 to report
#               success to qmail, 100 for failure. Default: 100.

set -eu

# qmail's forward program location
FORWARDBIN=/var/qmail/bin/forward
# mess822 822field location
M822FIELD=/usr/local/bin/822field

INPUT=''
MAILS=''
DECODE=''
TO_LOG=''
TO_FILE=''
APPEND=''
MSG_FILE=''
N_R=''
array=()

while getopts dt:m:e: name; do
  case $name in
    d)  DECODE=1;;
    t)  TO_LOG=1
        TO_FILE="$OPTARG";;
    m)  APPEND=1
        MSG_FILE="$OPTARG";;
    e)  EXIT_CODE_IN="$OPTARG";;
    ?)  exit 2;;
  esac
done

INPUT="$(</dev/stdin)"

function prepare {
  EXIT_CODE=${EXIT_CODE_IN:-100}

  MAILS="${INPUT}"

  if [[ ${DECODE} -eq 1 ]]; then
    MAILS="$(
      grep -E \
      "^([A-Za-z0-9+/]{4})*([A-Za-z0-9+/]{4}|[A-Za-z0-9+/]{3}=|[A-Za-z0-9+/]{2}==)$" \
      <<<"${MAILS}"
    )"
    MAILS="$( base64 -di <<<"${MAILS}" )"
  fi

  # Number of Records
  N_R="$( grep -c $'^\f' <<<"${MAILS}" )"
}

function cut {
  awk 'BEGIN { RS = "\f" }; NR=="'${NR}'"' <<<"${MAILS}"
}

function split {
  # we don't want the first and last record
  n=2
  until [[ ${n} -gt ${N_R} ]]; do
    NR=${n}
    mail="$( cut )" || (echo 'cut failed'; exit ${EXIT_CODE})
    array+=("${mail}")
    n=$(( ${n} + 1 ))
  done
}

function forward {
  n=2
  until [[ ${n} -gt ${N_R} ]]; do
    # arrays start at 0
    array_n=$(( ${n} - 2 ))
    msg="${array[${array_n}]}"
    if [[ ${APPEND} -eq 1 ]]; then
      appendix="$( <"${MSG_FILE}" )"
      msg="${msg} ${appendix}"
    fi
    to_list="$(
      ${M822FIELD} To <<<"${msg}" \
      | sed -e 's/[;,]/ /g' -e 's/^ //g' -e 's/ \+/ /g' -e 's/[<>]//g' \
        -e "s/ /\n/g"
    )"
    if [[ ${TO_LOG} -eq 1 ]]; then
      echo "${to_list}" >> "${TO_FILE}"
    fi
    while read to; do
      ${FORWARDBIN} "${to}" <<<"${msg}"
    done <<<"${to_list}"
    n=$(( ${n} + 1 ))
  done
}

prepare || (echo 'prepare failed'; exit ${EXIT_CODE})
split || (echo 'split failed'; exit ${EXIT_CODE})
forward || (echo 'forward failed'; exit ${EXIT_CODE})
