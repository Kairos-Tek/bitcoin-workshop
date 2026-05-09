#!/usr/bin/env bash
# Bitcoin Regtest Dashboard — Start script

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVER="$SCRIPT_DIR/server.py"
PID_FILE="$SCRIPT_DIR/server.pid"
PORT=18500

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║  Bitcoin Regtest Dashboard                   ║"
echo "╚══════════════════════════════════════════════╝"
echo ""

# Check if already running
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
  echo "❌ python3 not found in PATH."
  echo "   Install it first — see the Prerequisites section in README.md"
  exit 1
fi

# Check curl (needed to verify server startup)
if ! command -v curl &>/dev/null; then
  echo "❌ curl not found. Install it with: sudo apt install curl"
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
  echo "❌ Server did not respond. Check server.log for details:"
  cat "$SCRIPT_DIR/server.log"
  rm -f "$PID_FILE"
  exit 1
fi

echo "✅ Server running (PID $SERVER_PID)"
echo ""
echo "   Dashboard: http://localhost:$PORT"
echo "   API:       http://localhost:$PORT/api/status"
echo ""
echo "   To stop: ./stop-dashboard.sh"
echo ""

# Open dashboard in browser — detect OS
URL="http://localhost:$PORT/"
if [[ "$OSTYPE" == "darwin"* ]]; then
  # macOS
  open "$URL"
  echo "✅ Dashboard opened in browser."
elif grep -qi microsoft /proc/version 2>/dev/null; then
  # WSL2 — open browser on the Windows side
  if command -v wslview &>/dev/null; then
    wslview "$URL"
    echo "✅ Dashboard opened in browser."
  elif command -v explorer.exe &>/dev/null; then
    explorer.exe "$URL"
    echo "✅ Dashboard opened in browser."
  else
    echo "👉 Open your browser and go to: $URL"
    echo "   (Install wslu for automatic browser opening: sudo apt install wslu)"
  fi
elif command -v xdg-open &>/dev/null; then
  # Linux desktop
  xdg-open "$URL" &>/dev/null &
  echo "✅ Dashboard opened in browser."
else
  echo "👉 Open your browser and go to: $URL"
fi
echo ""
