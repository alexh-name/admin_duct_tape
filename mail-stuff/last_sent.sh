#!/bin/sh

# Build a list of form $USER $EPOCHTIME
# where USERs are derived from a plaintext list.
# The user's whole mail address is expected.
# A typical log file from qmail will be searched for the last time that user
# sent a mail. If a value is found, it will be written to the list.
# Potential older values will be deleted.

set -eu

USERS='/lists/all'
MAILLOG='/var/log/maillog'
LAST_SENT_LIST='/var/last_sent_list.txt'

cat "${USERS}" | while read usr; do
  last_sent="$(
    egrep "info msg [0-9]+: bytes [0-9]+ from <${usr}> qp [0-9]+ uid [0-9]" "${MAILLOG}" \
    | tail -n1 \
    | awk '{print $6}'
  )"
  if [ ! -z "${last_sent}" ]; then
    sed -i "/^${usr}\ [0-9][0-9.]*$/d" "${LAST_SENT_LIST}"
    echo "${usr} ${last_sent}" >> "${LAST_SENT_LIST}"
  fi
done

