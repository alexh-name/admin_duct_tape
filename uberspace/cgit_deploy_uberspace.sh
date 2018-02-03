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

echo 'RewriteEngine On
RewriteCond %{HTTPS} !=on
RewriteCond %{ENV:HTTPS} !=on
RewriteRule .* https://%{SERVER_NAME}%{REQUEST_URI} [R=301,L]

RewriteCond %{REQUEST_FILENAME} !-f
RewriteRule (.*) /cgi-bin/cgit.cgi/$1 [PT]
' > "${domaindir}/.htaccess"

# check if DOMAIN was added as web domain
if ! uberspace-list-domains -w | fgrep "${DOMAIN}" >/dev/null; then
  echo "-- Adding "${DOMAIN}" as web domain..."
  uberspace-add-domain -w -d  "${DOMAIN}"
  echo "-- Waiting 5 minutes for the config to get active..."
  sleep 300
fi

################################################################################
# HTTPS

FIRST_TIME_LE=0

function cert_domain_imported {
  uberspace-list-certificates | fgrep "${DOMAIN}" >/dev/null
}

function cert_le_newest {
  CERTFILE="$(
    find /home/"$(whoami)"/.config/letsencrypt/live/ \
      -name 'fullchain.pem' -exec stat -c '%X %n' {} \; \
    | sort -nr | head -n 1 | awk '{print $2}'
  )"
  CERTDIR="$( echo "${CERTFILE}" | rev | cut -d '/' -f '2-' | rev )"
}

function cert_le_contains_domain {
  cert-info --file "${CERTFILE}" --alt | fgrep "${DOMAIN}" >/dev/null
}

if cert_domain_imported; then
  echo "-- Cert for ${DOMAIN} already available."
else
  echo "-- Getting a cert from Let's Encrypt for ${DOMAIN}..."
  # check if letsencrypt was already configured
  le_config="/home/"$(whoami)"/.config/letsencrypt/cli.ini"
  if [ ! -f "${le_config}" ]; then
    FIRST_TIME_LE=1
    echo '-- First time run uberspace-letsencrypt...'
    uberspace-letsencrypt
  fi

  # check if DOMAIN is already in config
  if ! grep -E "^domains = .*${DOMAIN}.*" "${le_config}" &>/dev/null; then
    sed -i "/^domains\ =\ /s/$/,${DOMAIN}/" "${le_config}"
  fi

  cert_le_newest
  if ! cert_le_contains_domain; then
    letsencrypt certonly
    if ! cert_le_contains_domain; then
      echo "-- Newest cert still not containing ${DOMAIN}."
      exit 1
    fi
  else
    echo "-- ${DOMAIN} already in newest LE cert."
  fi

  # import cert, if it has DOMAIN as alt
  uberspace-add-certificate -k "${CERTDIR}/privkey.pem" -c "${CERTDIR}/cert.pem"
  # check if DOMAIN is now imported
  if cert_domain_imported; then
    echo "-- Cert for ${DOMAIN} ready now."
  else
    echo "-- Cert for ${DOMAIN} still not ready."
    exit 1
  fi
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
  -e "s/^CGIT_SCRIPT_PATH =.*$/CGIT_SCRIPT_PATH = \/home\/$(whoami)\/cgi-bin/" \
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

################################################################################

echo '---- done!'
echo "---- cgit is now available at https://${DOMAIN}."

if [ ${FIRST_TIME_LE} -eq 1 ]; then
  echo "Let's Encrypt wasn't configured before."
  echo "You might want to add"
  echo "  @daily /usr/local/bin/uberspace-letsencrypt-renew"
  echo "to your cron to automatically renew the cert, when needed."
fi

