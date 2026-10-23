#!/usr/bin/env bash
# Prepare the compiler for -ftime-trace measurements.
#
# The assignment image (ubuntu-22.04-userver) ships without Clang, so the first
# run installs clang-18 from the image's configured apt.llvm.org repository.
# Prints shell assignments for eval:
#   eval "$(scripts/setup_env.sh)"
set -euo pipefail

if ! command -v clang++-18 >/dev/null 2>&1; then
    echo "clang++-18 not found, installing clang-18 (first run only)..." >&2
    # The image already has package indexes; 'apt-get update' can be slow/flaky
    # behind a proxy, so try the install first and only hint at update on failure.
    if ! DEBIAN_FRONTEND=noninteractive apt-get install -y clang-18 >&2; then
        echo "clang-18 installation failed; try 'apt-get update' and rerun" >&2
        exit 1
    fi
fi

CXX="$(command -v clang++-18 || true)"
CC="$(command -v clang-18 || true)"
if [[ -z "$CXX" || -z "$CC" ]]; then
    echo "clang-18 is still not available after installation" >&2
    exit 1
fi

echo "export CC='$CC' CXX='$CXX'"
