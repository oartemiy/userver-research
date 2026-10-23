#!/usr/bin/env bash
# Locate or build ClangBuildAnalyzer. Prints shell assignments for eval:
#   eval "$(scripts/bootstrap_cba.sh)"
# Set CBA=/path/to/ClangBuildAnalyzer to use an existing binary.
set -euo pipefail

if [[ -n "${CBA:-}" && -x "${CBA}" ]]; then
    echo "export CBA='$CBA'"
    exit 0
fi

CBA="${CBA:-$HOME/tools/ClangBuildAnalyzer/build/ClangBuildAnalyzer}"
if [[ -x "$CBA" ]]; then
    echo "export CBA='$CBA'"
    exit 0
fi

SRC="${CBA_SRC:-$HOME/tools/ClangBuildAnalyzer}"
JOBS="${JOBS:-4}"
echo "ClangBuildAnalyzer not found, building it into $SRC" >&2

if [[ ! -d "$SRC/.git" ]]; then
    git clone --depth 1 https://github.com/aras-p/ClangBuildAnalyzer.git "$SRC" >&2
fi
cmake -S "$SRC" -B "$SRC/build" -DCMAKE_BUILD_TYPE=Release >&2
cmake --build "$SRC/build" -j "$JOBS" >&2

echo "export CBA='$SRC/build/ClangBuildAnalyzer'"
