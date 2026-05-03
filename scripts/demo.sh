#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# Bitcoin Regtest Dashboard — Full demo
#
# Runs the complete practical exercise from the AFI Blockchain Analytics course:
#   1. Create wallets on both nodes
#   2. Connect the nodes as peers
#   3. Mine 1 block (coinbase not yet spendable)
#   4. Mine 100 more blocks (coinbase of block 1 now mature)
#   5. Send 1 BTC from node1 to node2
#   6. Mine 1 block to confirm the transaction
#   7. Show final balances on both nodes
# ─────────────────────────────────────────────────────────────────────────────

CLI1="bitcoin-cli -regtest -datadir=$HOME/bitcoin/node1 -rpcport=1234"
CLI2="bitcoin-cli -regtest -datadir=$HOME/bitcoin/node2 -rpcport=2345"

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║  Bitcoin Regtest — Full Demo                 ║"
echo "╚══════════════════════════════════════════════╝"

# ── Step 1: Create wallets ────────────────────────────────────────────────────
echo ""
echo "━━━ Step 1: Create wallets ━━━━━━━━━━━━━━━━━━━━"
$CLI1 createwallet "wallet1" 2>/dev/null \
  && echo "   ✅ wallet1 created on node1" \
  || echo "   ⚠️  wallet1 already exists on node1"

$CLI2 createwallet "wallet2" 2>/dev/null \
  && echo "   ✅ wallet2 created on node2" \
  || echo "   ⚠️  wallet2 already exists on node2"

# ── Step 2: Connect nodes ─────────────────────────────────────────────────────
echo ""
echo "━━━ Step 2: Connect nodes as peers ━━━━━━━━━━━━"
$CLI1 addnode "127.0.0.1:2346" "add" 2>/dev/null || true
echo "   ✅ node2 registered as peer of node1"
sleep 2

# ── Step 3: Mine 1 block ──────────────────────────────────────────────────────
echo ""
echo "━━━ Step 3: Mine 1 block on node1 ━━━━━━━━━━━━━"
$CLI1 -generate 1
echo ""
echo "   Balance node1 (should be 0 — coinbase needs 100 confirmations):"
echo "   $($CLI1 getbalance) BTC"

# ── Step 4: Mine 100 more blocks ──────────────────────────────────────────────
echo ""
echo "━━━ Step 4: Mine 100 more blocks ━━━━━━━━━━━━━━"
$CLI1 -generate 100 > /dev/null
echo "   ✅ 100 blocks mined"
echo ""
echo "   Balance node1 (block 1 now has 100+ confirmations → 50 BTC):"
echo "   $($CLI1 getbalance) BTC"

# ── Step 5: Check sync ────────────────────────────────────────────────────────
echo ""
echo "━━━ Step 5: Chain state (both nodes) ━━━━━━━━━━━"
echo "   node1: $($CLI1 getblockchaininfo | python3 -c \
  "import sys,json; d=json.load(sys.stdin); print(f\"height={d['blocks']}  tip={d['bestblockhash'][:20]}...\")")"
echo "   node2: $($CLI2 getblockchaininfo 2>/dev/null | python3 -c \
  "import sys,json; d=json.load(sys.stdin); print(f\"height={d['blocks']}  tip={d['bestblockhash'][:20]}...\")" \
  2>/dev/null || echo "not yet synced — wait a few seconds")"

# ── Step 6: Get node2 address ─────────────────────────────────────────────────
echo ""
echo "━━━ Step 6: Get node2 receiving address ━━━━━━━━"
$CLI2 loadwallet "wallet2" 2>/dev/null || true
NODE2_ADDR=$($CLI2 getnewaddress "wallet2")
echo "   node2 address: $NODE2_ADDR"

# ── Step 7: Send 1 BTC ───────────────────────────────────────────────────────
echo ""
echo "━━━ Step 7: Send 1 BTC node1 → node2 ━━━━━━━━━━"
TXID=$($CLI1 -named sendtoaddress address="$NODE2_ADDR" amount=1 fee_rate=25)
echo "   ✅ Transaction sent!"
echo "   txid: $TXID"
echo ""
echo "   Balance node2 before confirmation (should be 0):"
echo "   $($CLI2 getbalance) BTC"

# ── Step 8: Mine 1 block to confirm ──────────────────────────────────────────
echo ""
echo "━━━ Step 8: Mine 1 block to confirm tx ━━━━━━━━━"
$CLI1 -generate 1 > /dev/null
echo "   ✅ Block mined — transaction confirmed"

# ── Step 9: Final balances ────────────────────────────────────────────────────
echo ""
echo "━━━ Step 9: Final balances ━━━━━━━━━━━━━━━━━━━━"
echo "   node1 (wallet1): $($CLI1 getbalance) BTC  (50 initial − 1 sent − fee)"
echo "   node2 (wallet2): $($CLI2 getbalance) BTC  (received)"

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║  Demo complete! Run ./start.sh to open       ║"
echo "║  the dashboard and explore blocks & txs.     ║"
echo "╚══════════════════════════════════════════════╝"
echo ""
