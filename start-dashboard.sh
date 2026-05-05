#!/usr/bin/env bash
# Bitcoin Regtest Dashboard — Start script
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVER="$SCRIPT_DIR/server.py"
PID_FILE="$SCRIPT_DIR/server.pid"
PORT=18500

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║  Bitcoin Regtest Dashboard                   ║"
echo "╚══════════════════════════════════════════════╝"
echo ""

# Verificar si ya hay un servidor corriendo
if [ -f "$PID_FILE" ]; then
  OLD_PID=$(cat "$PID_FILE")
  if kill -0 "$OLD_PID" 2>/dev/null; then
    echo "⚠️  Server is already running (PID $OLD_PID)"
    echo "   Use ./stop-dashboard.sh to stop it first."
    exit 1
  else
    echo "🧹 Stale PID found but process is gone. Cleaning up..."
    rm -f "$PID_FILE"
  fi
fi

# Check python3
if ! command -v python3 &>/dev/null; then
  echo "❌ Error: python3 not found in PATH"
  exit 1
fi

# Start server in background
echo "🚀 Starting API server on port $PORT..."
python3 "$SERVER" > "$SCRIPT_DIR/server.log" 2>&1 &
SERVER_PID=$!
echo $SERVER_PID > "$PID_FILE"

# Wait until ready (max 5s)
for i in {1..10}; do
  sleep 0.5
  if curl -s "http://localhost:$PORT/api/status" > /dev/null 2>&1; then
    break
  fi
done

# Check status
STATUS=$(curl -s "http://localhost:$PORT/api/status" 2>/dev/null)
if [ -z "$STATUS" ]; then
  echo "❌ Error: server did not respond. Check server.log for details."
  cat "$SCRIPT_DIR/server.log"
  exit 1
fi

echo "✅ Servidor corriendo (PID $SERVER_PID)"
echo ""
echo "   API:       http://localhost:$PORT/api/status"
echo "   Dashboard: file://$SCRIPT_DIR/index.html"
echo ""
echo "   To stop: ./stop-dashboard.sh"
echo ""

# Open dashboard in browser (via HTTP, not file://)
echo "🌐 Abriendo dashboard en el navegador..."
open "http://localhost:$PORT/"

echo "✅ Dashboard abierto."
echo ""
