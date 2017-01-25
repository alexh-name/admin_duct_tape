#!/bin/sh

# This script will print four space separated words randomly chosen
# out of a dictionary of newline separated words such as /usr/share/dict/words.
# The resulting phrase is checked to be of a minimum length of 30 characters
# or whatever is given as first argument. It re-rolls as long as it generates
# a phrase of that minimum length.
# I didn't check the distribution of generated numbers for choosing the words
# in the dictionary but I tried to make a reasonable choice of tools used
# for this. The script checks whether shuf is available (often the case on
# GNU systems) and falls back to jot (often found on BSD like systems).

# Use cases can be generating easier to remember, yet reasonably safe
# pass phrases.
#
# Calculating the entropy assuming the method of generation is known:
# Taking a dictionary of 399370 english words gives us 399370^4 =
# 25,439,100,624,082,329,610,000 possible phrases which result in
# log2(25439100624082329610000) ≈ 74.43 entropy bits for such a phrase.
# Assuming hardware capable of guessing 350 billion/s [1], it would take
# ~ 2304 years to try all possible phrases.
#
# Calculating the entropy assuming the method of generation is not known:
# We basically have the symbol set of the case sensitive Latin alphabet
# (a-z, A-Z) which are 52 distinct symbols. Our phrases have by default at least
# 30 characters. We get at minimum 52^30 =
# 3,020,649,319,540,279,026,721,308,472,064,611,280,212,898,898,509,824
# combinations which result in
# log2(3020649319540279026721308472064611280212898898509824) ≈ 117 entropy bits.
# Assuming hardware capable of guessing 350 billion/s [1], it would take
# ~ 273,669,033,081,492,265,231,690,627,678,536 years not taking into account
# rainbow tables etc.
#
# [1] http://arstechnica.com/security/2012/12/25-gpu-cluster-cracks-every-standard-windows-password-in-6-hours/

# Keep in mind that /usr/share/dict/words can contain offensive words.
# If you'd like to filter possibly offensive words out of it, this is one
# way to do it:
# Get a list of possibly offensive words from
# http://www.cs.cmu.edu/~biglou/resources/bad-words.txt, then:
# grep -iv -f bad-words.txt /usr/share/dict/words > good-words.txt
# This can consume a lot of RAM.

# Alex H. - https://keybase.io/alexh_name - 2016

set -eu

dict='/usr/share/dict/words'

if [ ! -f "${dict}" ]; then
  echo "Dictionary ${dict} not found."
  exit 1
fi

min_length="${1:-30}"

n_words="$( wc -l "${dict}" | awk '{print $1;}' )"

function rng {
  if [ -x "$(which shuf)" ]; then
    random_lines="$(shuf -i 1-"${n_words}" -n 4)"
  else
    n_words_plus_one="$(( "${n_words}" + 1 ))"
    random_lines="$( jot -w %i -r 4 1 "${n_words_plus_one}" )"
  fi
}
 
function roll {
  rng
  n='0'
  while read n_line; do
    array[${n}]="$( awk 'NR=="'${n_line}'"{print $1;}' "${dict}" )"
    n="$(( ${n} + 1 ))"
  done <<<"${random_lines}"
}

length='0'
while (( "${length}" < "${min_length}" )); do
  roll
  length="$(wc -m <<<"${array[@]}")"
done
echo "${array[@]}"
