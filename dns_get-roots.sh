#!/bin/sh

mv /etc/dnsroots.global /etc/dnsroot.global.old
dnsip $(dnsqr ns . | awk '/answer:/ { print $5; }' |sort) \
  > /etc/dnsroots.global
cp /etc/dnsroots.global /service/dnscache/root/servers/@
svc -du /service/dnscache

