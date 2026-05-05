# Bitcoin Regtest Dashboard

A real-time web dashboard to monitor two Bitcoin nodes running in **regtest** mode. Visualizes blocks, transactions, mempool and network status — all from a single browser tab.

Built as part of the **[AFI Master in Data Science & AI](https://www.afiglobaleducation.com/master-fulltime/master-en-ciencia-de-datos-e-inteligencia-artificial) — Blockchain Analytics** practical workshop.

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
    ├── demo-standalone.sh   ← Standalone demo: node1 mines independently (nodes isolated)
    ├── demo-full.sh         ← Full demo: wallets, mining, transaction (nodes connected)
    ├── send-transaction.sh  ← Send N BTC between nodes and confirm in one block
    └── mine-blocks.sh       ← Mine N blocks on a given node
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

> **Tip:** Open two extra terminal tabs running `tail -f ~/bitcoin/node1/regtest/debug.log` and `tail -f ~/bitcoin/node2/regtest/debug.log` to see live node activity throughout the exercise.

---

### Step 3 — Start the dashboard

```bash
chmod +x start.sh stop.sh
./start.sh
```

This starts `server.py` on port 18500 and opens `http://localhost:18500` in your browser.

**Check the initial state in the dashboard:** both nodes should appear online with height 0, 0 peers, mempool empty and wallet balance at 0 BTC. This is the starting point — a clean private blockchain with no activity yet.

> **Want to generate this dashboard with AI?** See [`website_prompt.md`](website_prompt.md) for the full prompt used to build it with Claude.

---

### Step 4 — Run the demo

Two modes are available depending on what you want to demonstrate.

#### Option A — Standalone demo (nodes isolated)

Runs the full exercise on **node1 only**, without connecting the nodes as peers first.

```bash
chmod +x scripts/demo-standalone.sh
./scripts/demo-standalone.sh
```

Once the script finishes, switch to the dashboard and explore:

**Block list:** node1 shows 102 blocks, node2 shows height 0. Use the pagination buttons to scroll back through node1's blocks. Find the last block (height 102) — it contains **2 transactions**: click on it to expand and identify the **coinbase** (the mining reward automatically created in every block) and the **payment transaction** (1 BTC sent to node2's address). Inspect the inputs and outputs of each.

**Wallet balance:** node1 shows ~49 BTC (50 initial − 1 sent − fee). Node2 shows 0 BTC — even though node1 sent it 1 BTC. This is because the two nodes are running completely separate blockchains: node2 has never seen that transaction. They are not yet connected as peers.

**Comparison panel:** the sync indicator will show the nodes as out of sync, with different tip block hashes and different heights.

Now connect the nodes:

```bash
./scripts/connect-nodes.sh
```

Watch the dashboard: once connected, node2 detects that node1 has a longer valid chain and syncs automatically — its height will jump from 0 to 102 and its wallet balance will update to 1 BTC. The comparison panel will turn green once both nodes share the same tip block hash. This illustrates the core principle of Bitcoin's peer-to-peer consensus — **nodes always adopt the longest valid chain**.

![Dashboard](<images/bitcoin-dashboard 1.png>)

#### Option B — Full demo (nodes connected from the start)

Runs the complete exercise with both nodes connected as peers from the beginning. Blocks and transactions propagate in real time as they are mined.

```bash
chmod +x scripts/demo-full.sh
./scripts/demo-full.sh
```

Once the script finishes, switch to the dashboard and explore:

**Comparison panel:** both nodes show the same height and the same tip block hash — the sync indicator is green. This is the expected state when nodes are connected: every mined block propagates to all peers immediately.

**Block list:** find the last block (height 102) — it contains **2 transactions**. Click on it to expand and identify the **coinbase** (the mining reward) and the **payment transaction** (1 BTC sent to node2). Check the outputs of the payment transaction: one output sends 1 BTC to node2's address, and another returns the change (~49 BTC) back to node1.

**Wallet balance:** node1 shows ~49 BTC, node2 shows 1 BTC — both reflecting the confirmed transaction.

---

### Step 4b — Send a transaction manually

Once the nodes have funds (after running either demo), you can send transactions between them at any time:

```bash
chmod +x scripts/send-transaction.sh

# Send 1 BTC from node1 to node2
./scripts/send-transaction.sh 1 1 2

# Send 0.5 BTC from node2 to node1
./scripts/send-transaction.sh 0.5 2 1
```

After the transaction is broadcast (before the confirmation block is mined), check the dashboard: the **mempool counter** will show 1 pending transaction and the **wallet balances** will still reflect the previous state — the transaction exists but has not yet been included in a block.

The script then mines 1 block to confirm the transaction. Switch back to the dashboard and verify:

- The **mempool** is now empty.
- A **new block** has appeared at the top of node1's block list containing 2 transactions: the coinbase and the confirmed payment. Click on it to inspect both.
- The **wallet balances** have updated: the sender's balance has decreased by the sent amount plus the fee, and the receiver's balance has increased accordingly.

---

### Step 4c — Mine blocks manually

Mine a specific number of blocks on any node at any time:

```bash
chmod +x scripts/mine-blocks.sh

# Mine 1 block on node1
./scripts/mine-blocks.sh 1 1

# Mine 100 blocks on node2
./scripts/mine-blocks.sh 100 2
```


---

### Step 5 — Stop everything

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