#!/bin/sh

# Use this in a .qmail file to check whether a mail's last origin was a trusted
# one. If it was, the next command in .qmail will be executed. If not, the mail
# won't be processed any further.
# e.g.:
# | /usr/local/bin/filter_untrusted-origin TRUSTED_ORIGIN_FILE
# | /usr/local/bin/split_multimail
# ./Maildir/

set -eu

INPUT="$(</dev/stdin)"

TRUSTED_ORIGIN_FILE="$1"
TRUSTED_ORIGIN="$(<${TRUSTED_ORIGIN_FILE})"

LAST_REC="$(grep -F 'Received:' <<<"${INPUT}" \
| head -n1)"

if grep -E "^Received: \(${TRUSTED_ORIGIN}\)" <<<"${LAST_REC}" \
> /dev/null 2>&1; then
  exit 0
 else
  # so qmail will not do any further deliveries in .qmail file
  exit 99
fi
