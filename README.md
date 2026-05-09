# Bitcoin Regtest Workshop

A hands-on practical workshop to explore Bitcoin internals: two local Bitcoin nodes in **regtest** mode, a live dashboard, and a full set of demo scripts. Mine blocks, send transactions, watch the mempool, and see Bitcoin's consensus rule in action — all without real money or internet.

Developed by **[Kairos Tek](https://kairos-tek.com)**.

---

## 🖥 Workshop presentation

The file [`presentation/workshop.html`](presentation/workshop.html) is an interactive bilingual slide deck (English / Spanish) designed for use during the live session. It covers the full exercise — from setup to demos to key concepts — with screenshots from the dashboard at each step.

Open it directly in your browser before starting the exercise:

```bash
open presentation/workshop.html        # macOS
start presentation/workshop.html       # Windows (run from the project folder)
xdg-open presentation/workshop.html    # Linux
```

Or just double-click the file from your file manager.

**How to navigate:**
- `←` / `→` arrow keys (or the on-screen buttons) to move between slides
- `F` to enter fullscreen
- `EN` / `ES` buttons to switch language at any time
- **Mode A** — each demo step is its own slide, ideal for following along live
- **Mode B** — all steps shown at once on a single slide, useful for reference

> The presentation is self-contained — no internet required once you have the project folder.

---

## Prerequisites — set up your environment from scratch

Before you can run anything, you need a few basic tools. Follow the section that matches your operating system. If you already have everything installed, jump straight to [Step-by-step guide](#step-by-step-guide).

---

### 🪟 Windows — install WSL2 first

This project does **not** work in PowerShell or the Windows Command Prompt. You need WSL2 (Windows Subsystem for Linux), which gives you a real Ubuntu terminal inside Windows. It is free and officially supported by Microsoft.

**Step 1 — Enable WSL2**

Open PowerShell **as Administrator** (right-click the Start menu → "Windows PowerShell (Admin)") and run:

```powershell
wsl --install
```

This installs WSL2 and Ubuntu automatically. When it finishes, **restart your computer**.

> If you already have WSL but an older version, run `wsl --update` to upgrade to WSL2.

**Step 2 — Open Ubuntu**

After restarting, search for **"Ubuntu"** in the Start menu and open it. The first time it launches it will ask you to create a username and password — this is your Linux user (it does not need to match your Windows account). Choose anything and remember the password; you will need it when commands ask for `sudo`.

**Step 3 — Update the package list**

Inside the Ubuntu terminal, run:

```bash
sudo apt update && sudo apt upgrade -y
```

> `sudo` means "run as administrator". It will ask for the password you just created.

From now on, **every command in this guide must be run inside this Ubuntu terminal** — not in PowerShell or CMD.

---

### 🍎 macOS — install Homebrew, Git and Python

**Step 1 — Open the terminal**

Press **⌘ Space**, type `Terminal`, and press Enter.

**Step 2 — Install Homebrew** (macOS package manager)

Paste this into the terminal and press Enter:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

The script will ask for your Mac password and may install the Xcode Command Line Tools (which includes `git`). Let it do so — this is normal and takes a few minutes. Follow any on-screen instructions to add Homebrew to your PATH at the end.

**Step 3 — Verify Git is available**

Git is included with the Xcode tools installed in the previous step. Check it works:

```bash
git --version
```

You should see something like `git version 2.x.x`. If not, run `brew install git`.

**Step 4 — Install Python 3**

```bash
brew install python@3.11
```

Verify it installed correctly:

```bash
python3 --version
```

You should see `Python 3.11.x` (any 3.9 or later version works).

---

### 🐧 Linux / WSL2 (Ubuntu or Debian) — install Git, Python and tools

If you are on Windows, complete the WSL2 section above first, then come back here and run these commands inside your Ubuntu terminal.

**Step 1 — Install Git, curl and wget**

```bash
sudo apt update
sudo apt install -y git curl wget
```

Verify:

```bash
git --version
```

**Step 2 — Install Python 3**

```bash
sudo apt install -y python3
```

Verify:

```bash
python3 --version
```

You should see `Python 3.10.x` or later (any 3.9+ version works).

**Step 3 (WSL2 only) — Install wslu so the dashboard opens in your browser**

```bash
sudo apt install -y wslu
```

`wslu` is a small package that lets WSL2 open URLs in your Windows browser. Without it, the dashboard server starts fine but the browser won't open automatically — you would have to open it by hand.

> **Not on WSL2?** Skip this step if you are on a native Linux machine.

---

### 📥 Get the project code

Once your environment is ready, clone this repository to your computer. Choose a location — your home folder is a good default:

```bash
cd ~
git clone https://github.com/Kairos-Tek/bitcoin-workshop.git
cd bitcoin-workshop
```

> `cd` means "change directory" — it moves you into a folder. After the two commands above, your terminal is inside the `bitcoin-workshop` folder and ready to run the scripts below.

Verify that the clone worked — you should see these files:

```bash
ls
# index.html  server.py  scripts/  start-dashboard.sh  stop-dashboard.sh  ...
```

---

## What is this?

When developing or testing Bitcoin applications, you typically run local nodes in `regtest` mode — a private blockchain where you control everything. This project gives you two things:

**A live dashboard** that monitors both nodes side by side: block explorer with clickable transactions, wallet balances, mempool monitoring, paginated block history, and real-time sync status — all updated automatically without page refresh.

**A set of bash scripts** to install Bitcoin Core, start and connect the nodes, mine blocks, send transactions between wallets, and run two end-to-end demo scenarios:

- **Standalone demo** — node1 mines independently while node2 stays isolated. After running the demo you can see both nodes on completely separate chains (different heights, different tip hashes, different balances). Then you connect them as peers and watch node2 sync automatically, adopting node1's longer chain — a direct illustration of Bitcoin's consensus rule: *nodes always adopt the longest valid chain*.

- **Full demo** — both nodes are connected from the start. Every mined block propagates to both peers in real time, so both nodes stay in sync throughout. At the end you can inspect the last block containing two transactions: the coinbase (mining reward) and the payment from node1 to node2, with its change output back to node1.

---

## Architecture

```
~/bitcoin/
├── node1/   ← Bitcoin Core node 1  (RPC port 1234)
└── node2/   ← Bitcoin Core node 2  (RPC port 2345)

bitcoin-workshop/
├── server.py              ← Python HTTP API server (port 18500)
├── index.html             ← Single-page dashboard (served via server.py)
├── diagnose.py            ← Debug utility for node connectivity
├── start-dashboard.sh     ← Start dashboard server + open browser
├── stop-dashboard.sh      ← Stop dashboard server
├── presentation/          ← Instructor slide deck (open in browser before class)
│   ├── workshop.html        ← Interactive bilingual presentation (EN/ES)
│   ├── images/              ← Dashboard screenshots used in slides
│   └── logos/               ← Kairos Tek brand assets
└── scripts/
    ├── install-mac.sh       ← Install Bitcoin Core on macOS
    ├── install-linux.sh     ← Install Bitcoin Core on Linux / WSL2
    ├── start-nodes.sh       ← Start both bitcoind processes
    ├── stop-nodes.sh        ← Stop both bitcoind processes
    ├── connect-nodes.sh     ← Connect node1 ↔ node2 as peers
    ├── demo-standalone.sh   ← Demo A: node1 mines independently (nodes isolated)
    ├── demo-full.sh         ← Demo B: wallets, mining, transaction (nodes connected)
    ├── send-transaction.sh  ← Send N BTC between nodes (broadcast only)
    ├── mine-blocks.sh       ← Mine N blocks on a given node
    └── reset.sh             ← Reset nodes to a clean state (start from scratch)
```

```
Browser  ──fetch──▶  server.py :18500  ──JSON-RPC──▶  bitcoind :1234
                                       ──JSON-RPC──▶  bitcoind :2345
```

**Why a backend server?** Browsers block direct RPC calls from a web page due to CORS and security policies. `server.py` acts as a local proxy, forwarding requests from the dashboard to each node using cookie-based authentication (`.cookie` files generated automatically by Bitcoin Core).

---

## Step-by-step guide

Start by making all scripts executable — run this once from the project folder:

```bash
chmod +x start-dashboard.sh stop-dashboard.sh scripts/*.sh
```

---

### Step 1 — Install Bitcoin Core

**macOS:**
```bash
./scripts/install-mac.sh
```

This runs `brew install bitcoin` and creates the `~/bitcoin/node1` and `~/bitcoin/node2` directories.

**Linux / WSL2:**
```bash
./scripts/install-linux.sh
source ~/.bashrc   # reload PATH
```

This downloads Bitcoin Core 27.2, extracts it to `~/bitcoin-core`, adds it to your PATH, and creates the node directories.

> **Manual alternative:** Download the right binary for your platform from https://bitcoin.org/en/download

---

### Step 2 — Start the Bitcoin nodes

```bash
./scripts/start-nodes.sh
```

This starts two `bitcoind` processes in regtest mode, each with its own data directory and ports:

| Node  | P2P port | RPC port | Data directory        |
|-------|----------|----------|-----------------------|
| node1 | 1235     | 1234     | `~/bitcoin/node1`     |
| node2 | 2346     | 2345     | `~/bitcoin/node2`     |

> **Tip:** Open two extra terminal tabs running `tail -f ~/bitcoin/node1/regtest/debug.log` and `tail -f ~/bitcoin/node2/regtest/debug.log` to see live node activity throughout the exercise.

---

### Step 3 — Start the dashboard

```bash
./start-dashboard.sh
```

This starts `server.py` on port 18500 and opens `http://localhost:18500` in your browser.

> **Linux / WSL2:** the browser may not open automatically. If it doesn't, open your browser manually and go to **http://localhost:18500**. If you installed `wslu` (see Prerequisites), it will open automatically on the Windows side.

**Check the initial state in the dashboard:** both nodes should appear online with height 0, 0 peers, mempool empty and wallet balance at 0 BTC. This is the starting point — a clean private blockchain with no activity yet.

![Dashboard](images/dashboard-initial-state.png)

> **Want to generate this dashboard with AI?** See [`website_prompt.md`](website_prompt.md) for the full prompt used to build it with Claude.

---

### Step 4 — Run the demo

Two modes are available depending on what you want to demonstrate.

#### Option A — Standalone demo (nodes isolated)

Runs the full exercise on **node1 only**, without connecting the nodes as peers first.

```bash
./scripts/demo-standalone.sh
```

The script runs automatically — no need to type any commands while it runs. It **pauses at two points** for you to explore the dashboard.

**First pause — before the transaction (101 blocks mined):**

The script stops after mining 101 blocks and asks you to check the dashboard. Switch over and verify:

![Dashboard](images/standalone-before-send.png)

- node1 shows **101 blocks** mined; node2 shows **height 0** — it has never received any blocks
- Wallet balance: node1 shows **50 BTC**, node2 shows **0 BTC**
- Mempool: **0 pending transactions** on both nodes — nothing has been sent yet
- Comparison panel (bottom): nodes are **OUT OF SYNC** — different heights, different tip hashes, sync indicator red — the nodes have never been connected as peers

Press Enter in the terminal to send the transaction.

**Second pause — transaction in the mempool:**

The script broadcasts 1 BTC from node1 to node2, then pauses again. Switch to the dashboard and check:

![Dashboard](images/standalone-mempool-pending.png)

- The **mempool counter** on node1 shows **1 pending transaction**; node2 shows **0** — it has not seen the transaction because the nodes are not connected
- **Wallet balances have not changed yet** — the transaction exists but has not been confirmed
- node2 still shows height 0

Press Enter in the terminal when ready to mine the confirmation block.

**After the script finishes:**

The script mines 1 block and shows the final balances in the terminal. Switch to the dashboard and verify:

![Dashboard](images/standalone-after-confirmation.png)

- Mempool is now **empty** (0 pending transactions)
- A new block has appeared at the top of node1's block list at height **102** with **2 transactions** — click on it to see the **coinbase** (block reward) and the **1 BTC payment** from node1 to node2
- Wallet balances: node1 shows **~49 BTC** (50 − 1 sent − fee), node2 still shows **0 BTC** — it has received nothing because the nodes are not connected
- Comparison panel: still **OUT OF SYNC** — node2 remains at height 0

**Connecting the nodes (the key moment):**

Now run:

```bash
./scripts/connect-nodes.sh
```

Watch the dashboard — within a few seconds you will see node2 sync automatically:

![Dashboard](images/standalone-nodes-synced.png)

- node2's height **jumps from 0 to 102** — it has adopted node1's longer chain in full
- Both nodes show **1 peer** (each other)
- node2's wallet balance updates to **1 BTC** — it has now processed the transaction that node1 broadcast earlier
- Both nodes show the **same block list** with identical hashes and the same block #102 with 2 transactions at the top
- Comparison panel: sync indicator turns **green** — both nodes share the same tip block hash

This is Bitcoin's core consensus rule in action: **nodes always adopt the longest valid chain**. node2 had no choice — when it connected to node1 and discovered a chain 102 blocks longer than its own (which had 0), it discarded its state and downloaded node1's entire chain.

---

#### Option B — Full demo (nodes connected from the start)

Runs the complete exercise with both nodes connected as peers from the beginning. Every block mined on node1 propagates to node2 in real time.

```bash
./scripts/demo-full.sh
```

The script runs automatically and **pauses once** — when the transaction is in the mempool — for you to explore the dashboard.

**Pause — transaction in the mempool:**

The script broadcasts 1 BTC from node1 to node2, then pauses. Switch to the dashboard and check:

![Dashboard](images/full-demo-mempool-pending.png)

- The **mempool counter** shows **1 pending transaction on both nodes** — unlike the standalone demo, node2 is connected and receives the transaction immediately
- **Wallet balances have not changed yet** — the transaction has not been confirmed
- Both nodes show the same height (**101 blocks**) and the same tip hash

Press Enter in the terminal when ready to mine the confirmation block.

**After the script finishes:**

The script mines 1 block and shows the final balances. Switch to the dashboard and verify:

![Dashboard](images/full-demo-confirmed.png)

- Mempool is now **empty** on both nodes
- Both nodes show **102 blocks** and the same tip hash — the sync indicator is **green**
- Wallet balances: node1 shows **~49 BTC**, node2 shows **1 BTC**

Find the block at height **102** in node1's block list — it shows **2 transactions** (TXS column). Click on it to open the block detail:

![Dashboard](images/block-detail-two-transactions.png)

The modal shows all block header fields and both transactions: the **coinbase** (the mining reward created automatically in every block) and the **payment** (1 BTC sent to node2's address, with the change returning to node1). Expand each transaction to inspect its inputs and outputs.

**Comparison panel:** both nodes show the same height and the same tip block hash — the sync indicator is green. Every block propagated to both peers immediately throughout the demo.

---

### Step 4b — Send a transaction manually

Once the nodes have funds (after running either demo), you can send transactions between them at any time.

**Phase 1 — Broadcast one or more transactions**

```bash
# Send 1 BTC from node1 to node2
./scripts/send-transaction.sh 1 1 2

# Send 0.5 BTC from node2 to node1
./scripts/send-transaction.sh 0.5 2 1
```

The script broadcasts the transaction and then **pauses**, waiting for you to press Enter. While it waits, switch to the dashboard and check:

- The **mempool counter** shows the pending transaction.
- The **wallet balances** have not changed yet — the transaction exists in the mempool but has not been included in any block.

This is the unconfirmed state: the transaction is known to the network but not yet final.

You can **send multiple transactions before mining** — run the script again with a different amount or direction and watch the mempool counter grow. Each transaction will appear in the mempool independently, and all of them will be picked up in the next block you mine.

When you are done exploring, press Enter in the terminal. The script will remind you how to mine and exit.

**Phase 2 — Mine a block whenever you are ready**

```bash
./scripts/mine-blocks.sh 1 1
```

You decide when to mine. There is no rush — the transactions will wait in the mempool until a block is produced.

**Phase 3 — Verify in the dashboard**

Switch back to the dashboard and check:

- The **mempool** is now empty — all pending transactions have been picked up by the miner.
- A **new block** has appeared at the top of node1's block list. Click on it to expand: it contains the coinbase (mining reward) plus one entry per confirmed transaction. Inspect the inputs and outputs of each.
- The **wallet balances** have updated to reflect all confirmed transactions.

---

### Step 5 — Stop everything

```bash
# Stop the dashboard
./stop-dashboard.sh

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
| `GET /api/node/{1\|2}/balance` | Wallet balance + receive address |
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

## Frequently asked questions & common errors

### Prerequisites & getting started

**"I get `No such file or directory` when running the `chmod` command"**

You are running the command from the wrong folder. The terminal must be inside the `bitcoin-workshop` directory. Run `pwd` to see where you are, then navigate there:

```bash
cd ~/bitcoin-workshop
chmod +x start-dashboard.sh stop-dashboard.sh scripts/*.sh
```

**"What does `./` mean before a script name?"**

It tells the terminal to run the script located in the current folder. Without it, the terminal searches only system-wide locations and won't find it. Always include `./` when running scripts from this project.

**"I get `Permission denied` when running a script"**

The script is not marked as executable. Run the `chmod` command once from the project folder:

```bash
chmod +x start-dashboard.sh stop-dashboard.sh scripts/*.sh
```

**"I'm on Windows — can I follow this guide?"**

Only through WSL2 (Windows Subsystem for Linux 2). Follow the **🪟 Windows** section at the top of this guide — it installs Ubuntu inside Windows. Native terminals (PowerShell, CMD) are not supported.

**"The `git clone` command says `git: command not found`"**

Git is not installed. Follow the Prerequisites section for your OS to install it before cloning.

---

### Step 1 — Installation

**"I get `brew: command not found` when running `install-mac.sh`"**

Homebrew is not installed. Go to https://brew.sh, copy the one-line command shown there, paste it into your terminal, and press Enter. Once Homebrew finishes, run `./scripts/install-mac.sh` again.

**"The install script says `Warning: bitcoin X.X is already installed` — did it work?"**

Yes. Bitcoin Core was already installed from a previous session. The script skips the download and creates the node directories if they don't exist. Continue to Step 2.

**"On Linux/WSL2, `bitcoind` is not found after running `install-linux.sh`"**

The PATH was updated in `~/.bashrc` but the current terminal doesn't know yet. Run:

```bash
source ~/.bashrc
```

Then verify with `bitcoind --version`. If you open a new terminal in the future, it will load automatically. You only need `source ~/.bashrc` once per terminal session after a fresh install.

**"I get `Exec format error` when running `bitcoind`"**

The downloaded binary doesn't match your computer's CPU architecture. This can happen on ARM-based machines (some newer laptops, Apple Silicon Macs). The install script now detects the architecture automatically — if you still see this error, you may have an old version of the script. Pull the latest version with `git pull` and run it again.

**"The download gets stuck or fails with a network error"**

Check that you have internet access. The script downloads from `bitcoincore.org` — if that domain is blocked on your network, download the file manually from https://bitcoincore.org/en/download, place the `.tar.gz` in your home folder, and run the install script again (it will detect that the file already exists).

---

### Step 2 — Starting the nodes

**"I get `bitcoind: command not found` when running `start-nodes.sh`"**

Bitcoin Core is not in your PATH. On macOS run Step 1 first. On Linux/WSL2 run `source ~/.bashrc` and try again. Verify with `bitcoind --version`.

**"The script says `⚠️ node1 already running — skipping` — is that a problem?"**

No — the node was already running from a previous session and was detected correctly. Continue to Step 3.

**"The script gets stuck on `Waiting for nodes to be ready...`"**

The nodes failed to start. Press Ctrl+C, then check whether bitcoind is actually running:

```bash
ps aux | grep bitcoind
```

If no processes appear, check the log for the error:

```bash
tail -20 ~/bitcoin/node1/regtest/debug.log
```

**"I see `bind: Address already in use` in the output or logs"**

A previous bitcoind process is still holding the ports. Stop it and restart:

```bash
./scripts/stop-nodes.sh
sleep 3
./scripts/start-nodes.sh
```

---

### Step 3 — Dashboard

**"I ran `./start-dashboard.sh` but the browser didn't open"**

On Linux or WSL2 the automatic browser opening depends on your setup. If the browser doesn't open, go to **http://localhost:18500** in your browser manually — the server is already running. On WSL2, installing `wslu` (`sudo apt install wslu`) enables automatic browser opening in future sessions.

**"I get `curl: command not found` when running `start-dashboard.sh`"**

Install curl:

```bash
sudo apt install curl   # Linux / WSL2
```

On macOS, curl is pre-installed — if it's missing, run `brew install curl`.

**"The dashboard shows both nodes as OFFLINE"**

The Bitcoin nodes are not running. Run `./scripts/start-nodes.sh` and wait for "Both nodes ready!". The dashboard polls every 3 seconds and will update automatically once the nodes are up — no need to refresh the page.

**"I get `Address already in use` when starting the dashboard"**

A previous server is still running on port 18500. Stop it first:

```bash
./stop-dashboard.sh
```

Then start again. If `stop-dashboard.sh` says no PID file was found, kill the process directly:

```bash
pkill -f server.py
./start-dashboard.sh
```

**"The wallet balance shows `—`"**

No wallet exists yet. Wallets are created automatically when you run a demo script (Step 4). This is expected before any demo has been run.

**"Node 1 shows height 0 and 0 BTC — is something wrong?"**

No. A freshly started regtest node has no blocks and no funds — that is the correct starting state. Run a demo (Step 4) to mine blocks and generate activity.

**"The data on the dashboard looks frozen"**

Click the **↻ Refresh** button in the top-right corner to force an immediate update of all panels. If the data is still stale after clicking it, check that the terminal running `./start-dashboard.sh` is still active and hasn't exited.

---

### Step 4 — Demos

**"The demo script fails immediately with `Connection refused`"**

The nodes are not running. Run `./scripts/start-nodes.sh` and wait for the "Both nodes ready!" message before running the demo.

**"The demo says `wallet1 already exists` — did something go wrong?"**

No. This happens when you run the demo a second time. The script detects the existing wallet and continues normally. If you want a completely clean start, use the reset script:

```bash
./scripts/reset.sh
./scripts/start-nodes.sh
```

**"I ran `mine-blocks.sh` directly and got an error about `No wallet is loaded`"**

`mine-blocks.sh` now creates a wallet automatically if one doesn't exist. If you see this error, you may have an older version of the script. Run `git pull` to get the latest version.

**"After the standalone demo, node2 shows 0 BTC — but node1 sent it 1 BTC"**

This is the key insight of the standalone demo — it is intentional. The two nodes are running completely separate blockchains because they were never connected as peers. Node2 never received the transaction. To complete the exercise:

```bash
./scripts/connect-nodes.sh
```

Watch the dashboard: node2 will detect that node1 has a longer chain and sync automatically — its height jumps to match node1's and its balance updates to 1 BTC. This is Bitcoin's core consensus rule in action: **nodes always adopt the longest valid chain**.

**"After connecting the nodes, node2 still shows height 0"**

Sync takes a few seconds. The dashboard refreshes every 3 seconds — wait up to 10 seconds. If nothing changes, click **↻ Refresh**. If it still shows 0 after 30 seconds, run `./scripts/connect-nodes.sh` again — occasionally the first `addnode` call needs a retry.

**"After the standalone demo, node2 shows 0 peers even after connecting"**

Peer count refreshes every 3 seconds. If it stays at 0 after 10 seconds, run `./scripts/connect-nodes.sh` again. The key thing to confirm sync is not the peer count but the tip block hash — both nodes should show the same hash in the comparison panel.

**"I want to run the demo again from scratch"**

Use the reset script, which stops the nodes and wipes all blockchain data in one command:

```bash
./scripts/reset.sh
./scripts/start-nodes.sh
./start-dashboard.sh
./scripts/demo-standalone.sh   # or demo-full.sh
```

---

### Step 4b — Sending transactions manually

**"I get `Insufficient funds` when running `send-transaction.sh`"**

The source wallet doesn't have enough balance. Check the current balance in the dashboard. Remember that each transaction also deducts a small fee — you can never send the exact full balance. Mine more blocks first:

```bash
./scripts/mine-blocks.sh 101 1   # mine 101 blocks on node1
```

**"The mempool showed 1 pending transaction but it disappeared"**

After sending, `send-transaction.sh` pauses and waits for you to press Enter. It does **not** mine automatically — you decide when to mine. If the mempool cleared without you mining, another process may have triggered mining. The transaction is confirmed and included in the new block.

**"The terminal says 'press Enter to continue' but the dashboard already updated"**

The dashboard polls independently every few seconds. It may show the next state before you press Enter in the terminal — that is fine. Press Enter when you are ready to continue the script.

---

### General questions

**"What is regtest mode? Is this real Bitcoin?"**

No. Regtest (regression test) mode is a private, local blockchain that only exists on your computer. No real money is involved — the BTC you mine has no value. You can mine blocks instantly, reset everything at any time, and experiment freely. It is the standard environment for learning and developing Bitcoin applications.

**"What is a coinbase transaction? I see one in every block"**

The coinbase is the first transaction in every block. Unlike regular transactions it has no inputs — it creates new Bitcoin as the reward for mining. In regtest mode the reward is 50 BTC per block. Every block must contain exactly one coinbase; it is the only way new Bitcoin enters circulation.

**"Why does the demo mine 101 blocks before sending? Why not just 1?"**

Bitcoin enforces the **coinbase maturity rule**: freshly mined coins cannot be spent until 100 additional blocks are mined on top of the block that created them. This protects against chain reorganizations. So the demo mines 1 block to earn 50 BTC, then 100 more blocks to make those coins spendable, and only then sends the transaction.

**"The browser tab shows old data — do I need to refresh the page?"**

No. The dashboard refreshes automatically every few seconds. If something looks stale, click the **↻ Refresh** button in the top-right corner to force an immediate update. You never need to reload the entire page.

**"How do I verify that both nodes are on the same chain?"**

Look at the **Node Comparison** panel at the bottom of the dashboard. The "Best Hash" row shows the tip block hash of each node — if both hashes match, the nodes are in sync (the green banner confirms this). You can click the **copy** button next to any hash to copy the full 64-character hash to the clipboard for comparison.

**"Why does node2 show 0 peers in the full demo?"**

In the full demo the nodes connect before mining. After the demo finishes the peer connection may have lapsed or not yet refreshed. The important thing is not the peer count but the sync status: both nodes should show the same height and the same tip hash in the comparison panel.

**"Can node2 mine blocks too? Everything happens on node1"**

Yes. The demo uses node1 for simplicity, but you can mine on node2 at any time:

```bash
./scripts/mine-blocks.sh 5 2   # mine 5 blocks on node2
```

If both nodes are connected, the new blocks propagate to node1 immediately.

**"Can I run this on two separate computers?"**

Not with this setup. Both nodes communicate over `127.0.0.1` (localhost). Connecting nodes across machines requires network and firewall configuration beyond the scope of this exercise.

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
