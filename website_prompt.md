# Dashboard Generation Prompt

This is the prompt used to generate this dashboard with **Claude** (Cowork or Claude Code).

---

```
I have two Bitcoin nodes running in regtest mode in the $HOME/bitcoin directory.
I want you to build a complete dashboard to visualize blocks and transactions in real time.

## STEP 1 — Environment exploration (do this BEFORE writing any code)

1. List the contents of ~/bitcoin and understand the structure of the two nodes:
   - Find the directories for each node (node1/ and node2/)
   - Bitcoin Core uses cookie-based authentication by default. Find the .cookie file
     for each node at: ~/bitcoin/node{1,2}/regtest/.cookie
     (format: __cookie__:<password> — use this for Basic auth in RPC calls)
   - Note the RPC ports: node1 uses 1234, node2 uses 2345
   - Verify the nodes are active by running:
     bitcoin-cli -regtest -datadir=$HOME/bitcoin/node1 -rpcport=1234 getblockchaininfo
     bitcoin-cli -regtest -datadir=$HOME/bitcoin/node2 -rpcport=2345 getblockchaininfo

## STEP 2 — Backend: local API server

Create a file `server.py` (Python 3, stdlib only — no external dependencies)
that acts as an HTTP proxy between the dashboard and the nodes:

- Listen on http://localhost:18500
- Expose these JSON endpoints:
  * GET /api/node/{1|2}/info            → getblockchaininfo + getnetworkinfo + getmempoolinfo
  * GET /api/node/{1|2}/blocks?offset=N → 20 blocks starting from tip-N (default 0)
  * GET /api/node/{1|2}/block/{hash}    → getblock <hash> 2 (with full transactions)
  * GET /api/node/{1|2}/mempool         → getmempoolinfo + txids from getrawmempool
  * GET /api/node/{1|2}/balance         → getbalance + first wallet address; auto-loads
                                          wallet if not loaded; returns {balance, address, error}
  * GET /api/status                     → connection status of both nodes (includes cookie_path,
                                          cookie_exists, rpc_error for diagnostics)

- Authentication: read the .cookie file from ~/bitcoin/node{N}/regtest/.cookie on each
  request; refresh automatically on HTTP 401 (cookie regenerates on node restart)
- Each Bitcoin call uses direct HTTP RPC — do NOT use subprocess/bitcoin-cli for the server
- Add CORS headers so the HTML can consume the API
- Handle connection errors gracefully (node down → respond with {error: "..."})
- Use JSON-RPC 1.0 (Bitcoin Core only accepts this version)
- The /api/node/{n}/blocks endpoint must parse the ?offset=N query parameter and return
  {blocks: [...], tip_height: N} — tip_height is needed by the frontend for pagination

## STEP 3 — Frontend: single HTML dashboard

Create a self-contained `index.html` file (HTML + CSS + JS in one file) with:

### Layout
- Dark theme with Bitcoin-inspired colors: orange #f7931a, black, dark grey
- Header with logo/title "Bitcoin Regtest Dashboard" and last-updated timestamp
- Two main columns, one per node, clearly labelled "Node 1" and "Node 2"

### Per-node panel
- Status card: chain height, difficulty, best block hash (truncated),
  connected peers, mempool size
- Visual status indicator (green = online, red = offline) with animated pulse dot
- Counter of blocks mined in the current session

### Per-node wallet info
- Wallet balance (BTC) fetched from /api/node/{1|2}/balance, displayed prominently
  in an orange-tinted row below the stats grid, refreshed every 10 seconds
- Show a "no wallet" message if the node has no wallet loaded

### Block viewer (per node)
- Paginated block list: 20 blocks per page, with "← Older" / "Newer →"
  navigation buttons and a page indicator (e.g. "p. 1 / 6")
- The blocks endpoint accepts an ?offset=N query parameter so the server returns
  the 20 blocks starting from tip - N, enabling backward navigation
- When a new block arrives while the user is browsing an older page, automatically
  reset to page 0 (most recent blocks) and flash the new block orange
- Each row shows: height, hash (first+last 8 chars), human-readable timestamp,
  number of transactions, size in bytes
- Clicking a block → modal with:
  * All block header fields (version, merkle root, bits, nonce, difficulty, weight)
  * Full transaction list — each transaction expandable showing:
    - txid, size, inputs (coinbase label or prev_txid:vout) and outputs (address + BTC value)

### Real-time updates
- Automatic polling every 3 seconds to /api/node/{1|2}/info
- Block polling every 5 seconds
- When a new block appears → orange highlight animation on the new row
- Mempool refreshed every 10 seconds with a badge showing pending tx count

### Bottom panel: comparative view
- Side-by-side table comparing both nodes: height, tip hash, peers, mempool
- Sync indicator: green if both nodes share the same tip block hash, red if diverged

## STEP 4 — Supporting scripts

Create a `scripts/` folder with these bash scripts (compatible with bash 3.2 / macOS):

- `install-mac.sh`     — installs Bitcoin Core via Homebrew; creates ~/bitcoin/node1 and node2
- `install-linux.sh`   — downloads Bitcoin Core 27.2 for Linux/WSL2; adds to PATH
- `start-nodes.sh`     — starts both bitcoind processes in regtest mode:
                          node1: P2P 1235, RPC 1234, datadir ~/bitcoin/node1
                          node2: P2P 2346, RPC 2345, datadir ~/bitcoin/node2
- `stop-nodes.sh`      — stops both nodes gracefully via bitcoin-cli stop
- `connect-nodes.sh`   — connects node1 ↔ node2 as peers via addnode
- `mine-blocks.sh`     — parameters: <num_blocks> <node>; mines N blocks on the given node
- `send-transaction.sh`— parameters: <amount> <source_node> <dest_node>;
                          validates balance, broadcasts tx, shows mempool prompt, mines 1 block
                          to confirm; uses if/else instead of declare -A for bash 3.2 compat
- `demo-standalone.sh` — full exercise on node1 only (nodes not connected as peers):
                          create wallets → mine 101 blocks → send 1 BTC → mine 1 block to confirm
- `demo-full.sh`       — same exercise with both nodes connected from the start

## STEP 5 — Launch scripts

Create a `start-dashboard.sh` file that:
1. Starts server.py in the background (saving the PID to server.pid)
2. Opens the dashboard at http://localhost:18500 in the default browser
3. Shows the server URL and how to stop it in the console

And a `stop-dashboard.sh` that reads server.pid and kills the process.

## STEP 6 — Verification

Before finishing:
1. Start server.py and verify it responds: curl http://localhost:18500/api/status
2. Confirm that at least one of the endpoints /api/node/1/blocks returns real data
3. If a node is not running, document in README.md how to start it

## Final deliverables (save to the project folder)
- index.html
- server.py
- start-dashboard.sh / stop-dashboard.sh
- README.md (step-by-step guide: install → start nodes → start dashboard → run demo → stop)
- scripts/ (all 9 bash scripts listed above)
- website_prompt.md (this prompt, for reproducibility)

## Technical constraints
- server.py: Python 3 stdlib only (http.server, urllib, json, base64, pathlib)
- index.html: vanilla JS + CSS, no external frameworks, no npm, no bundlers
- All bash scripts: bash 3.2 compatible (macOS default — no declare -A associative arrays)
- Do not use localStorage for node data (use in-memory JS variables, refresh with polling)
- Compatibility: macOS/Linux (including WSL2), python3 in PATH, bitcoin-cli in PATH
```

---

> This dashboard was built interactively with Claude Cowork.
> Repository: https://github.com/joobid/bitcoin-dashboard
