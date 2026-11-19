# syntax=docker/dockerfile:1

# =============================================================================
# Komodo Core - offline action cache overlay
#
# Base: the official published image (no git clone, no repo, no build args).
# Adds exactly ONE layer on top of it: bakes `npm:mogh_auth_client` into the
# Deno cache at /action-cache/deno.
#
# Why: the core serves its own client lib (client/lib.js) which contains
# `import { MoghAuthClient } from "npm:mogh_auth_client"`. The official
# image only pre-caches the two JSR packages (jsr:@std/yaml,
# jsr:@std/toml), so the first action run tries to download the npm package
# at runtime. With it cached here, action runs make ZERO network requests
# for dependencies (verified: fully offline action run, 0 fetches).
#
# Build (this file is the entire context - nothing else needed):
#   mkdir komodo-core-offline && cd komodo-core-offline
#   cp /path/to/Dockerfile .
#   docker build -t komodo-core-offline:2.3.3 .
#
# Note: build on the host that runs core. Docker BuildKit uses the locally
# present ghcr.io/moghtech/komodo-core:2 image as the base and does NOT
# re-pull, so the fork is based on the exact image you already run.
#
# Upgrade path: when upstream bumps :2, re-run the same build command.
# =============================================================================

FROM ghcr.mortimer.website/moghtech/komodo-core:2

# Inherited from the base image; set explicitly so the cache lands in the
# right place even if a future official image drops this ENV.
ENV DENO_DIR=/action-cache/deno

# The stock pre-cache line plus the missing npm package.
# The two jsr packages are already cached in the base (idempotent re-check);
# the npm package is the fix. All network access happens here, at build
# time, on your machine - never at action runtime.
RUN cd /action-cache && \
  deno install jsr:@std/yaml jsr:@std/toml npm:mogh_auth_client
