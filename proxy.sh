#!/bin/sh
# prox.sh - squid forward proxy, no auth, guarded
# usage: ./proxy.sh [-p PORT]   (default 3128)
set -e

PORT=3128
SELF=$(basename "$0")
usage() { echo "usage: $SELF [-p PORT]   (default 3128)"; }

# dep: cmd -> apk package. skip if present, install if missing.
need() {
	command -v "$1" >/dev/null 2>&1 && return 0
	echo "dep missing: $1 -> apk add $2"
	apk update >/dev/null 2>&1
	apk add --no-cache "$2" >/dev/null 2>&1 || true
	command -v "$1" >/dev/null 2>&1 || { echo "error: failed to install $1 ($2)" >&2; exit 1; }
}

while getopts ":p:h" opt; do
  case "$opt" in
    p) PORT=$OPTARG ;;
    h) usage; exit 0 ;;
    :) echo "error: -$OPTARG needs a value" >&2; usage >&2; exit 2 ;;
    *) usage >&2; exit 2 ;;
  esac
done

case "$PORT" in
  ''|*[!0-9]*) echo "error: port must be numeric, got '$PORT'" >&2; exit 2 ;;
esac
[ "$PORT" -ge 1 ] && [ "$PORT" -le 65535 ] || { echo "error: port out of range: $PORT" >&2; exit 2; }
[ "$PORT" -eq 53 ] && { echo "error: port 53 is used by slowdns" >&2; exit 2; }

CONF=/etc/squid/squid.conf

need squid squid
need curl curl
need ss iproute2-ss

[ -f "$CONF.orig" ] || cp "$CONF" "$CONF.orig"

cat > "$CONF" <<CONF_EOF
# minimal forward proxy, no auth, guards: no internal dest, no abuse ports
http_port $PORT
visible_hostname 9router

acl internal_nets dst 10.0.0.0/8 127.0.0.0/8 169.254.0.0/16 172.16.0.0/12 192.168.0.0/16
acl abuse_ports port 25 135 137 138 139 445 6667

http_access deny internal_nets
http_access deny abuse_ports
http_access allow all

# cache off, memory/disk swap dir skipped
cache deny all
pid_filename /run/squid/squid.pid
coredump_dir /var/cache/squid
access_log /var/log/squid/access.log squid
cache_log /var/log/squid/cache.log
CONF_EOF

# 1. Fix: Siapkan direktori run, log, cache & kepemilikan user squid
mkdir -p /run/squid /var/log/squid /var/cache/squid
rm -f /run/squid/* /var/run/squid.pid /run/squid.pid
chown -R squid:squid /run/squid /var/log/squid /var/cache/squid

# 2. Validasi konfigurasi
if squid -k parse 2>&1 | grep -iE 'error|fatal'; then
  echo "conf invalid, abort" >&2
  exit 1
fi

# 3. Fix: Hentikan proses squid lama (jika ada) & turunkan ulimit agar tidak Bad file descriptor di Docker
pkill -9 squid >/dev/null 2>&1 || true
sleep 1
ulimit -n 65535

# Jalankan langsung binary squid (bypass OpenRC yang sering gagal di container)
squid -f "$CONF"

# Tunggu port aktif (maksimal 10 detik)
for i in $(seq 1 10); do
  ss -lnt 2>/dev/null | grep -q ":$PORT" && break
  sleep 1
done

ss -lnt 2>/dev/null | grep -q ":$PORT" || {
  echo "FAIL: $PORT not listening. Cache log:" >&2
  cat /var/log/squid/cache.log >&2 || true
  exit 1
}

code=$(curl -s -x "http://127.0.0.1:$PORT" -o /dev/null -w '%{http_code}' --max-time 15 http://example.com || true)
[ "$code" = 200 ] || { echo "FAIL: http proxy test got $code" >&2; exit 1; }

code=$(curl -s -x "http://127.0.0.1:$PORT" -o /dev/null -w '%{http_code}' --max-time 20 https://example.com || true)
[ "$code" = 200 ] || { echo "FAIL: https CONNECT test got $code" >&2; exit 1; }

code=$(curl -s -x "http://127.0.0.1:$PORT" -o /dev/null -w '%{http_code}' --max-time 10 http://10.199.98.3/ || true)
[ "$code" = 403 ] || { echo "FAIL: internal guard got $code (want 403)" >&2; exit 1; }

echo "OK: squid proxy up on $PORT (http+https ok, internal blocked)"
