#!/usr/bin/env bash
set -eo pipefail

# Render config.yaml
cp "$(dirname "$0")/../config.yaml" /etc/gremlin/config.yaml

# Prepare PID directory
PIDDIR=/var/vcap/sys/run/gremlind
mkdir -p "$PIDDIR"
chown vcap:vcap "$PIDDIR"
chmod 755 "$PIDDIR"

# Start gremlind and capture PID
/var/vcap/packages/gremlin/sbin/gremlind \
  >> /var/vcap/sys/log/gremlind/stdout.log \
  2>> /var/vcap/sys/log/gremlind/stderr.log &

echo $! > "$PIDDIR/gremlind.pid"
