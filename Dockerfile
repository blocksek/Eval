# ── Wonderland CTF 2026 — Eval Container ───────────────────────────────────
#
# Provides a clean environment for AI agent evaluation:
#   • All 20 Solidity challenges + 5 Aztec Noir challenges
#   • No .git history, no docker-compose flags, no reference solutions
#   • Foundry (forge/anvil/cast), Python 3, Node.js 22, Yarn pre-installed
#   • All Solidity challenge contracts pre-built
#   • `ctf-eval` CLI for challenge lifecycle management
#
# Build:   docker build -t ctf-eval .
# Run:     docker run -it --rm ctf-eval
# ───────────────────────────────────────────────────────────────────────────

# ── Pull Foundry binaries from official image ─────────────────────────────
FROM ghcr.io/foundry-rs/foundry:latest AS foundry-bins

FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# ── System packages ──────────────────────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
        curl \
        git \
        build-essential \
        ca-certificates \
        python3 \
        python3-pip \
        jq \
        procps \
    && rm -rf /var/lib/apt/lists/*

# ── Node.js 22 + Yarn ────────────────────────────────────────────────────────
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/* \
    && npm install -g yarn

# ── Foundry (forge, anvil, cast, chisel) ─────────────────────────────────────
COPY --from=foundry-bins /usr/local/bin/forge  /usr/local/bin/forge
COPY --from=foundry-bins /usr/local/bin/anvil  /usr/local/bin/anvil
COPY --from=foundry-bins /usr/local/bin/cast   /usr/local/bin/cast
COPY --from=foundry-bins /usr/local/bin/chisel /usr/local/bin/chisel

# ── Paradigm CTF Python infrastructure ───────────────────────────────────────
COPY solidity/paradigm-ctf-infrastructure /opt/paradigm-ctf-infrastructure
RUN pip3 install --no-cache-dir -e /opt/paradigm-ctf-infrastructure

# ── Challenge source files ────────────────────────────────────────────────────
# .dockerignore already strips: .git, node_modules, build artifacts,
# docker-compose files (contain flags), per-challenge Dockerfiles.
WORKDIR /challenges
COPY . /challenges/

# Belt-and-suspenders: remove anything that might help an agent cheat,
# even if .dockerignore missed it.
RUN \
    # No git history
    find /challenges -name ".git" -type d -exec rm -rf {} + 2>/dev/null; true && \
    # No docker-compose (flags as env vars)
    find /challenges -name "docker-compose.yml" -o -name "docker-compose.yaml" \
         | xargs rm -f 2>/dev/null; true && \
    # No per-challenge Dockerfiles
    find /challenges/solidity -maxdepth 2 -name "Dockerfile" -delete 2>/dev/null; true && \
    # No remaining solution artefacts (defence-in-depth; should already be gone)
    find /challenges -name "solve.py" -delete 2>/dev/null; true && \
    find /challenges -name "Solve.s.sol" -delete 2>/dev/null; true && \
    find /challenges -path "*/script/exploit" -type d -exec rm -rf {} + 2>/dev/null; true && \
    find /challenges/aztec-noir/src/ts -mindepth 1 -delete 2>/dev/null; true && \
    find /challenges/aztec-noir/scripts/challenges -mindepth 1 -delete 2>/dev/null; true

# ── Forge library dependencies ────────────────────────────────────────────────
# forge-std:  not vendored — download once then copy to every project.
# forge-ctf:  vendored in 6 challenges already; copy to the rest from there.
#
# We install forge-std for one project (network access for git), then rsync
# it to the others so we only hit the network once.  forge-ctf is already
# present in the repo for some challenges; we just copy that tree around.
# balance-proof already vendors both forge-std and forge-ctf — copy them to
# every other challenge project that is missing one or both.
RUN ANCHOR=/challenges/solidity/balance-proof/project/lib && \
    for project in /challenges/solidity/*/project; do \
        [ -f "$project/foundry.toml" ] || continue; \
        mkdir -p "$project/lib"; \
        [ -d "$project/lib/forge-std" ] || cp -r "$ANCHOR/forge-std" "$project/lib/"; \
        [ -d "$project/lib/forge-ctf"  ] || cp -r "$ANCHOR/forge-ctf"  "$project/lib/"; \
    done

# ── Pre-build all Solidity challenges ────────────────────────────────────────
# Agents can re-build at any time; this just saves first-run latency.
RUN for project in /challenges/solidity/*/project; do \
        [ -f "$project/foundry.toml" ] || continue; \
        name=$(basename "$(dirname "$project")"); \
        echo "==> building $name ..."; \
        cd "$project" && forge build --quiet 2>&1 | tail -2 \
            || echo "    [warn] build failed for $name — agents may need to debug deps"; \
    done

# ── Aztec Noir: install JS dependencies ──────────────────────────────────────
# This enables agents to read, analyze, and type-check Aztec challenges.
# Running tests requires an external Aztec network (see /eval/README.md).
WORKDIR /challenges/aztec-noir
RUN yarn install || true

# ── Eval harness ─────────────────────────────────────────────────────────────
COPY eval /eval
RUN chmod +x /eval/ctf-eval
ENV PATH="/eval:$PATH"

# ── Workspace — agents write their exploits here ─────────────────────────────
WORKDIR /workspace

RUN echo "==> Eval image ready." && \
    echo "    Run  ctf-eval list  to see available challenges."

CMD ["/bin/bash", "--login"]
