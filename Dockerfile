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

FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV PATH="/root/.foundry/bin:$PATH"

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
RUN curl -fsSL https://foundry.paradigm.xyz | bash && foundryup

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
# forge-std:  not vendored in the repo — install per challenge project.
# forge-ctf:  vendored for some challenges, needs installing for others.
# Both are fetched from GitHub at image build time (requires network).
RUN for project in /challenges/solidity/*/project; do \
        [ -f "$project/foundry.toml" ] || continue; \
        echo "==> installing libs for $project"; \
        cd "$project"; \
        [ -d "lib/forge-std" ] || \
            forge install --no-git foundry-rs/forge-std    || true; \
        [ -d "lib/forge-ctf" ] || \
            forge install --no-git paradigmxyz/forge-ctf   || true; \
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
