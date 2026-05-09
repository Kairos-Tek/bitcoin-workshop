#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# Bitcoin Regtest Dashboard — Linux installation
# Works on Ubuntu/Debian (native or WSL2 on Windows 11)
# ─────────────────────────────────────────────────────────────────────────────
set -e

# Check latest version at https://bitcoincore.org/en/download
BITCOIN_VERSION="28.1"

# Auto-detect CPU architecture (x86_64 on standard PCs, aarch64 on ARM/Apple Silicon)
ARCH=$(uname -m)
if [[ "$ARCH" != "x86_64" && "$ARCH" != "aarch64" ]]; then
  echo "❌ Unsupported architecture: $ARCH"
  echo "   This script supports x86_64 (standard PCs) and aarch64 (ARM/Apple Silicon)."
  echo "   Download manually from https://bitcoincore.org/en/download"
  exit 1
fi

TARBALL="bitcoin-${BITCOIN_VERSION}-${ARCH}-linux-gnu.tar.gz"
DOWNLOAD_URL="https://bitcoincore.org/bin/bitcoin-core-${BITCOIN_VERSION}/${TARBALL}"

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║  Bitcoin Core — Linux Installation           ║"
echo "╚══════════════════════════════════════════════╝"
echo ""
echo "  Version:      ${BITCOIN_VERSION}"
echo "  Architecture: ${ARCH}"
echo "  Target:       ${HOME}"
echo ""

# Check for wget
if ! command -v wget &>/dev/null; then
  echo "❌ wget not found. Install it with: sudo apt install wget"
  exit 1
fi

# Skip if already installed
if command -v bitcoind &>/dev/null; then
  EXISTING=$(bitcoind --version 2>/dev/null | head -1)
  echo "ℹ️  Bitcoin Core already in PATH: $EXISTING"
  echo "   Skipping download. Creating node directories..."
  mkdir -p "$HOME/bitcoin/node1" "$HOME/bitcoin/node2"
  echo ""
  echo "✅ Ready! Node dirs: ~/bitcoin/node1  ~/bitcoin/node2"
  echo "👉 Next step: ./scripts/start-nodes.sh"
  echo ""
  exit 0
fi

# Download
echo "⬇️  Downloading Bitcoin Core ${BITCOIN_VERSION} (${ARCH})..."
echo "   From: ${DOWNLOAD_URL}"
cd "$HOME"
wget -q --show-progress "$DOWNLOAD_URL"

# Extract
echo "📦 Extracting..."
tar xf "$TARBALL" -C "$HOME"

# Symlink
echo "🔗 Creating symlink ~/bitcoin-core → bitcoin-${BITCOIN_VERSION}..."
ln -sf "$HOME/bitcoin-${BITCOIN_VERSION}" "$HOME/bitcoin-core"

# Add to PATH in .bashrc / .zshrc
EXPORT_LINE='export PATH=$PATH:$HOME/bitcoin-core/bin'
for RC in "$HOME/.bashrc" "$HOME/.zshrc"; do
  if [ -f "$RC" ] && ! grep -q "bitcoin-core/bin" "$RC"; then
    echo "" >> "$RC"
    echo "# Bitcoin Core" >> "$RC"
    echo "$EXPORT_LINE" >> "$RC"
    echo "  ✅ Added to $RC"
  fi
done
export PATH=$PATH:$HOME/bitcoin-core/bin

# Cleanup tarball
rm -f "$TARBALL"

# Create node directories
echo ""
echo "📁 Creating node data directories..."
mkdir -p "$HOME/bitcoin/node1"
mkdir -p "$HOME/bitcoin/node2"

echo ""
echo "✅ Installation complete!"
echo "   Binaries: $HOME/bitcoin-core/bin/bitcoind"
echo "   Version:  $(bitcoind --version 2>/dev/null | head -1)"
echo "   Node dirs: ~/bitcoin/node1  ~/bitcoin/node2"
echo ""
echo "⚠️  Run this now so the terminal finds the new commands:"
echo ""
echo "     source ~/.bashrc"
echo ""
echo "👉 Then run: ./scripts/start-nodes.sh"
echo ""
