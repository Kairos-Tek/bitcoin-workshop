# Bitcoin Regtest Dashboard

A real-time web dashboard to monitor two Bitcoin nodes running in **regtest** mode. Visualizes blocks, transactions, mempool and network status — all from a single browser tab.

Built as part of the **[AFI Master in Data Science & AI](https://www.afiglobaleducation.com/master-fulltime/master-en-ciencia-de-datos-e-inteligencia-artificial) — Blockchain Analytics** practical workshop.

![Dashboard](<images/bitcoin-dashboard 1.png>)

Both nodes online at block height 182, 1 peer each, with the last 20 blocks listed per node.

---

## What is this?

When developing or testing Bitcoin applications, you typically run local nodes in `regtest` mode — a private blockchain where you control everything. This dashboard gives you a live view of both nodes side by side:

- Block explorer with clickable transactions
- Real-time sync status between nodes
- Mempool monitoring
- Automatic polling (no page refresh needed)

---

## Architecture

```
~/bitcoin/
├── node1/   ← Bitcoin Core node 1  (RPC port 1234)
└── node2/   ← Bitcoin Core node 2  (RPC port 2345)

bitcoin-dashboard/
├── server.py          ← Python HTTP API server (port 18500)
├── index.html         ← Single-page dashboard (served via server.py)
├── start.sh           ← Start dashboard server + open browser
├── stop.sh            ← Stop dashboard server
└── scripts/
    ├── install-mac.sh     ← Install Bitcoin Core on macOS
    ├── install-linux.sh   ← Install Bitcoin Core on Linux / WSL2
    ├── start-nodes.sh     ← Start both bitcoind processes
    ├── stop-nodes.sh      ← Stop both bitcoind processes
    ├── connect-nodes.sh   ← Connect node1 ↔ node2 as peers
    ├── demo-standalone.sh ← Standalone demo: node1 mines independently (nodes isolated)
    └── demo.sh            ← Full demo: wallets, mining, transaction (nodes connected)
```

```
Browser  ──fetch──▶  server.py :18500  ──JSON-RPC──▶  bitcoind :1234
                                       ──JSON-RPC──▶  bitcoind :2345
```

**Why a backend server?** Browsers block direct RPC calls from a web page due to CORS and security policies. `server.py` acts as a local proxy, forwarding requests from the dashboard to each node using cookie-based authentication (`.cookie` files generated automatically by Bitcoin Core).

---

## Requirements

- **macOS** or **Linux** (Ubuntu/Debian, including WSL2 on Windows 11)
- **Bitcoin Core** (installed via the scripts below)
- **Python 3.9+** (no external dependencies — stdlib only)
- **Homebrew** (macOS only — https://brew.sh)

---

## Step-by-step guide

### Step 1 — Install Bitcoin Core

**macOS:**
```bash
chmod +x scripts/install-mac.sh
./scripts/install-mac.sh
```

This runs `brew install bitcoin` and creates the `~/bitcoin/node1` and `~/bitcoin/node2` directories.

**Linux / WSL2:**
```bash
chmod +x scripts/install-linux.sh
./scripts/install-linux.sh
source ~/.bashrc   # reload PATH
```

This downloads Bitcoin Core 27.2, extracts it to `~/bitcoin-core`, adds it to your PATH, and creates the node directories.

> **Manual alternative:** Download the right binary for your platform from https://bitcoin.org/en/download

---

### Step 2 — Start the Bitcoin nodes

```bash
chmod +x scripts/start-nodes.sh
./scripts/start-nodes.sh
```

This starts two `bitcoind` processes in regtest mode, each with its own data directory and ports:

| Node  | P2P port | RPC port | Data directory        |
|-------|----------|----------|-----------------------|
| node1 | 1234     | 1234     | `~/bitcoin/node1`     |
| node2 | 2345     | 2345     | `~/bitcoin/node2`     |

You can verify the nodes are running with:
```bash
bitcoin-cli -regtest -datadir="$HOME/bitcoin/node1" -rpcport=1234 getblockchaininfo
bitcoin-cli -regtest -datadir="$HOME/bitcoin/node2" -rpcport=2345 getblockchaininfo
```

Both should show `"chain": "regtest"` and `"blocks": 0`.

> **Tip:** Open two extra terminal tabs running `tail -f ~/bitcoin/node1/regtest/debug.log` and `tail -f ~/bitcoin/node2/regtest/debug.log` to see live node activity throughout the exercise.

---

### Step 3 — Create wallets

```bash
bitcoin-cli -regtest -datadir=$HOME/bitcoin/node1 -rpcport=1234 createwallet "wallet1"
bitcoin-cli -regtest -datadir=$HOME/bitcoin/node2 -rpcport=2345 createwallet "wallet2"
```

This creates a wallet on each node. The wallet files (including public/private keys) are stored in `~/bitcoin/nodeX/regtest/wallets/walletX/wallet.dat`.

---

### Step 4 — Connect the nodes as peers

```bash
chmod +x scripts/connect-nodes.sh
./scripts/connect-nodes.sh
```

Or manually:
```bash
bitcoin-cli -regtest -datadir=$HOME/bitcoin/node1 -rpcport=1234 addnode "127.0.0.1:2346" "add"
```

Verify node1 sees node2:
```bash
bitcoin-cli -regtest -datadir=$HOME/bitcoin/node1 -rpcport=1234 getpeerinfo
```

> You can use the machine's local network IP instead of `127.0.0.1` to connect nodes running on different machines.

---

### Step 5 — Mine the first block

```bash
bitcoin-cli -regtest -datadir=$HOME/bitcoin/node1 -rpcport=1234 -generate 1
```

Output shows the coinbase address and the block hash:
```json
{
  "address": "bcrt1q0gm0yeguhpa2jm7sy3t2ueh26qnuh872g777r8",
  "blocks": ["74bb1520f204ab70dd49d28691ba82403c791f85588fc809143b146c5067ed1e"]
}
```

Check the balance of node1:
```bash
bitcoin-cli -regtest -datadir=$HOME/bitcoin/node1 -rpcport=1234 getbalance
```

**Result: 0 BTC** — why? The coinbase reward can only be spent after **100 confirmations** (a safety measure against miners who might try to double-spend their reward). Additionally, in regtest the first 150 blocks each carry a reward of **50 BTC**.

---

### Step 6 — Mine 100 more blocks

```bash
bitcoin-cli -regtest -datadir=$HOME/bitcoin/node1 -rpcport=1234 -generate 100
```

Now block 1 has 100 confirmations. Check balance again:
```bash
bitcoin-cli -regtest -datadir=$HOME/bitcoin/node1 -rpcport=1234 getbalance
```

**Result: 50 BTC** ✅

Verify both nodes are in sync (node2 may take a few seconds):
```bash
bitcoin-cli -regtest -datadir="$HOME/bitcoin/node1" -rpcport=1234 getblockchaininfo
bitcoin-cli -regtest -datadir="$HOME/bitcoin/node2" -rpcport=2345 getblockchaininfo
```

Both should show `"blocks": 101`.

---

### Step 7 — Send 1 BTC from node1 to node2

Get a receiving address for node2:
```bash
bitcoin-cli -regtest -datadir=$HOME/bitcoin/node2 -rpcport=2345 loadwallet "wallet2"
NODE2_ADDR=$(bitcoin-cli -regtest -datadir=$HOME/bitcoin/node2 -rpcport=2345 getnewaddress "wallet2")
echo $NODE2_ADDR
```

Send 1 BTC (replace the address with the one you got above):
```bash
bitcoin-cli -regtest -datadir=$HOME/bitcoin/node1 -rpcport=1234 \
  -named sendtoaddress address="$NODE2_ADDR" amount=1 fee_rate=25
```

You'll get back a **transaction ID (txid)**. Check node2's balance — it will still be **0 BTC** because the transaction is unconfirmed (in the mempool, not yet in a block).

---

### Step 8 — Mine a block to confirm the transaction

```bash
bitcoin-cli -regtest -datadir=$HOME/bitcoin/node1 -rpcport=1234 -generate 1
```

Now check balances on both nodes:
```bash
bitcoin-cli -regtest -datadir=$HOME/bitcoin/node1 -rpcport=1234 getbalance
# → 48.99996475 BTC  (50 − 1 sent − fee)

bitcoin-cli -regtest -datadir=$HOME/bitcoin/node2 -rpcport=2345 getbalance
# → 1.00000000 BTC
```

---

### Step 9 — Start the dashboard

```bash
chmod +x start.sh stop.sh
./start.sh
```

This starts `server.py` on port 18500 and opens `http://localhost:18500` in your browser.

![Block detail](<images/bitcoin-dashboard 2.png>)

Block #102 showing two transactions: the **coinbase** (50.00003525 BTC mined reward) and the **1 BTC payment** sent to node2's wallet, with 48.99996475 BTC returned as change.

> **Want to generate this dashboard with AI?** See [`website_prompt.md`](website_prompt.md) for the full prompt used to build it with Claude.

---

### Step 10 — Run the automated demo

Two demo modes are available depending on what you want to demonstrate.

#### Option A — Standalone demo (nodes isolated)

Runs all the exercise steps on **node1 only**, without connecting the nodes as peers. Node2 stays at block height 0 and is unaware of any transactions — even if node1 sends BTC to a node2 address.

```bash
chmod +x scripts/demo-standalone.sh
./scripts/demo-standalone.sh
```

After the demo completes, open the dashboard (`./start.sh`) and compare the two panels side by side: node1 will show 102 blocks and a balance of ~49 BTC, while node2 shows height 0 and 0 BTC — even though node1 already sent it 1 BTC.

Now connect the nodes:

```bash
./scripts/connect-nodes.sh
```

Watch node2 in the dashboard: it will detect the longer chain on node1 and sync automatically, jumping from height 0 to 102 and showing its 1 BTC balance. This illustrates the core principle of Bitcoin's peer-to-peer consensus — nodes always adopt the longest valid chain.

#### Option B — Full demo (nodes connected from the start)

Runs the complete exercise with both nodes connected as peers from step 1. Blocks and transactions propagate in real time as they are mined.

```bash
chmod +x scripts/demo.sh
./scripts/demo.sh
```

---

### Step 11 — Stop everything

```bash
# Stop the dashboard
./stop.sh

# Stop the Bitcoin nodes
./scripts/stop-nodes.sh
```

Or individually:
```bash
bitcoin-cli -regtest -datadir=$HOME/bitcoin/node1 -rpcport=1234 stop
bitcoin-cli -regtest -datadir=$HOME/bitcoin/node2 -rpcport=2345 stop
```

---

## Dashboard features

### Per-node panels
| Feature | Description |
|---|---|
| **Status badge** | Online / Offline indicator |
| **Chain height** | Current block count |
| **Peers** | Number of connected peers |
| **Session blocks** | Blocks mined since dashboard opened |
| **Mempool** | Pending transaction count, refreshed every 10s |
| **Best block hash** | Full hash of the chain tip |

### Block list
- Last 20 blocks, newest first
- Columns: height · hash · timestamp · tx count · size
- **Click any block** to open the detail modal

### Block detail modal
- All block header fields: version, merkle root, bits, nonce, difficulty, weight
- Full transaction list — each transaction expandable showing:
  - All inputs (coinbase or `txid:vout`)
  - All outputs with address and BTC value

### Real-time updates
| Data | Polling interval |
|---|---|
| Node info (height, peers) | Every 3 seconds |
| Block list | Every 5 seconds |
| Mempool | Every 10 seconds |

New blocks flash orange when detected.

### Comparison panel
- Side-by-side table comparing both nodes
- Sync indicator: green if both nodes share the same tip block hash

---

## API endpoints

`server.py` exposes a local JSON API at `http://localhost:18500`:

| Endpoint | Description |
|---|---|
| `GET /` | Serves `index.html` |
| `GET /api/status` | Connection status of both nodes |
| `GET /api/node/{1\|2}/info` | `getblockchaininfo` + `getnetworkinfo` + `getmempoolinfo` |
| `GET /api/node/{1\|2}/blocks` | Last 20 blocks (summary) |
| `GET /api/node/{1\|2}/block/{hash}` | Full block with transactions (verbosity 2) |
| `GET /api/node/{1\|2}/mempool` | Mempool info + raw txid list |

---

## Configuration

Node config is at the top of `server.py`. Change ports or paths here if your setup differs:

```python
NODE_CONFIGS = [
    {"name": "node1", "rpchost": "127.0.0.1", "rpcport": 1234, "datadir": BITCOIN_DIR / "node1"},
    {"name": "node2", "rpchost": "127.0.0.1", "rpcport": 2345, "datadir": BITCOIN_DIR / "node2"},
]
```

Authentication uses Bitcoin Core's auto-generated `.cookie` files — no manual credential setup needed.

---

## Useful references

- [Bitcoin Core API calls list](https://en.bitcoin.it/wiki/Original_Bitcoin_client/API_calls_list)
- [Understanding Bitcoin's on-disk data](https://bitcoindev.network/understanding-the-data/)
- [Bitcoin Core download](https://bitcoin.org/en/download)

---

## Tech stack

| Layer | Tech |
|---|---|
| Bitcoin nodes | Bitcoin Core (regtest) |
| API server | Python 3 stdlib (`http.server`, `urllib`, `json`) |
| Frontend | Vanilla HTML + CSS + JavaScript (no frameworks) |
| Auth | Bitcoin Core cookie auth (`.cookie` file) |

No npm, no pip installs, no bundlers — just `python3` and a browser.

---

## License

[MIT License](https://en.wikipedia.org/wiki/MIT_License) — Copyright © 2026 Jorge Ordovás ([@joobid](https://github.com/joobid) on GitHub · [@joobid](https://x.com/joobid) on X)