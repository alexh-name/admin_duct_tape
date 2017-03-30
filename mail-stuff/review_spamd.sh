#!/bin/sh

logs="/var/log/spamd/@*"

grep -oE 'spamd: result: . -?[0-9]+' ${logs} | awk '{print $4}' | sort -n | uniq -c

