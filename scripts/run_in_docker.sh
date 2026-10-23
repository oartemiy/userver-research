#!/usr/bin/env bash
# Reproduce the measurements in the exact environment from the assignment:
# ubuntu-22.04-userver image pinned by digest, 4 CPUs, 8 GiB RAM.
#
#   scripts/run_in_docker.sh
#
# On Apple Silicon the image runs under x86-64 emulation; absolute times are
# distorted, but baseline and PCH are measured under the same conditions.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IMG="ghcr.io/userver-framework/ubuntu-22.04-userver"
DIGEST="sha256:fca9c8ac7e97b4e2b042d822facbb152aec10a9d4e09c0862e44c50640f3f303"

exec docker run --rm \
    -v "$ROOT":/work -w /work \
    -e REPS -e JOBS \
    --cpus=4 --cpuset-cpus=0-3 --memory=8g --memory-swap=8g \
    "$IMG@$DIGEST" \
    bash scripts/run_all.sh
