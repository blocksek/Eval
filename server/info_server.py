#!/usr/bin/env python3
"""
Info API server — port 8080

GET /manifest.json              → serves /srv/manifest.json
GET /challenges/<name>          → JSON with name, address, readme, sources
                                  sources: {relative_path: file_content} for all
                                  .sol files under project/src/
404 for anything else.
"""

import json
import os
import http.server

MANIFEST_PATH = "/srv/manifest.json"
CHALLENGES_BASE = "/challenges/solidity"


class InfoHandler(http.server.BaseHTTPRequestHandler):
    def log_message(self, format, *args):
        # Suppress access logs
        pass

    def send_json(self, code, obj):
        body = json.dumps(obj, indent=2).encode()
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def send_404(self):
        self.send_json(404, {"error": "not found"})

    def do_GET(self):
        path = self.path.split("?")[0].rstrip("/")

        if path == "/manifest.json":
            if not os.path.exists(MANIFEST_PATH):
                self.send_json(503, {"error": "manifest not yet available"})
                return
            with open(MANIFEST_PATH, "r") as f:
                manifest = json.load(f)
            self.send_json(200, manifest)
            return

        if path.startswith("/challenges/"):
            parts = path.split("/")
            # /challenges/<name>  → parts = ['', 'challenges', '<name>']
            if len(parts) == 3 and parts[2]:
                name = parts[2]
                challenge_dir = os.path.join(CHALLENGES_BASE, name)
                project_src = os.path.join(challenge_dir, "project", "src")

                if not os.path.isdir(challenge_dir):
                    self.send_404()
                    return

                # Read address from manifest
                address = None
                if os.path.exists(MANIFEST_PATH):
                    with open(MANIFEST_PATH, "r") as f:
                        manifest = json.load(f)
                    address = manifest.get("challenges", {}).get(name, {}).get("address")

                # Read README
                readme = ""
                for readme_name in ("README.md", "readme.md", "README.txt"):
                    readme_path = os.path.join(challenge_dir, readme_name)
                    if os.path.exists(readme_path):
                        with open(readme_path, "r", errors="replace") as f:
                            readme = f.read()
                        break

                # Collect .sol sources
                sources = {}
                if os.path.isdir(project_src):
                    for root, dirs, files in os.walk(project_src):
                        for fname in files:
                            if fname.endswith(".sol"):
                                abs_path = os.path.join(root, fname)
                                rel_path = os.path.relpath(abs_path, project_src)
                                try:
                                    with open(abs_path, "r", errors="replace") as f:
                                        sources[rel_path] = f.read()
                                except OSError:
                                    pass

                self.send_json(200, {
                    "name": name,
                    "address": address,
                    "readme": readme,
                    "sources": sources,
                })
                return

        self.send_404()


if __name__ == "__main__":
    server = http.server.HTTPServer(("0.0.0.0", 8080), InfoHandler)
    print("[info_server] Listening on 0.0.0.0:8080", flush=True)
    server.serve_forever()
