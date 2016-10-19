#!/bin/sh

# Split multiple complete mails (including headers) that are encapsuled into one
# and forward them to recipients defined in each single mail's "To" field.
# Form feed is our delimiter here.
# If any argument is given, the multimail is considered base64 encoded.
# Usage e.g. in .qmail:
# | /usr/local/bin/split_multimail [d]

set -eu

# qmail's forward program location
FORWARDBIN=/var/qmail/bin/forward
# mess822 822field location
M822FIELD=/usr/local/bin/822field

ARGS_N=$#

# Concatenated and by form feed delimited mails
MAILS="$( awk 'BEGIN { RS = "\n\n" }; NR=="2"' </dev/stdin )"

if [[ ${ARGS_N} -ne 0 ]]; then
  MAILS="$( base64 -d <<<"${MAILS}" )"
fi

# Number of Records
N_R="$( grep -c $'^\f' <<<"${MAILS}" )"

array=()

function cut {
  awk 'BEGIN { RS = "\f" }; NR=="'${NR}'"' <<<"${MAILS}"
}

function split {
  # we don't want the first and last record
  n=2
  until [[ ${n} -gt ${N_R} ]]; do
    NR=${n}
    mail="$( cut )"
    array+=("${mail}")
    n=$(( ${n} + 1 ))
  done
}

function forward {
  n=2
  until [[ ${n} -gt ${N_R} ]]; do
    # arrays start at 0
    array_n=$(( ${n} - 2 ))
    to="$( ${M822FIELD} To <<<"${array[${array_n}]}" )"
    ${FORWARDBIN} ${to} <<<"${array[${array_n}]}"
    n=$(( ${n} + 1 ))
  done
}

split
forward
