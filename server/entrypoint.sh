#!/usr/bin/env bash
set -euo pipefail

MNEMONIC="test test test test test test test test test test test junk"
PLAYER_ADDR="0x70997970C51812dc3A010C7d01b50e0d17dc79C8"
PLAYER_KEY="0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d"
ZERO_ADDR="0x0000000000000000000000000000000000000000"
ANVIL_URL="http://127.0.0.1:18545"

# ── 1. Start Anvil ────────────────────────────────────────────────────────────
echo "[entrypoint] Starting Anvil on 127.0.0.1:18545 ..."
anvil \
    --host 127.0.0.1 \
    --port 18545 \
    --mnemonic "${MNEMONIC}" \
    --balance 10000 \
    > /tmp/anvil.log 2>&1 &
ANVIL_PID=$!

# ── 2. Wait for Anvil to be ready ─────────────────────────────────────────────
echo "[entrypoint] Waiting for Anvil ..."
for i in $(seq 1 60); do
    if curl -sf -X POST "${ANVIL_URL}" \
            -H 'Content-Type: application/json' \
            -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
            > /dev/null 2>&1; then
        echo "[entrypoint] Anvil ready."
        break
    fi
    sleep 1
done

# ── 3. Enable autoImpersonateAccount and fund zero address ────────────────────
echo "[entrypoint] Enabling anvil_autoImpersonateAccount ..."
curl -sf -X POST "${ANVIL_URL}" \
    -H 'Content-Type: application/json' \
    -d '{"jsonrpc":"2.0","method":"anvil_autoImpersonateAccount","params":[true],"id":1}' \
    > /dev/null

echo "[entrypoint] Funding zero address with 10000 ETH ..."
curl -sf -X POST "${ANVIL_URL}" \
    -H 'Content-Type: application/json' \
    -d "{\"jsonrpc\":\"2.0\",\"method\":\"anvil_setBalance\",\"params\":[\"${ZERO_ADDR}\",\"0x21E19E0C9BAB2400000\"],\"id\":2}" \
    > /dev/null

# ── 4. Deploy all Solidity challenges ─────────────────────────────────────────
declare -A DEPLOYED_ADDRS

for project in /challenges/solidity/*/project; do
    [ -f "${project}/foundry.toml" ] || continue
    name=$(basename "$(dirname "${project}")")

    # Skip infrastructure helper
    if [ "${name}" = "paradigm-ctf-infrastructure" ]; then
        continue
    fi

    echo "[entrypoint] Deploying ${name} ..."
    OUTPUT_FILE="/tmp/addr_${name}"

    set +e
    (
        cd "${project}"
        MNEMONIC="${MNEMONIC}" \
        OUTPUT_FILE="${OUTPUT_FILE}" \
        forge script script/Deploy.s.sol:Deploy \
            --rpc-url "${ANVIL_URL}" \
            --broadcast \
            --unlocked \
            --sender "${ZERO_ADDR}" \
            2>&1 | tail -5
    )
    EXIT_CODE=$?
    set -e

    if [ ${EXIT_CODE} -eq 0 ] && [ -f "${OUTPUT_FILE}" ]; then
        ADDR=$(cat "${OUTPUT_FILE}")
        DEPLOYED_ADDRS["${name}"]="${ADDR}"
        echo "[entrypoint]   ✓ ${name} deployed at ${ADDR}"
    else
        echo "[entrypoint]   ✗ ${name} deployment failed (exit ${EXIT_CODE})"
    fi
done

# ── 5. Write /srv/manifest.json ───────────────────────────────────────────────
echo "[entrypoint] Writing manifest ..."

python3 - <<'PYEOF'
import json, os

deployed = {}
for f in os.listdir("/tmp"):
    if f.startswith("addr_"):
        name = f[len("addr_"):]
        with open(f"/tmp/{f}") as fh:
            addr = fh.read().strip()
        if addr:
            deployed[name] = {"address": addr}

manifest = {
    "rpc_url": "http://ctf-server:8545",
    "player_address": "0x70997970C51812dc3A010C7d01b50e0d17dc79C8",
    "player_private_key": "0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d",
    "challenges": deployed,
}

os.makedirs("/srv", exist_ok=True)
with open("/srv/manifest.json", "w") as fh:
    json.dump(manifest, fh, indent=2)

print(f"[entrypoint] Manifest written: {len(deployed)} challenge(s) deployed.")
for name, info in sorted(deployed.items()):
    print(f"  {name}: {info['address']}")
PYEOF

# ── 6. Start RPC proxy and info server ────────────────────────────────────────
echo "[entrypoint] Starting RPC proxy (port 8545) ..."
python3 /srv/rpc_proxy.py &

echo "[entrypoint] Starting info server (port 8080) ..."
python3 /srv/info_server.py &

# ── 7. Banner and wait ────────────────────────────────────────────────────────
echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║         Wonderland CTF 2026 — Server Ready               ║"
echo "║                                                          ║"
echo "║  RPC  (filtered): http://0.0.0.0:8545                   ║"
echo "║  Info API:        http://0.0.0.0:8080                   ║"
echo "║  Manifest:        http://0.0.0.0:8080/manifest.json     ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

wait ${ANVIL_PID}
