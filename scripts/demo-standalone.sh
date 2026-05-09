#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# Bitcoin Regtest Workshop — Demo A (standalone)
#
# Standalone demo: node1 mines and transacts in isolation.
#   1. Create wallets on both nodes
#   2. Mine 1 block (coinbase not yet spendable)
#   3. Mine 100 more blocks (coinbase of block 1 now mature)
#   4. Send 1 BTC from node1 to node2 (broadcast only — check mempool in dashboard)
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

# ── Step 4: Chain state ───────────────────────────────────────────────────────
echo ""
echo "━━━ Step 4: Chain state (both nodes) ━━━━━━━━━━━"
echo "   node1: $($CLI1 getblockchaininfo | python3 -c \
  "import sys,json; d=json.load(sys.stdin); print(f\"height={d['blocks']}  tip={d['bestblockhash'][:20]}...\")")"
echo "   node2: $($CLI2 getblockchaininfo 2>/dev/null | python3 -c \
  "import sys,json; d=json.load(sys.stdin); print(f\"height={d['blocks']}  tip={d['bestblockhash'][:20]}...\")" \
  2>/dev/null || echo "not yet synced — wait a few seconds")"

# ── Dashboard checkpoint ─────────────────────────────────────────────────────
echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║  Check the dashboard before continuing       ║"
echo "╚══════════════════════════════════════════════╝"
echo ""
echo "  👉 Switch to the dashboard and verify:"
echo "     • node1 shows 101 blocks mined"
echo "     • node2 shows height 0 (no blocks yet)"
echo "     • Wallet balance: node1 shows 50 BTC, node2 shows 0 BTC"
echo "     • Comparison panel (bottom): nodes are OUT OF SYNC"
echo "       — different heights, different tip hashes"
echo "       — sync indicator is red: nodes are not connected as peers"
echo ""
read -rp "  When ready, press Enter to send the transaction." _
echo ""

# ── Step 5: Send 1 BTC node1 → node2 (broadcast only) ───────────────────────
echo ""
echo "━━━ Step 5: Send 1 BTC node1 → node2 ━━━━━━━━━━"
bash "$SEND" 1 1 2

# ── Step 6: Mine 1 block to confirm ──────────────────────────────────────────
echo "━━━ Step 6: Mine 1 block to confirm ━━━━━━━━━━━"
bash "$MINE" 1 1
echo "   ✅ Transaction confirmed"

# ── Step 7: Final balances ────────────────────────────────────────────────────
echo ""
echo "━━━ Step 7: Final balances ━━━━━━━━━━━━━━━━━━━━"
echo "   node1 (wallet1): $($CLI1 getbalance) BTC  (50 initial − 1 sent − fee)"
echo "   node2 (wallet2): $($CLI2 getbalance) BTC  (received)"

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║  Check the dashboard to verify confirmation  ║"
echo "╚══════════════════════════════════════════════╝"
echo ""
echo "  👉 Switch to the dashboard and verify:"
echo "     • Mempool is now empty (0 pending transactions)"
echo "     • A new block appears at the top of node1's block list"
echo "     • Click that block — it contains 2 transactions:"
echo "       1. Coinbase (block reward to the miner)"
echo "       2. The 1 BTC payment from node1 to node2"
echo "     • Wallet balances:"
echo "       — node1: ~49 BTC (50 − 1 sent − small fee)"
echo "       — node2:  0 BTC — it has not received anything yet"
echo "         (the nodes are not connected — node2 has never seen the transaction)"
echo "     • Comparison panel: nodes still OUT OF SYNC"
echo "       — node1 at height 102, node2 at height 0"
echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║  Final step: connect the nodes               ║"
echo "╚══════════════════════════════════════════════╝"
echo ""
echo "  Run the following command to connect the nodes as peers:"
echo ""
echo "     ./scripts/connect-nodes.sh"
echo ""
echo "  Then watch the dashboard — within seconds you will see:"
echo "     • node2 syncs automatically: height jumps from 0 to 102"
echo "     • Both nodes show 1 peer (each other)"
echo "     • node2 wallet updates to 1 BTC"
echo "     • Both block lists show the same blocks and the same tip hash"
echo "     • Comparison panel turns GREEN — nodes are in sync"
echo ""
echo "  This is Bitcoin's consensus rule in action:"
echo "  nodes always adopt the longest valid chain."
echo ""
