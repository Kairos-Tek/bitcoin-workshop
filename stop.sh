#!/usr/bin/env bash
# Bitcoin Regtest Dashboard — Script de parada

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PID_FILE="$SCRIPT_DIR/server.pid"

if [ ! -f "$PID_FILE" ]; then
  echo "⚠️  No se encontró server.pid — ¿está el servidor corriendo?"
  exit 1
fi

PID=$(cat "$PID_FILE")

if kill -0 "$PID" 2>/dev/null; then
  kill "$PID"
  rm -f "$PID_FILE"
  echo "✅ Servidor detenido (PID $PID)"
else
  echo "⚠️  El proceso $PID no existe. Limpiando PID file."
  rm -f "$PID_FILE"
fi
