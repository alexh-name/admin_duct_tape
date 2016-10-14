#!/bin/sh

INPUT="$(</dev/stdin)"

grep -F 'Received:' <<<"${INPUT}" \
| head -n1 \
| grep -E "^Received: \(qmail [0-9]+ invoked by alias\)" > /dev/null 2>&1

if [[ $? -eq 0 ]]; then
  exit 0
 else
  # so qmail will not do any further deliveries in .qmail file
  exit 99
fi