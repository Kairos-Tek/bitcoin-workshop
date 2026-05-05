#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# Bitcoin Regtest Dashboard — Mine blocks
#
# Usage:
#   ./scripts/mine_blocks.sh <num_blocks> <node>
#
# Examples:
#   ./scripts/mine_blocks.sh 1 1      # Mine 1 block on node1
#   ./scripts/mine_blocks.sh 100 2    # Mine 100 blocks on node2
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
  DATADIR="$HOME/bitcoin/node1"; PORT=1234
else
  DATADIR="$HOME/bitcoin/node2"; PORT=2345
fi

CLI="bitcoin-cli -regtest -datadir=${DATADIR} -rpcport=${PORT}"

echo ""
echo "⛏  Mining ${NUM} block(s) on node${NODE} (port ${PORT})..."

if [[ "$NUM" -eq 1 ]]; then
  $CLI -generate 1
else
  $CLI -generate "$NUM" > /dev/null
  echo "   ✅ ${NUM} blocks mined"
fi

HEIGHT=$($CLI getblockcount 2>/dev/null || echo "?")
echo "   Chain height: ${HEIGHT}"
echo ""
