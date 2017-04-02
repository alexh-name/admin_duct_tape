#!/bin/sh

logs="/var/log/spamd/@*"

grep -oE 'autolearn=.*' ${logs} | cut -d ':' -f 2 | sort | uniq -c

grep -oE 'spamd: result: . -?[0-9]+.*autolearn=[^ham]' ${logs} | awk '$0 !~ /Y/{print $4}' | sort -n | uniq -c
