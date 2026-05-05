#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# Bitcoin Regtest Dashboard — Send transaction between nodes
#
# Usage:
#   ./scripts/send-transaction.sh <amount_btc> <source_node> <dest_node>
#
# Examples:
#   ./scripts/send-transaction.sh 1 1 2    # Send 1 BTC from node1 to node2
#   ./scripts/send-transaction.sh 0.5 2 1  # Send 0.5 BTC from node2 to node1
# ─────────────────────────────────────────────────────────────────────────────

set -e

# ── Parse arguments ───────────────────────────────────────────────────────────
AMOUNT="$1"
SRC="$2"
DST="$3"

if [[ -z "$AMOUNT" || -z "$SRC" || -z "$DST" ]]; then
  echo ""
  echo "Usage: $0 <amount_btc> <source_node> <dest_node>"
  echo ""
  echo "  amount_btc   Amount to send (e.g. 1, 0.5, 2.5)"
  echo "  source_node  Node that sends (1 or 2)"
  echo "  dest_node    Node that receives (1 or 2)"
  echo ""
  echo "Examples:"
  echo "  $0 1 1 2    → Send 1 BTC from node1 to node2"
  echo "  $0 0.5 2 1  → Send 0.5 BTC from node2 to node1"
  echo ""
  exit 1
fi

if [[ "$SRC" != "1" && "$SRC" != "2" ]]; then
  echo "❌ source_node must be 1 or 2 (got: $SRC)"
  exit 1
fi

if [[ "$DST" != "1" && "$DST" != "2" ]]; then
  echo "❌ dest_node must be 1 or 2 (got: $DST)"
  exit 1
fi

if [[ "$SRC" == "$DST" ]]; then
  echo "❌ source_node and dest_node must be different"
  exit 1
fi

# ── Node config ───────────────────────────────────────────────────────────────
if [[ "$SRC" == "1" ]]; then
  DATADIR_SRC="$HOME/bitcoin/node1"; PORT_SRC=1234; WALLET_SRC="wallet1"
else
  DATADIR_SRC="$HOME/bitcoin/node2"; PORT_SRC=2345; WALLET_SRC="wallet2"
fi

if [[ "$DST" == "1" ]]; then
  DATADIR_DST="$HOME/bitcoin/node1"; PORT_DST=1234; WALLET_DST="wallet1"
else
  DATADIR_DST="$HOME/bitcoin/node2"; PORT_DST=2345; WALLET_DST="wallet2"
fi

CLI_SRC="bitcoin-cli -regtest -datadir=${DATADIR_SRC} -rpcport=${PORT_SRC}"
CLI_DST="bitcoin-cli -regtest -datadir=${DATADIR_DST} -rpcport=${PORT_DST}"
MINE="$(dirname "$0")/mine-blocks.sh"

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║       Bitcoin Regtest — Send Transaction     ║"
echo "╚══════════════════════════════════════════════╝"
echo ""
echo "  Sending : ${AMOUNT} BTC"
echo "  From    : node${SRC} (port ${PORT_SRC})"
echo "  To      : node${DST} (port ${PORT_DST})"
echo ""

# ── Verify nodes are reachable ────────────────────────────────────────────────
echo "━━━ Checking nodes ━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if ! $CLI_SRC getblockchaininfo > /dev/null 2>&1; then
  echo "   ❌ node${SRC} is not running. Start nodes first: ./scripts/start-nodes.sh"
  exit 1
fi
if ! $CLI_DST getblockchaininfo > /dev/null 2>&1; then
  echo "   ❌ node${DST} is not running. Start nodes first: ./scripts/start-nodes.sh"
  exit 1
fi
echo "   ✅ Both nodes online"

# ── Load wallets ──────────────────────────────────────────────────────────────
echo ""
echo "━━━ Loading wallets ━━━━━━━━━━━━━━━━━━━━━━━━━━━"
$CLI_SRC loadwallet "${WALLET_SRC}" 2>/dev/null || true
echo "   ✅ ${WALLET_SRC} loaded on node${SRC}"
$CLI_DST loadwallet "${WALLET_DST}" 2>/dev/null || true
echo "   ✅ ${WALLET_DST} loaded on node${DST}"

# ── Check source balance ──────────────────────────────────────────────────────
echo ""
echo "━━━ Balances before transaction ━━━━━━━━━━━━━━━"
BAL_SRC=$($CLI_SRC getbalance 2>/dev/null || echo "0")
BAL_DST=$($CLI_DST getbalance 2>/dev/null || echo "0")
echo "   node${SRC} (${WALLET_SRC}): ${BAL_SRC} BTC"
echo "   node${DST} (${WALLET_DST}): ${BAL_DST} BTC"

# Check sufficient balance (rough comparison using awk)
ENOUGH=$(awk -v bal="$BAL_SRC" -v amt="$AMOUNT" 'BEGIN { print (bal+0 > amt+0) ? "yes" : "no" }')
if [[ "$ENOUGH" != "yes" ]]; then
  echo ""
  echo "   ❌ Insufficient balance on node${SRC}: ${BAL_SRC} BTC available, ${AMOUNT} BTC requested"
  echo "      Mine some blocks first: bitcoin-cli -regtest -datadir=${DATADIR_SRC} -rpcport=${PORT_SRC} -generate 101"
  exit 1
fi

# ── Get destination address ───────────────────────────────────────────────────
echo ""
echo "━━━ Getting destination address ━━━━━━━━━━━━━━━"
DST_ADDR=$($CLI_DST getnewaddress "${WALLET_DST}")
echo "   node${DST} address: ${DST_ADDR}"

# ── Send transaction ──────────────────────────────────────────────────────────
echo ""
echo "━━━ Sending ${AMOUNT} BTC ━━━━━━━━━━━━━━━━━━━━━━━━━"
TXID=$($CLI_SRC -named sendtoaddress address="$DST_ADDR" amount="$AMOUNT" fee_rate=25)
echo "   ✅ Transaction broadcast!"
echo "   txid: ${TXID}"
echo ""
echo "   node${DST} balance (should be unchanged — tx is in the mempool):"
echo "   $($CLI_DST getbalance 2>/dev/null || echo '0') BTC"
echo ""
echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║  Transaction broadcast — not yet confirmed   ║"
echo "╚══════════════════════════════════════════════╝"
echo ""
echo "  👉 Check the dashboard now:"
echo "     • Mempool counter shows 1 pending transaction"
echo "     • Wallet balances have NOT changed yet"
echo "     • The transaction is waiting to be included in a block"
echo ""
read -rp "  When ready, press Enter." _
echo ""
echo ""
echo "╔═══════════════════════════════════════════════════════╗"
echo "║  Mining block to confirm transaction (or maybe not!)  ║"
echo "╚═══════════════════════════════════════════════════════╝"
echo ""
echo "⛏  Remember you have to mine 1 block using './scripts/mine-blocks.sh 1 1' to confirm the new transaction... or you can send more transactions first!"
echo ""
echo "  Then check the dashboard again:"
echo "     • Mempool is empty"
echo "     • A new block appears at the top of the block list"
echo "     • Click it to see the coinbase + the payment transaction"
echo "     • Wallet balances have updated"
echo ""
