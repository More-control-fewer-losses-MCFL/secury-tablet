#!/bin/sh
set -eu

PORT=${PORT:-80}
API_UPSTREAM=${API_UPSTREAM:-api:8000}
PUBLIC_SCHEME=${PUBLIC_SCHEME:-http}
TRUST_CF_CONNECTING_IP=${TRUST_CF_CONNECTING_IP:-false}

printf '%s' "$PORT" | grep -Eq '^[0-9]{1,5}$' || { echo 'Invalid PORT' >&2; exit 1; }
printf '%s' "$API_UPSTREAM" | grep -Eq '^[A-Za-z0-9][A-Za-z0-9.-]*:[0-9]{1,5}$' || {
    echo 'Invalid API_UPSTREAM' >&2; exit 1;
}
case "$PUBLIC_SCHEME" in http|https) ;; *) echo 'Invalid PUBLIC_SCHEME' >&2; exit 1;; esac
case "$TRUST_CF_CONNECTING_IP" in true|false) ;; *) echo 'Invalid TRUST_CF_CONNECTING_IP' >&2; exit 1;; esac

# Use the DNS server supplied by the container runtime, not Docker's fixed local address.
DNS_RESOLVER=$(awk '$1 == "nameserver" && $2 ~ /^[0-9.]+$/ { print $2; exit }' /etc/resolv.conf)
[ -n "$DNS_RESOLVER" ] || { echo 'No IPv4 DNS resolver available' >&2; exit 1; }
export PORT API_UPSTREAM PUBLIC_SCHEME TRUST_CF_CONNECTING_IP DNS_RESOLVER

# Restrict substitution to our variables; Nginx's $host/$uri variables must survive.
envsubst '${PORT} ${API_UPSTREAM} ${PUBLIC_SCHEME} ${TRUST_CF_CONNECTING_IP} ${DNS_RESOLVER}' \
    < /etc/nginx/templates/default.conf.template > /etc/nginx/conf.d/default.conf
nginx -t
exec nginx -g 'daemon off;'
