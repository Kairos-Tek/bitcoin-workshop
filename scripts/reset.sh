#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# Bitcoin Regtest Dashboard — Reset nodes to a clean state
#
# Use this to start the exercise from scratch without reinstalling Bitcoin Core.
# It stops the nodes (if running), deletes all blockchain data, and recreates
# the empty directories so you can run start-nodes.sh again immediately.
#
# Usage:
#   ./scripts/reset.sh          # Reset both nodes
#   ./scripts/reset.sh 1        # Reset only node1
#   ./scripts/reset.sh 2        # Reset only node2
# ─────────────────────────────────────────────────────────────────────────────

TARGET="${1:-both}"

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║  Bitcoin Regtest — Reset                     ║"
echo "╚══════════════════════════════════════════════╝"
echo ""

if [[ "$TARGET" != "1" && "$TARGET" != "2" && "$TARGET" != "both" ]]; then
  echo "❌ Invalid argument: '$TARGET'. Use 1, 2, or leave empty for both."
  exit 1
fi

reset_node() {
  local NODE="$1"
  local DATADIR="$HOME/bitcoin/node${NODE}"
  local PORT
  [[ "$NODE" == "1" ]] && PORT=1234 || PORT=2345

  echo "🔄 Resetting node${NODE}..."

  # Stop if running
  if bitcoin-cli -regtest -datadir="$DATADIR" -rpcport="$PORT" \
      getblockchaininfo &>/dev/null; then
    bitcoin-cli -regtest -datadir="$DATADIR" -rpcport="$PORT" stop &>/dev/null
    echo "   ✅ node${NODE} stopped"
    sleep 2
  else
    echo "   ℹ️  node${NODE} was not running"
  fi

  # Delete data directory and recreate empty
  if [ -d "$DATADIR" ]; then
    rm -rf "$DATADIR"
    echo "   ✅ Deleted $DATADIR"
  fi
  mkdir -p "$DATADIR"
  echo "   ✅ Recreated empty $DATADIR"
}

if [[ "$TARGET" == "both" || "$TARGET" == "1" ]]; then
  reset_node 1
fi

echo ""

if [[ "$TARGET" == "both" || "$TARGET" == "2" ]]; then
  reset_node 2
fi

echo ""
echo "✅ Reset complete! Both nodes are back to a clean state."
echo ""
echo "   To start again from scratch:"
echo "   1. ./scripts/start-nodes.sh"
echo "   2. ./start-dashboard.sh"
echo "   3. ./scripts/demo-standalone.sh   (or demo-full.sh)"
echo ""
