#!/bin/sh

# This script crawls recipients from local mail files and creates a CSV of
# contacts. Recipients of the form NAME <ADRESS> are prioritized over
# ADRESS only to avoid duplication.

# Usage: sh extract_mail_contacts.sh Maildir/.Sent/cur/

# To decode non-ASCII contact names you need imap_mime_header_decoder.php
# or some own replacement.
# (https://gist.github.com/alexh-name/4ea8f5287f35a7c204caaaf1028dd3b2)

# It is not very fast and although I field-tested it, there still might be
# corner cases which break the format.
# It is easy to debug though. I left behind double commented lines for this
# purpose.

# Aside pretty standard unix tools there are no dependencies.
# It should work with POSIX only, but it's not tested (yet).
# When you use imap_mime_header_decoder.php, you need PHP and PHP-imap.

# Alex H. - https://keybase.io/alexh_name - 2016

##set -eu
##n=1
dir=$1
decoder="php ./imap_mime_header_decoder.php"


function extract() {
  m_l_file="${tmpdir}/merged_lines_file"
  find "${dir}" -type f | while read file; do
    sed '$!N;s/\n / /;P;D' "${file}" > ${m_l_file}
    # there can be line breaks inside the list of rcpts
    line="$(awk '/^To:\ .*@.*/{print $0; exit}' ${m_l_file})"
    # stop after first line with 'To: '
    rcpt="$(sed -e 's/^To: //' <<<${line})"
    sed -e 's/, */\n/g' -e 's/,$//' <<<${rcpt} | while read split; do
    # cycle through multiple rcpts
      address="$(cut -d '<' -f2 <<<${split} | cut -d '>' -f1)"
      if ! grep ' ' <<<${split} >/dev/null 2>&1; then
        name=''
        tmpfile="${tmpdir}/unsorted_addresses.tmp"
      else
        name="$(cut -d ':' -f2 <<<${split} | cut -d '<' -f1 \
          | sed -e 's/^ //' -e 's/ $//')"
        if [[ decoder != '' ]]; then
          name="$(${decoder} "${name}")"
        fi
        tmpfile="${tmpdir}/unsorted_contacts.tmp"
      fi
      if [[ ${address} == *@* ]]; then
        printf "%s,%s,\n" "${name}" "${address}" >> ${tmpfile}
        ##printf "%s,%s,%s,%s\n" "${name}" "${address}" "${split}" "${file}" >> ${tmpfile}
      fi
      ##printf "%s\n" "${n}" "${file}" "line:${line}" "split:${split}" "address:${address}" "name:${name}"
      ##printf "\n"
    done
    ##n="$(( ${n} + 1 ))"
  done
}

function merge {
  cp ${tmpdir}/unsorted_contacts.tmp ${tmpdir}/unsorted_merged_contacts.tmp
  while read line; do
    address="$(cut -d ',' -f2 <<<${line})"
    if ! grep "${address}" ${tmpdir}/unsorted_contacts.tmp >/dev/null 2>&1; then
      printf "%s\n" "${line}" >> ${tmpdir}/unsorted_merged_contacts.tmp
    fi
  done < ${tmpdir}/unsorted_addresses.tmp
}

tmpdir="extract_contacts.tmp.d"
mkdir ${tmpdir}
> ${tmpdir}/unsorted_addresses.tmp
> ${tmpdir}/unsorted_contacts.tmp
> ${tmpdir}/unsorted_merged_contacts.tmp
printf "%s\n" "Display Name,Primary Email,"
extract
merge
sort -f -u ${tmpdir}/unsorted_merged_contacts.tmp
rm -r ${tmpdir}
