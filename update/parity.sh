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
    | sed -e 's/^\[parity\](//' -e 's/).*$//' -e 's/^http/https/'
  )"

  # The list provides a md5sum, ugh.
  PARITY_BIN_MD5_LIST="$(
    echo "${PARITY_BIN}" \
    | awk '{print $7}'
  )"

  if [ -e 'parity' ]; then
    echo 'parity exists.'
  else
    wget "${PARITY_BIN_URL}" -O parity
  fi
}

function parity_md5 {
  echo "${PARITY_BIN_MD5_LIST}  parity" > parity.md5
  md5sum -c parity.md5
}

function parity_hash {
  # Basically the same as in parity_bin
  # sha256 hash exists, but in a separate file
  PARITY_HASH="$(
    echo "${LIST}" \
    | egrep '^linux \| x86_64 \| \[parity\.sha256\]'
  )"
  # Again, https works!
  PARITY_HASH_URL="$(
    echo "${PARITY_HASH}" \
    | awk '{print $5}' \
    | sed -e 's/^\[parity\.sha256\](//' -e 's/).*$//' -e 's/^http/https/'
  )"
  if [ -e 'parity.256' ]; then
    echo 'parity.256 exists.'
  else
    wget "${PARITY_HASH_URL}" -O parity.256
  fi

  # Replace path in sha256 file to match our local file
  sed -i 's/target\/x86_64-unknown-linux-gnu\/release\/parity$/parity/' parity.256
  sha256sum -c parity.256
}

echo '  ## Getting version list...'
parity_list
echo '  ## Getting parity binary...'
parity_bin
echo '  ## Checking md5 hash from list...'
parity_md5
echo '  ## Getting and checking sha256 hash from file...'
parity_hash

echo '  ## All fine, cleaning up and putting parity to /usr/local/bin/'
rm parity.md5
rm parity.256
install parity /usr/local/bin/

