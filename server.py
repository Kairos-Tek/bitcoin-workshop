#!/usr/bin/env python3
"""
Bitcoin Regtest Dashboard — API Server
Reads .cookie files from ~/bitcoin/node1 and ~/bitcoin/node2.
Serves a JSON API on http://localhost:18500
"""

import json
import os
import base64
import urllib.request
import urllib.error
from http.server import HTTPServer, BaseHTTPRequestHandler
from pathlib import Path

# ── Configuración de nodos ────────────────────────────────────────────────────

BITCOIN_DIR = Path.home() / "bitcoin"

NODE_CONFIGS = [
    {
        "name":    "node1",
        "rpchost": "127.0.0.1",
        "rpcport": 1234,
        "datadir": BITCOIN_DIR / "node1",
    },
    {
        "name":    "node2",
        "rpchost": "127.0.0.1",
        "rpcport": 2345,
        "datadir": BITCOIN_DIR / "node2",
    },
]


def read_cookie(datadir: Path) -> tuple[str, str]:
    """Lee el fichero .cookie de regtest y devuelve (user, password)."""
    cookie_path = datadir / "regtest" / ".cookie"
    try:
        text = cookie_path.read_text().strip()
        user, _, password = text.partition(":")
        return user, password
    except Exception as e:
        print(f"  [WARN] No se pudo leer {cookie_path}: {e}")
        return "__cookie__", ""


# ── Bitcoin RPC client ────────────────────────────────────────────────────────

class BitcoinRPC:
    def __init__(self, cfg: dict):
        self.cfg = cfg
        self.url = f"http://{cfg['rpchost']}:{cfg['rpcport']}/"
        self._refresh_auth()

    def _refresh_auth(self):
        """Recarga las credenciales del cookie (se regenera al reiniciar el nodo)."""
        user, password = read_cookie(self.cfg["datadir"])
        creds = base64.b64encode(f"{user}:{password}".encode()).decode()
        self.headers = {
            "Authorization": f"Basic {creds}",
            "Content-Type": "application/json",
        }

    def call(self, method: str, params=None):
        payload = json.dumps({
            "jsonrpc": "1.0",
            "id": "dashboard",
            "method": method,
            "params": params or [],
        }).encode()

        for attempt in range(2):          # 2 intentos: 2º recarga cookie
            req = urllib.request.Request(self.url, data=payload, headers=self.headers)
            try:
                with urllib.request.urlopen(req, timeout=5) as resp:
                    result = json.loads(resp.read())
                    if result.get("error"):
                        return None, result["error"]
                    return result.get("result"), None
            except urllib.error.HTTPError as e:
                if e.code == 401 and attempt == 0:
                    self._refresh_auth()   # cookie puede haber cambiado
                    continue
                body = e.read().decode(errors="replace")
                try:
                    err = json.loads(body).get("error", body)
                except Exception:
                    err = body
                return None, err
            except Exception as e:
                return None, str(e)
        return None, "Authentication failed"

    def is_online(self) -> bool:
        result, _ = self.call("getblockchaininfo")
        return result is not None


# ── HTTP Request Handler ──────────────────────────────────────────────────────

