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

# Keep in mind that /usr/share/dict/words can contain offensive words.
# If you'd like to filter possibly offensive words out of it, this is one
# way to do it:
# Get a list of possibly offensive words from
# http://www.cs.cmu.edu/~biglou/resources/bad-words.txt, then:
# grep -iv -f bad-words.txt /usr/share/dict/words > good-words.txt
# This can consume a lot of RAM.

set -eu

dict='/usr/share/dict/words'

if [[ ! -f "${dict}" ]]; then
  echo "Dictionary "${dict}" not found."
  exit 1
fi

min_length=${1:-30}

n_words="$(wc -l "${dict}" | awk '{print $1;}')"

function rng() {
  if [[ -x "$(which shuf)" ]]; then
    random_lines="$(shuf -i 1-${n_words} -n 4)"
  else
    n_words_plus_one=$(( ${n_words} + 1 ))
    random_lines="$(jot -w %i -r 4 1 ${n_words_plus_one})"
  fi
}
 
function roll() {
  rng
  n='0'
  while read n_line; do
    array[${n}]="$(awk 'NR=="'$n_line'"{print $1;}' "${dict}")"
    n=$(( ${n} + 1 ))
  done <<<"${random_lines}"
}

length='0'
while [[ ${length} -lt ${min_length} ]]; do
  roll
  length="$(wc -m <<<"${array[@]}")"
done
echo "${array[@]}"
