#!/bin/sh
# Quick and unelegant script to fetch a parity binary of VERSION,
# check against provided checksum and install to /usr/local/bin/.

set -eu

VER="${1}"

function parity_list {
  # List as published via GitHub
  LIST="$(
    curl -s "https://vanity-service.parity.io/parity-binaries?format=markdown&version=v${VER}"
  )"
}

function parity_bin {
  PARITY_BIN="$(
    echo "${LIST}" \
    | egrep '^linux \| x86_64 \| \[parity\]'
  )"

  # Make URL https, it works!
  PARITY_BIN_URL="$(
    echo "${PARITY_BIN}" \
    | awk '{print $5}' \
    | sed -e 's/^\[parity\](//' -e 's/).*$//' -e 's/^http:/https:/'
  )"

  # The list provides a SHA256sum.
  PARITY_BIN_SHA256_LIST="$(
    echo "${PARITY_BIN}" \
    | awk '{print $7}'
  )"

  if [ -e 'parity' ]; then
    echo 'parity exists.'
  else
    wget "${PARITY_BIN_URL}" -O parity
  fi
}

function parity_sha256 {
  echo "${PARITY_BIN_SHA256_LIST}  parity" > parity.sha256
  sha256sum -c parity.sha256
}

echo '  ## Getting version list...'
parity_list
echo '  ## Getting parity binary...'
parity_bin
echo '  ## Checking sha256 hash from list...'
parity_sha256

echo '  ## All fine, cleaning up and putting parity to /usr/local/bin/'
rm parity.sha256
install parity /usr/local/bin/

