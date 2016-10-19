#!/bin/sh

dnsip="/usr/local/bin/dnsip"
dnsqr="/usr/local/bin/dnsqr"
svc="/usr/local/bin/svc"

mv /etc/dnsroots.global /etc/dnsroot.global.old
${dnsip} $( ${dnsqr} ns . | awk '/answer:/ { print $5; }' | sort ) \
  > /etc/dnsroots.global
cp /etc/dnsroots.global /service/dnscache/root/servers/@
${svc} -du /service/dnscache
