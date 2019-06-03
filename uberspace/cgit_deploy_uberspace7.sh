#!/bin/sh
# Automatically deploy cgit on Uberspace:
# - create folder for domain
# - create .htaccess with HTTPS enforcement
# - add domain to web server config
# - get cert from Let's Encrypt if no matching cert is already available
# - fully install cgit via modified Makefile
# Usage: ./this-script DOMAIN

set -eu

################################################################################
# Prepare webroot

DOMAIN=''

if [ $# -gt 0 ]; then
 DOMAIN="$1"
fi

# end here if no domain was submitted
if [ -z "${DOMAIN}" ]; then
  echo "-- No domain was submitted."
  exit 0
fi

domaindir="/var/www/virtual/$(whoami)/${DOMAIN}"
if [ -d "${domaindir}" ]; then
  echo "-- Using directory ${domaindir}."
else
  mkdir /var/www/virtual/"$(whoami)"/"${DOMAIN}"
  echo "-- Made a directory for domain ${DOMAIN}."
fi

echo 'AddHandler cgi-script .cgi
Options +ExecCGI
' > "${domaindir}/.htaccess"

# check if DOMAIN was added as web domain
if ! uberspace web domain list | fgrep "${DOMAIN}" >/dev/null; then
  echo "-- Adding "${DOMAIN}" as web domain..."
  uberspace web domain add "${DOMAIN}"
  echo "-- Waiting 5 minutes for the config to get active..."
  sleep 300
fi

################################################################################
# Building

# check if we are in a git repo of cgit

function git_cgit_check {
  fgrep 'url = https://git.zx2c4.com/cgit' ./.git/config &>/dev/null
}

if ! git_cgit_check && [ -d ./cgit ]; then
    cd ./cgit
fi
if ! git_cgit_check; then
  echo '-- Cloning https://git.zx2c4.com/cgit...'
  git clone https://git.zx2c4.com/cgit
  cd cgit
fi

cp Makefile Makefile.orig

sed -i \
  -e "s/^CGIT_SCRIPT_PATH =.*$/CGIT_SCRIPT_PATH = \/var\/www\/virtual\/$(whoami)\/${DOMAIN}/" \
  -e "s/^CGIT_DATA_PATH =.*$/CGIT_DATA_PATH = \/var\/www\/virtual\/$(whoami)\/${DOMAIN}/" \
  -e "s/^CGIT_CONFIG =.*$/CGIT_CONFIG = \/home\/$(whoami)\/etc\/cgitrc/" \
  -e "s/^CACHE_ROOT =.*$/CGIT_CONFIG = \/home\/$(whoami)\/cache\/cgitrc/" \
  -e "s/^prefix =.*$/prefix = \/home\/$(whoami)\/local/" \
Makefile

echo '-- Modified Makefile for Uberspace. Original copied to Makefile.orig.'

echo '-- Getting copy of git...'
git submodule init
git submodule update
echo '-- Making...'
make
make install

mv "${domaindir}/cgit.cgi" "${domaindir}/index.cgi"

################################################################################

echo '---- done!'
echo "---- cgit is now available at https://${DOMAIN}."
