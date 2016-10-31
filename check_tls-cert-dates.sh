#!/bin/sh

set -eu

while getopts d:p: name; do
  case $name in
    d)  DEST="${OPTARG}";;
    p)  PORT="${OPTARG}";;
    ?)  exit 2;;
  esac
done

PORT=${PORT:-443}

echo | openssl s_client -connect ${DEST}:${PORT} 2>/dev/null \
| openssl x509 -noout -dates
