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

while getopts dt:m: name; do
  case $name in
    d)  DECODE=1;;
    t)  TO_LOG=1
        TO_FILE="$OPTARG";;
    m)  APPEND=1
        MSG_FILE="$OPTARG";;
    ?)  exit 2;;
  esac
done

INPUT="$(</dev/stdin)"

function prepare {
  MAILS="${INPUT}"

  if [[ ${DECODE} -eq 1 ]]; then
    MAILS="$( awk 'BEGIN { RS = "\n\n" }; NR=="2"' <<<"${MAILS}" )"
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
    mail="$( cut || (echo 'cut failed'; exit 99) )"
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

prepare || (echo 'prepare failed'; exit 99)
split || (echo 'split failed'; exit 99)
forward || (echo 'forward failed'; exit 99)
