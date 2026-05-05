#!/usr/bin/env bash
# Bitcoin Regtest Dashboard — Stop script

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PID_FILE="$SCRIPT_DIR/server.pid"

if [ ! -f "$PID_FILE" ]; then
  echo "⚠️  server.pid not found — is the server running?"
  exit 1
fi

PID=$(cat "$PID_FILE")

if kill -0 "$PID" 2>/dev/null; then
  kill "$PID"
  rm -f "$PID_FILE"
  echo "✅ Server stopped (PID $PID)"
else
  echo "⚠️  Process $PID not found. Cleaning up PID file."
  rm -f "$PID_FILE"
fi