class DashboardHandler(BaseHTTPRequestHandler):
    nodes: list[dict] = []
    rpcs:  list[BitcoinRPC] = []

    def log_message(self, fmt, *args):
        pass  # silenciar log por defecto

    def send_json(self, data, status=200):
        body = json.dumps(data, indent=2).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")
        self.end_headers()
        self.wfile.write(body)

    def do_OPTIONS(self):
        self.send_response(200)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")
        self.end_headers()

    def do_GET(self):
        path = self.path.split("?")[0].rstrip("/")
        parts = [p for p in path.split("/") if p]

        # ── Servir index.html en la raíz ─────────────────────────────────────
        if path in ("", "/", "/index.html"):
            html_path = Path(__file__).parent / "index.html"
            try:
                content = html_path.read_bytes()
                self.send_response(200)
                self.send_header("Content-Type", "text/html; charset=utf-8")
                self.send_header("Content-Length", str(len(content)))
                self.end_headers()
                self.wfile.write(content)
            except Exception as e:
                self.send_json({"error": f"No se pudo leer index.html: {e}"}, 500)
            return

        # ── GET /api/status ──────────────────────────────────────────────────
        if parts == ["api", "status"]:
            statuses = []
            for i, (cfg, rpc) in enumerate(zip(self.nodes, self.rpcs)):
                result, err = rpc.call("getblockchaininfo")
                cookie_path = cfg["datadir"] / "regtest" / ".cookie"
                statuses.append({
                    "node":        i + 1,
                    "name":        cfg["name"],
                    "rpcport":     cfg["rpcport"],
                    "rpcurl":      rpc.url,
                    "online":      result is not None,
                    "rpc_error":   str(err) if err else None,
                    "cookie_path": str(cookie_path),
                    "cookie_exists": cookie_path.exists(),
                    "datadir":     str(cfg["datadir"]),
                })
            self.send_json({"nodes": statuses})
            return

        # ── GET /api/node/{1|2}/... ──────────────────────────────────────────
        if len(parts) >= 3 and parts[0] == "api" and parts[1] == "node":
            try:
                node_idx = int(parts[2]) - 1
                assert 0 <= node_idx < len(self.rpcs)
            except Exception:
                self.send_json({"error": "Invalid node number (use 1 or 2)"}, 400)
                return

            rpc  = self.rpcs[node_idx]
            cfg  = self.nodes[node_idx]
            sub  = parts[3] if len(parts) > 3 else "info"

            # GET /api/node/{n}/info ─────────────────────────────────────────
            if sub == "info":
                chain_info, e1 = rpc.call("getblockchaininfo")
                net_info,   e2 = rpc.call("getnetworkinfo")
                mem_info,   e3 = rpc.call("getmempoolinfo")
                if e1:
                    self.send_json({"error": str(e1)})
                    return
                self.send_json({
                    "blockchain": chain_info,
                    "network":    net_info,
                    "mempool":    mem_info,
                })
                return

            # GET /api/node/{n}/blocks ────────────────────────────────────────
            if sub == "blocks":
                chain_info, err = rpc.call("getblockchaininfo")
                if err:
                    self.send_json({"error": str(err)})
                    return

                tip_height = chain_info["blocks"]
                blocks = []
                hash_cur, _ = rpc.call("getblockhash", [tip_height])

                for _ in range(min(20, tip_height + 1)):
                    if not hash_cur:
                        break
                    blk, err = rpc.call("getblock", [hash_cur])
                    if err or not blk:
                        break
                    blocks.append({
                        "height":            blk["height"],
                        "hash":              blk["hash"],
                        "time":              blk["time"],
                        "txcount":           len(blk.get("tx", [])),
                        "size":              blk.get("size", 0),
                        "weight":            blk.get("weight", 0),
                        "previousblockhash": blk.get("previousblockhash", ""),
                        "nonce":             blk.get("nonce", 0),
                        "bits":              blk.get("bits", ""),
                    })
                    hash_cur = blk.get("previousblockhash")

                self.send_json({"blocks": blocks, "tip_height": tip_height})
                return

            # GET /api/node/{n}/block/{hash} ──────────────────────────────────
            if sub == "block" and len(parts) > 4:
                block_hash = parts[4]
                blk, err = rpc.call("getblock", [block_hash, 2])
                if err:
                    self.send_json({"error": str(err)})
                    return
                self.send_json(blk)
                return

            # GET /api/node/{n}/mempool ───────────────────────────────────────
            if sub == "mempool":
                mem_info, e1 = rpc.call("getmempoolinfo")
                raw_mem,  e2 = rpc.call("getrawmempool", [False])
                self.send_json({
                    "info":  mem_info,
                    "txids": raw_mem or [],
                    "error": str(e1 or e2) if (e1 or e2) else None,
                })
                return

            self.send_json({"error": f"Unknown endpoint: {path}"}, 404)
            return

        self.send_json({"error": "Not found"}, 404)


# ── Main ──────────────────────────────────────────────────────────────────────

def main():
    PORT = 18500

    nodes = NODE_CONFIGS
    rpcs  = [BitcoinRPC(cfg) for cfg in nodes]

    DashboardHandler.nodes = nodes
    DashboardHandler.rpcs  = rpcs

    print()
    print("=" * 58)
    print("  Bitcoin Regtest Dashboard — API Server")
    print("=" * 58)
    for i, (cfg, rpc) in enumerate(zip(nodes, rpcs)):
        online = rpc.is_online()
        badge  = "✅ ONLINE" if online else "❌ OFFLINE"
        print(f"  Nodo {i+1} ({cfg['name']}): port {cfg['rpcport']}  {badge}")
    print(f"\n  API → http://localhost:{PORT}/api/status")
    print("  Ctrl+C para detener")
    print("=" * 58)
    print()

    server = HTTPServer(("localhost", PORT), DashboardHandler)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\n[INFO] Servidor detenido.")


if __name__ == "__main__":
    main()
