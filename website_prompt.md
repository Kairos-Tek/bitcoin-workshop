# Dashboard Generation Prompt

This is the prompt used to generate this dashboard with **Claude** (Cowork or Claude Code).

---

```
I have two Bitcoin nodes running in regtest mode in the $HOME/bitcoin directory.
I want you to build a complete dashboard to visualize blocks and transactions in real time.

## STEP 1 — Environment exploration (do this BEFORE writing any code)

1. List the contents of ~/bitcoin and understand the structure of the two nodes:
   - Find the directories for each node (node1/ and node2/)
   - Read the bitcoin.conf file of each node to extract:
     * rpcuser, rpcpassword, rpcport
     * datadir, port (P2P)
     * any other relevant configuration
   - Verify the nodes are active by running:
     bitcoin-cli -conf=<path_conf_node1> getblockchaininfo
     bitcoin-cli -conf=<path_conf_node2> getblockchaininfo
   - Note the RPC port of each node

## STEP 2 — Backend: local API server

Create a file `server.py` (Python 3, stdlib only — no external dependencies)
that acts as an HTTP proxy between the dashboard and the nodes:

- Listen on http://localhost:18500
- Expose these JSON endpoints:
  * GET /api/node/{1|2}/info         → getblockchaininfo + getnetworkinfo
  * GET /api/node/{1|2}/blocks       → last 20 blocks (hash, height, time, txcount, size)
  * GET /api/node/{1|2}/block/{hash} → getblock <hash> 2 (with full transactions)
  * GET /api/node/{1|2}/mempool      → getmempoolinfo + txids from mempool
  * GET /api/status                  → connection status of both nodes

- Each Bitcoin call uses direct HTTP RPC (requests to http://127.0.0.1:<rpcport>/
  with basic auth) — do NOT use subprocess/bitcoin-cli for the server
- Add CORS headers so the HTML can consume the API
- Handle connection errors gracefully (node down → respond with {error: "..."})
- Use JSON-RPC 1.0 (Bitcoin Core only accepts this version)

## STEP 3 — Frontend: single HTML dashboard

Create a self-contained `index.html` file (HTML + CSS + JS in one file) with:

### Layout
- Dark theme with Bitcoin-inspired colors: orange #f7931a, black, dark grey
- Header with logo/title "Bitcoin Regtest Dashboard" and last-updated timestamp
- Two main columns, one per node, clearly labelled "Node 1" and "Node 2"

### Per-node panel
- Status card: chain height, difficulty, best block hash (truncated),
  connected peers, mempool size
- Visual status indicator (green = online, red = offline)
- Counter of blocks mined in the current session

### Block viewer (per node)
- List of the last 20 blocks in descending order
- Each row shows: height, hash (first+last 8 chars), human-readable timestamp,
  number of transactions, size in bytes
- Clicking a block → side panel/modal with:
  * All block fields (version, merkleroot, bits, nonce, etc.)
  * List of transactions in the block, each expandable showing:
    - txid, size, inputs (coinbase or prev_txid:vout + value) and outputs (address + BTC value)

### Real-time updates
- Automatic polling every 3 seconds to /api/node/{1|2}/info
- Block polling every 5 seconds
- When a new block appears → orange highlight animation on the new row
- Mempool refreshed every 10 seconds with a badge showing the number of pending txs

### Bottom panel: comparative view
- Side-by-side table comparing both nodes: height, tip hash, peers, mempool
- Indicator of whether the nodes are in sync (same tip block hash)

## STEP 4 — Launch script

Create a `start.sh` file that:
1. Starts server.py in the background (saving the PID to server.pid)
2. Opens the dashboard at http://localhost:18500 in the default browser
3. Shows the server URL and how to stop it in the console

And a `stop.sh` that reads server.pid and kills the process.

## STEP 5 — Verification

Before finishing:
1. Start server.py and verify it responds: curl http://localhost:18500/api/status
2. Confirm that at least one of the endpoints /api/node/1/blocks returns real data
3. If a node is not running, document in README.md how to start it:
   bitcoind -conf=<path> -daemon

## Final deliverables (save to the project folder)
- index.html
- server.py
- start.sh / stop.sh
- README.md (usage instructions, ports, how to mine test blocks)

## Technical constraints
- server.py: Python 3 stdlib only (http.server, urllib, json, base64, threading)
- index.html: vanilla JS + CSS, no external frameworks, no npm, no bundlers
- Do not use localStorage for node data (use in-memory variables, refresh with polling)
- Compatibility: macOS/Linux, python3 in PATH, bitcoin-cli in PATH or /usr/local/bin
```

---

> This dashboard was built interactively with Claude Cowork.
> Repository: https://github.com/joobid/bitcoin-dashboard
