#!/bin/sh

# Split multiple complete mails (including headers) that are encapsuled into one
# and forward them to recipients defined in each single mail's "To" field.
# Form feed is our delimiter here.

set -eu

# qmail's forward program location
FORWARDBIN=/var/qmail/bin/forward
# mess822 822field location
M822FIELD=/usr/local/bin/822field

# Concatenated and by form feed delimited mails
MAILS="$(</dev/stdin)"

# Count of delimiters actually
N_MAILS="$( grep -c "\f" <<<"${MAILS}" )"

array=()

function cut {
  awk 'BEGIN { RS = "\f" }; NR=="'${NR}'"' <<<"${MAILS}"
}

function split {
  # we don't want the first and last record
  n=2
  until [[ ${n} -gt ${N_MAILS} ]]; do
    count=$(( ${n} - 1 ))
    NR=${n}
    mail="$( cut )"
    array+=("${mail}")
    n=$(( ${n} + 1 ))
  done
}

function forward {
  n=2
  until [[ ${n} -gt ${N_MAILS} ]]; do
    # arrays start at 0
    array_n=$(( ${n} - 2 ))
    to="$( ${M822FIELD} To <<<"${array[${array_n}]}" )"
    ${FORWARDBIN} ${to} <<<"${array[${array_n}]}"
    n=$(( ${n} + 1 ))
  done
}

split
forward
