#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# Bitcoin Regtest Dashboard — Connect node1 and node2 as peers
# ─────────────────────────────────────────────────────────────────────────────
set -e

CLI1="bitcoin-cli -regtest -datadir=$HOME/bitcoin/node1 -rpcport=1234"
CLI2="bitcoin-cli -regtest -datadir=$HOME/bitcoin/node2 -rpcport=2345"

echo ""
echo "🔗 Connecting node1 ↔ node2..."

# Register node2 as a peer of node1
$CLI1 addnode "127.0.0.1:2346" "add"
echo "   ✅ node2 (127.0.0.1:2346) added as peer of node1"

sleep 2

echo ""
echo "📡 Peer info for node1:"
$CLI1 getpeerinfo | grep -E '"addr"|"subver"|"synced_blocks"' \
  || echo "   (no peers yet — wait a few seconds and retry)"

echo ""
echo "✅ Done. Nodes will sync automatically."
echo ""
