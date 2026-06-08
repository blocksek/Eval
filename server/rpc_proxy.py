#!/usr/bin/env python3
"""
Filtered RPC proxy — port 8545
Forwards JSON-RPC requests to upstream Anvil at http://127.0.0.1:18545.
Blocks any method starting with: anvil_  hardhat_  evm_
Handles both single requests and batch arrays.
Access logs are suppressed.
"""

import json
import http.server
import urllib.request
import urllib.error

UPSTREAM = "http://127.0.0.1:18545"
BLOCKED_PREFIXES = ("anvil_", "hardhat_", "evm_")


def _blocked_error(req_id, method):
    return {
        "jsonrpc": "2.0",
        "id": req_id,
        "error": {
            "code": -32601,
            "message": f"Method not found: {method!r} is blocked by the CTF proxy",
        },
    }


def _forward(payload_bytes):
    req = urllib.request.Request(
        UPSTREAM,
        data=payload_bytes,
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    with urllib.request.urlopen(req) as resp:
        return resp.read()


def _process(body_bytes):
    try:
        data = json.loads(body_bytes)
    except json.JSONDecodeError:
        return json.dumps({"jsonrpc": "2.0", "id": None, "error": {"code": -32700, "message": "Parse error"}}).encode()

    is_batch = isinstance(data, list)
    requests = data if is_batch else [data]

    results = []
    forward_requests = []
    forward_indices = []

    for i, req in enumerate(requests):
        method = req.get("method", "")
        if any(method.startswith(prefix) for prefix in BLOCKED_PREFIXES):
            results.append((i, _blocked_error(req.get("id"), method)))
        else:
            forward_requests.append(req)
            forward_indices.append(i)

    # Forward non-blocked requests in one batch (or single)
    if forward_requests:
        payload = json.dumps(forward_requests if is_batch or len(forward_requests) > 1 else forward_requests[0]).encode()
        try:
            raw = _forward(payload)
            fwd_data = json.loads(raw)
        except Exception as exc:
            error_resp = {"jsonrpc": "2.0", "id": None, "error": {"code": -32603, "message": str(exc)}}
            fwd_data = [error_resp] * len(forward_requests)

        if not isinstance(fwd_data, list):
            fwd_data = [fwd_data]

        for idx, resp in zip(forward_indices, fwd_data):
            results.append((idx, resp))

    # Reconstruct in original order
    results.sort(key=lambda x: x[0])
    ordered = [r for _, r in results]

    if is_batch:
        return json.dumps(ordered).encode()
    else:
        return json.dumps(ordered[0] if ordered else {}).encode()


class SilentHandler(http.server.BaseHTTPRequestHandler):
    def log_message(self, format, *args):
        # Suppress access logs
        pass

    def do_POST(self):
        length = int(self.headers.get("Content-Length", 0))
        body = self.rfile.read(length)
        response_body = _process(body)
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(response_body)))
        self.end_headers()
        self.wfile.write(response_body)

    def do_GET(self):
        # Some clients send GET health checks
        body = b'{"jsonrpc":"2.0","result":"ok","id":null}'
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)


if __name__ == "__main__":
    server = http.server.HTTPServer(("0.0.0.0", 8545), SilentHandler)
    print("[rpc_proxy] Listening on 0.0.0.0:8545 → forwarding to", UPSTREAM, flush=True)
    server.serve_forever()
