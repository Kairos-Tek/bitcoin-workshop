#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# Bitcoin Regtest Dashboard — Mine blocks
#
# Usage:
#   ./scripts/mine-blocks.sh <num_blocks> <node>
#
# Examples:
#   ./scripts/mine-blocks.sh 1 1      # Mine 1 block on node1
#   ./scripts/mine-blocks.sh 100 2    # Mine 100 blocks on node2
# ─────────────────────────────────────────────────────────────────────────────

set -e

NUM="$1"
NODE="$2"

if [[ -z "$NUM" || -z "$NODE" ]]; then
  echo ""
  echo "Usage: $0 <num_blocks> <node>"
  echo ""
  echo "  num_blocks   Number of blocks to mine (e.g. 1, 100)"
  echo "  node         Node that mines (1 or 2)"
  echo ""
  echo "Examples:"
  echo "  $0 1 1      → Mine 1 block on node1"
  echo "  $0 100 1    → Mine 100 blocks on node1"
  echo ""
  exit 1
fi

if [[ "$NODE" != "1" && "$NODE" != "2" ]]; then
  echo "❌ node must be 1 or 2 (got: $NODE)"
  exit 1
fi

if ! [[ "$NUM" =~ ^[0-9]+$ ]] || [[ "$NUM" -lt 1 ]]; then
  echo "❌ num_blocks must be a positive integer (got: $NUM)"
  exit 1
fi

if [[ "$NODE" == "1" ]]; then
  DATADIR="$HOME/bitcoin/node1"; PORT=1234; WALLET="wallet1"
else
  DATADIR="$HOME/bitcoin/node2"; PORT=2345; WALLET="wallet2"
fi

CLI="bitcoin-cli -regtest -datadir=${DATADIR} -rpcport=${PORT}"

# Check node is running
if ! $CLI getblockchaininfo &>/dev/null; then
  echo "❌ node${NODE} is not running. Start nodes first: ./scripts/start-nodes.sh"
  exit 1
fi

# Ensure a wallet exists and is loaded — required for -generate in Bitcoin Core 24+
LOADED_WALLETS=$($CLI listwallets 2>/dev/null || echo "[]")
if echo "$LOADED_WALLETS" | grep -q "\"${WALLET}\""; then
  : # wallet already loaded — nothing to do
else
  # Try to load it; if it doesn't exist yet, create it silently
  if ! $CLI loadwallet "$WALLET" &>/dev/null; then
    $CLI createwallet "$WALLET" &>/dev/null \
      && echo "   ℹ️  Created wallet '$WALLET' on node${NODE}" \
      || true
  fi
fi

echo ""
echo "⛏  Mining ${NUM} block(s) on node${NODE} (port ${PORT})..."

$CLI -generate "$NUM" > /dev/null

HEIGHT=$($CLI getblockcount 2>/dev/null || echo "?")
echo "   ✅ Done — chain height: ${HEIGHT}"
echo ""
