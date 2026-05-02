# Bitcoin Regtest Dashboard

A real-time web dashboard to monitor two Bitcoin nodes running in **regtest** mode. Visualizes blocks, transactions, mempool and network status — all from a single browser tab.

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
├── nodo1/   ← Bitcoin Core node 1  (RPC port 1234)
└── nodo2/   ← Bitcoin Core node 2  (RPC port 2345)

~/claude/bitcoin-dashboard/
├── server.py    ← Python HTTP API server (port 18500)
├── index.html   ← Single-page dashboard (served via server.py)
├── start.sh     ← Start server + open browser
└── stop.sh      ← Stop server
```

```
Browser  ──fetch──▶  server.py :18500  ──JSON-RPC──▶  bitcoind :1234
                                       ──JSON-RPC──▶  bitcoind :2345
```

**Why a backend server?** Browsers block direct RPC calls from a web page due to CORS and security policies. `server.py` acts as a local proxy, forwarding requests from the dashboard to each node using cookie-based authentication (`.cookie` files generated automatically by Bitcoin Core).

---

## Requirements

- **macOS** (tested on macOS Sequoia)
- **Bitcoin Core** installed (`bitcoind` and `bitcoin-cli` in PATH)
- **Python 3.9+** (no external dependencies — stdlib only)
- Two `bitcoind` nodes running in regtest mode

---

## Node setup

If you don't have the nodes running yet, start them with:

```bash
# Node 1
bitcoind \
  -datadir=$HOME/bitcoin/nodo1 \
  -regtest \
  -port=1234 \
  -rpcport=1234 \
  -bind=127.0.0.1:1235=onion \
  -daemon

# Node 2
bitcoind \
  -datadir=$HOME/bitcoin/nodo2 \
  -regtest \
  -port=2345 \
  -rpcport=2345 \
  -bind=127.0.0.1:2346=onion \
  -daemon
```

Connect them to each other:
```bash
bitcoin-cli -datadir=$HOME/bitcoin/nodo2 -regtest addnode "127.0.0.1:1234" "add"
```

---

## Running the dashboard

```bash
git clone https://github.com/joobid/bitcoin-dashboard.git
cd bitcoin-dashboard

chmod +x start.sh stop.sh
./start.sh
```

This will:
1. Start `server.py` in the background on port `18500`
2. Open `http://localhost:18500` in your default browser
3. Save the server PID to `server.pid` for clean shutdown

To stop:
```bash
./stop.sh
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

![Block detail](<images/bitcoin-dashboard 2.png>)

Block #102 containing two transactions: the **coinbase** (50.00003525 BTC mined reward) and a **1 BTC payment** sent to `bcrt1qs4gat...ewdnker`, with 48.99996475 BTC returned as change.

The modal shows all block header fields (version, merkle root, bits, nonce, difficulty, weight) and every transaction fully expanded with inputs and outputs.

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

Node config is hardcoded in `server.py` (top of file). Change ports or paths here if your setup differs:

```python
NODE_CONFIGS = [
    {"name": "nodo1", "rpchost": "127.0.0.1", "rpcport": 1234, "datadir": BITCOIN_DIR / "nodo1"},
    {"name": "nodo2", "rpchost": "127.0.0.1", "rpcport": 2345, "datadir": BITCOIN_DIR / "nodo2"},
]
```

Authentication uses Bitcoin Core's auto-generated `.cookie` files — no manual credential setup needed.

---

## Mining test blocks

```bash
# Create a wallet on node 1
bitcoin-cli -datadir=$HOME/bitcoin/nodo1 -regtest createwallet "test"

# Get a receiving address
ADDR=$(bitcoin-cli -datadir=$HOME/bitcoin/nodo1 -regtest getnewaddress)

# Mine 10 blocks
bitcoin-cli -datadir=$HOME/bitcoin/nodo1 -regtest generatetoaddress 10 $ADDR

# Send a transaction
bitcoin-cli -datadir=$HOME/bitcoin/nodo1 -regtest sendtoaddress <destination> 1.5
```

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

MIT
