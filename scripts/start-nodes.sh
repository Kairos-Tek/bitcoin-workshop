#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# Bitcoin Regtest Dashboard — Start Bitcoin nodes
# ─────────────────────────────────────────────────────────────────────────────
set -e

CLI1="bitcoin-cli -regtest -datadir=$HOME/bitcoin/node1 -rpcport=1234"
CLI2="bitcoin-cli -regtest -datadir=$HOME/bitcoin/node2 -rpcport=2345"

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║  Starting Bitcoin Regtest Nodes              ║"
echo "╚══════════════════════════════════════════════╝"
echo ""

if ! command -v bitcoind &>/dev/null; then
  echo "❌ bitcoind not found in PATH."
  echo "   Run ./scripts/install-mac.sh or ./scripts/install-linux.sh first."
  exit 1
fi

mkdir -p "$HOME/bitcoin/node1" "$HOME/bitcoin/node2"

echo "🚀 Starting node1 (P2P: 1234, RPC: 1234)..."
if $CLI1 getblockchaininfo &>/dev/null; then
  echo "   ⚠️  node1 already running — skipping"
else
  bitcoind -regtest -port=1234 -datadir="$HOME/bitcoin/node1" \
    -rpcport=1234 -bind=127.0.0.1:1235=onion -daemon
  echo "   ✅ node1 started"
fi

echo ""
echo "🚀 Starting node2 (P2P: 2345, RPC: 2345)..."
if $CLI2 getblockchaininfo &>/dev/null; then
  echo "   ⚠️  node2 already running — skipping"
else
  bitcoind -regtest -port=2345 -datadir="$HOME/bitcoin/node2" \
    -rpcport=2345 -bind=127.0.0.1:2346=onion -daemon
  echo "   ✅ node2 started"
fi

echo ""
echo "⏳ Waiting for nodes to be ready..."
for i in {1..20}; do
  sleep 1
  $CLI1 getblockchaininfo &>/dev/null && $CLI2 getblockchaininfo &>/dev/null && break
  printf "."
done
echo ""

echo ""
echo "✅ Both nodes ready!"
echo "   node1 → datadir: $HOME/bitcoin/node1  rpcport: 1234"
echo "   node2 → datadir: $HOME/bitcoin/node2  rpcport: 2345"
echo ""
echo "👉 Next: ./scripts/connect-nodes.sh   ./scripts/demo.sh   ./start.sh"
echo ""
