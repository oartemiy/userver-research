#!/usr/bin/env bash
# Locate or build ClangBuildAnalyzer.
#
# By default the analyzer is installed inside the repository:
#   .tools/ClangBuildAnalyzer/build/ClangBuildAnalyzer
# so a reviewer does not need a pre-installed CBA and the binary stays with the
# checkout. Prints shell assignments for eval:
#   eval "$(scripts/bootstrap_cba.sh)"
#
# Overrides:
#   CBA=/path/to/ClangBuildAnalyzer   use an existing binary
#   CBA_SRC=/path/to/source           use/build from another source tree
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="${CBA_SRC:-$ROOT/.tools/ClangBuildAnalyzer}"
JOBS="${JOBS:-4}"

if [[ -n "${CBA:-}" ]]; then
    if [[ -x "$CBA" ]]; then
        echo "export CBA='$CBA'"
        exit 0
    fi
    echo "CBA is set to '$CBA', but it is not executable; ignoring it" >&2
fi

CBA="$SRC/build/ClangBuildAnalyzer"
if [[ -x "$CBA" ]]; then
    echo "export CBA='$CBA'"
    exit 0
fi

if [[ ! -d "$SRC" ]]; then
    echo "ClangBuildAnalyzer not found, cloning into $SRC (first run only)..." >&2
    mkdir -p "$(dirname "$SRC")"
    if ! git clone --depth 1 https://github.com/aras-p/ClangBuildAnalyzer.git "$SRC" >&2; then
        echo "failed to clone ClangBuildAnalyzer; check network access" >&2
        exit 1
    fi
elif [[ ! -f "$SRC/CMakeLists.txt" ]]; then
    echo "$SRC exists but does not look like ClangBuildAnalyzer (no CMakeLists.txt)" >&2
    exit 1
else
    echo "Building ClangBuildAnalyzer from existing source in $SRC..." >&2
fi

cmake -S "$SRC" -B "$SRC/build" -DCMAKE_BUILD_TYPE=Release >&2
cmake --build "$SRC/build" -j "$JOBS" >&2

if [[ ! -x "$CBA" ]]; then
    echo "ClangBuildAnalyzer build finished but $CBA is missing" >&2
    exit 1
fi

echo "export CBA='$CBA'"
