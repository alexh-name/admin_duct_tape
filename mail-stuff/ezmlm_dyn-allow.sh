#!/bin/sh
# Use on top of ezmlm .qmail file to dynamically check for new allowed senders.

set -eu

sub="/usr/local/bin/ezmlm/ezmlm-sub"
allow_dir="$HOME/lists/allow"

list=$1

${sub} $HOME/${list}/ allow <${allow_dir}/${list}
