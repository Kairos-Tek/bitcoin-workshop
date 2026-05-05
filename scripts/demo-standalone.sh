#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# Bitcoin Regtest Dashboard — Standalone demo
#
# Runs the standalone practical exercise from the AFI Blockchain Analytics course:
#   1. Create wallets on both nodes
#   2. Mine 1 block (coinbase not yet spendable)
#   3. Mine 100 more blocks (coinbase of block 1 now mature)
#   4. Send 1 BTC from node1 to node2
#   5. Mine 1 block to confirm the transaction
#   6. Show final balances on both nodes
# ─────────────────────────────────────────────────────────────────────────────

CLI1="bitcoin-cli -regtest -datadir=$HOME/bitcoin/node1 -rpcport=1234"
CLI2="bitcoin-cli -regtest -datadir=$HOME/bitcoin/node2 -rpcport=2345"
MINE="$(dirname "$0")/mine-blocks.sh"
SEND="$(dirname "$0")/send-transaction.sh"

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║       Bitcoin Regtest — Standalone Demo      ║"
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

# ── Step 2: Mine 1 block ──────────────────────────────────────────────────────
echo ""
echo "━━━ Step 2: Mine 1 block on node1 ━━━━━━━━━━━━━"
bash "$MINE" 1 1
echo "   Balance node1 (should be 0 — coinbase needs 100 confirmations):"
echo "   $($CLI1 getbalance) BTC"

# ── Step 3: Mine 100 more blocks ──────────────────────────────────────────────
echo ""
echo "━━━ Step 3: Mine 100 more blocks ━━━━━━━━━━━━━━"
bash "$MINE" 100 1
echo "   Balance node1 (block 1 now has 100+ confirmations → 50 BTC):"
echo "   $($CLI1 getbalance) BTC"

# ── Step 4: Check sync ────────────────────────────────────────────────────────
echo ""
echo "━━━ Step 5: Chain state (both nodes) ━━━━━━━━━━━"
echo "   node1: $($CLI1 getblockchaininfo | python3 -c \
  "import sys,json; d=json.load(sys.stdin); print(f\"height={d['blocks']}  tip={d['bestblockhash'][:20]}...\")")"
echo "   node2: $($CLI2 getblockchaininfo 2>/dev/null | python3 -c \
  "import sys,json; d=json.load(sys.stdin); print(f\"height={d['blocks']}  tip={d['bestblockhash'][:20]}...\")" \
  2>/dev/null || echo "not yet synced — wait a few seconds")"

# ── Step 5: Send 1 BTC node1 → node2 ────────────────────────────────────────
echo ""
echo "━━━ Step 5: Send 1 BTC node1 → node2 ━━━━━━━━━━"
bash "$SEND" 1 1 2

# ── Step 6: Final balances ────────────────────────────────────────────────────
echo ""
echo "━━━ Step 6: Final balances ━━━━━━━━━━━━━━━━━━━━"
echo "   node1 (wallet1): $($CLI1 getbalance) BTC  (50 initial − 1 sent − fee)"
echo "   node2 (wallet2): $($CLI2 getbalance) BTC  (received)"

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║  Demo complete! Run ./start.sh to open       ║"
echo "║  the dashboard and explore blocks & txs.     ║"
echo "╚══════════════════════════════════════════════╝"
echo ""
