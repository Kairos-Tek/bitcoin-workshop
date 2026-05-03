#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# Bitcoin Regtest Dashboard — Linux installation
# Works on Ubuntu/Debian (native or WSL2 on Windows 11)
# ─────────────────────────────────────────────────────────────────────────────
set -e

# Check latest version at https://bitcoin.org/en/download
BITCOIN_VERSION="27.2"
ARCH="x86_64"
TARBALL="bitcoin-${BITCOIN_VERSION}-${ARCH}-linux-gnu.tar.gz"
DOWNLOAD_URL="https://bitcoin.org/bin/bitcoin-core-${BITCOIN_VERSION}/${TARBALL}"

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║  Bitcoin Core — Linux Installation           ║"
echo "╚══════════════════════════════════════════════╝"
echo ""
echo "  Version: ${BITCOIN_VERSION}"
echo "  Target:  ${HOME}"
echo ""

# Download
echo "⬇️  Downloading Bitcoin Core ${BITCOIN_VERSION}..."
cd "$HOME"
wget -q --show-progress "$DOWNLOAD_URL"

# Extract
echo "📦 Extracting..."
tar xvf "$TARBALL" -C "$HOME" > /dev/null

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
    echo "  Added to $RC"
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
echo "   Binaries: $(which bitcoind 2>/dev/null || echo $HOME/bitcoin-core/bin/bitcoind)"
echo "   Version:  $(bitcoind --version 2>/dev/null | head -1 || echo 'restart shell to verify')"
echo "   Node dirs: ~/bitcoin/node1  ~/bitcoin/node2"
echo ""
echo "⚠️  Restart your shell or run:  source ~/.bashrc"
echo "👉 Next step: run ./scripts/start-nodes.sh"
echo ""
