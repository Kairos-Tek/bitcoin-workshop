#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# Bitcoin Regtest Dashboard — Stop Bitcoin nodes
# ─────────────────────────────────────────────────────────────────────────────

echo ""
echo "🛑 Stopping Bitcoin Regtest Nodes..."
echo ""

if bitcoin-cli -regtest -datadir="$HOME/bitcoin/node1" -rpcport=1234 \
    getblockchaininfo &>/dev/null; then
  bitcoin-cli -regtest -datadir="$HOME/bitcoin/node1" -rpcport=1234 stop
  echo "   ✅ node1 stopped"
else
  echo "   ⚠️  node1 was not running"
fi

if bitcoin-cli -regtest -datadir="$HOME/bitcoin/node2" -rpcport=2345 \
    getblockchaininfo &>/dev/null; then
  bitcoin-cli -regtest -datadir="$HOME/bitcoin/node2" -rpcport=2345 stop
  echo "   ✅ node2 stopped"
else
  echo "   ⚠️  node2 was not running"
fi

echo ""
echo "✅ All Bitcoin nodes stopped."
echo ""
