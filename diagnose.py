#!/usr/bin/env python3
"""Quick diagnostic — run on Mac with: python3 diagnose.py"""
import urllib.request, urllib.error, base64, json, sys
from pathlib import Path

BITCOIN_DIR = Path.home() / "bitcoin"

NODES = [
    {"name": "node1", "rpcport": 1234},
    {"name": "node2", "rpcport": 2345},
]

def read_cookie(name):
    p = BITCOIN_DIR / name / "regtest" / ".cookie"
    print(f"  Cookie path: {p}")
    print(f"  Exists: {p.exists()}")
    if p.exists():
        txt = p.read_text().strip()
        print(f"  Content: {txt[:40]}...")
        user, _, pwd = txt.partition(":")
        return user, pwd
    return None, None

def rpc_call(host, port, user, pwd, method):
    url  = f"http://{host}:{port}/"
    cred = base64.b64encode(f"{user}:{pwd}".encode()).decode()
    data = json.dumps({"jsonrpc":"1.0","id":"diag","method":method,"params":[]}).encode()
    req  = urllib.request.Request(url, data=data,
           headers={"Authorization": f"Basic {cred}", "Content-Type":"application/json"})
    try:
        with urllib.request.urlopen(req, timeout=5) as r:
            return json.loads(r.read()), None
    except urllib.error.HTTPError as e:
        body = e.read().decode(errors="replace")
        return None, f"HTTP {e.code}: {body[:200]}"
    except Exception as e:
        return None, str(e)

print(f"\n{'='*60}")
print(f"  Bitcoin Regtest Dashboard — Diagnostics")
print(f"  HOME={Path.home()}")
print(f"  BITCOIN_DIR={BITCOIN_DIR}  exists={BITCOIN_DIR.exists()}")
print(f"{'='*60}\n")

for node in NODES:
    name    = node["name"]
    port    = node["rpcport"]
    print(f"── {name} (rpcport={port}) ─────────────────────────────")
    user, pwd = read_cookie(name)
    if not user:
        print("  ❌ Could not read cookie file\n")
        continue

    # Try IPv4 / IPv6 / hostname
    for host in ["127.0.0.1", "::1", "localhost"]:
        res, err = rpc_call(host, port, user, pwd, "getblockchaininfo")
        if res:
            print(f"  ✅ Conectado via {host}:{port}")
            print(f"     height={res['result']['blocks']}  chain={res['result']['chain']}")
            break
        else:
            print(f"  ❌ {host}:{port} → {err}")
    print()

print("Diagnostics complete.\n")
