#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# Bitcoin Regtest Dashboard — Mac installation
# Requires: Homebrew (https://brew.sh)
# ─────────────────────────────────────────────────────────────────────────────
set -e

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║  Bitcoin Core — Mac Installation             ║"
echo "╚══════════════════════════════════════════════╝"
echo ""

# Check Homebrew
if ! command -v brew &>/dev/null; then
  echo "❌ Homebrew not found. Install it first:"
  echo '   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
  exit 1
fi

echo "📦 Installing Bitcoin Core via Homebrew..."
brew install bitcoin

echo ""
echo "📁 Creating node data directories..."
mkdir -p "$HOME/bitcoin/node1"
mkdir -p "$HOME/bitcoin/node2"

echo ""
echo "✅ Installation complete!"
echo "   Binaries: $(which bitcoind)"
echo "   Version:  $(bitcoind --version | head -1)"
echo "   Node dirs: ~/bitcoin/node1  ~/bitcoin/node2"
echo ""
echo "👉 Next step: run ./scripts/start-nodes.sh"
echo ""
