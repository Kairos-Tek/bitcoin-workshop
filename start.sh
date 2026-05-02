#!/usr/bin/env bash
# Bitcoin Regtest Dashboard — Script de arranque
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
    echo "⚠️  El servidor ya está corriendo (PID $OLD_PID)"
    echo "   Usa ./stop.sh para detenerlo primero."
    exit 1
  else
    echo "🧹 PID antiguo encontrado pero el proceso no existe. Limpiando..."
    rm -f "$PID_FILE"
  fi
fi

# Verificar python3
if ! command -v python3 &>/dev/null; then
  echo "❌ Error: python3 no encontrado en PATH"
  exit 1
fi

# Arrancar el servidor en background
echo "🚀 Arrancando servidor API en puerto $PORT..."
python3 "$SERVER" > "$SCRIPT_DIR/server.log" 2>&1 &
SERVER_PID=$!
echo $SERVER_PID > "$PID_FILE"

# Esperar a que esté listo (máx 5 seg)
for i in {1..10}; do
  sleep 0.5
  if curl -s "http://localhost:$PORT/api/status" > /dev/null 2>&1; then
    break
  fi
done

# Verificar estado
STATUS=$(curl -s "http://localhost:$PORT/api/status" 2>/dev/null)
if [ -z "$STATUS" ]; then
  echo "❌ Error: el servidor no respondió. Revisa server.log para más detalles."
  cat "$SCRIPT_DIR/server.log"
  exit 1
fi

echo "✅ Servidor corriendo (PID $SERVER_PID)"
echo ""
echo "   API:       http://localhost:$PORT/api/status"
echo "   Dashboard: file://$SCRIPT_DIR/index.html"
echo ""
echo "   Para detener: ./stop.sh"
echo ""

# Abrir el dashboard en el navegador (via HTTP, no file://)
echo "🌐 Abriendo dashboard en el navegador..."
open "http://localhost:$PORT/"

echo "✅ Dashboard abierto."
echo ""
