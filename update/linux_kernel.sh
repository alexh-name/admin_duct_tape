#!/bin/sh
# Small script to install a new linux kernel to /boot/

set -eu

JOBS=4
INSTALL_PATH='/boot/linux/'

cd /usr/src/linux
zcat /proc/config.gz > .config
make oldconfig

nice -n 20 make -j${JOBS}
make modules_install

until mountpoint /boot/; do
  echo -n 'Please insert /boot/ '
  echo -ne "\a"
  n=1
  until [ ${n} -gt 10 ]; do
    echo -n '.'
    sleep 1
    n=$(( ${n} + 1 ))
  done
  echo
  mount /boot/ || true
  echo
done

INSTALL_PATH="${INSTALL_PATH}" make install

umount /boot/

echo 'done!'

