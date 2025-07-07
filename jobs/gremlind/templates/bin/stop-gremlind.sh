#!/usr/bin/env bash
set -eo pipefail

PIDFILE=/var/vcap/sys/run/gremlind/gremlind.pid

if [ -f "$PIDFILE" ]; then
  kill "$(cat "$PIDFILE")" || true
  rm -f "$PIDFILE"
fi

