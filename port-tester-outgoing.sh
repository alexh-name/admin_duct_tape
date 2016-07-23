#!/bin/sh

max=$1
n="1"
url="portquiz.net"

until [[ ${n} -gt ${max} ]]; do
  nc -z ${url} ${n}
  n=$(( ${n} + 1 ))
done
