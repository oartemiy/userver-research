#!/usr/bin/env bash
# Reproducible ClangBuildAnalyzer measurement for the research userver service.
#
# Usage:
#   scripts/measure.sh baseline [reps]   # no PCH (reference build)
#   scripts/measure.sh pch      [reps]   # hypothesis: precompiled header
#
# Env overrides: JOBS, REPS, BUILD_DIR, RESULTS, CC, CXX, CBA
set -uo pipefail

MODE="${1:-baseline}"
REPS="${2:-${REPS:-3}}"
JOBS="${JOBS:-4}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="${BUILD_DIR:-$ROOT/build-$MODE}"
RESULTS="${RESULTS:-$ROOT/results/$MODE}"
CC="${CC:-$(command -v clang-18 || command -v clang || true)}"
CXX="${CXX:-$(command -v clang++-18 || command -v clang++ || true)}"
CBA="${CBA:-/root/tools/ClangBuildAnalyzer/build/ClangBuildAnalyzer}"

if [[ -z "$CC" || -z "$CXX" ]]; then
    echo "clang not found; run scripts/setup_env.sh first" >&2
    exit 3
fi

case "$MODE" in
    baseline) PCH_FLAG=-DRESEARCH_USE_PCH=OFF ;;
    pch)      PCH_FLAG=-DRESEARCH_USE_PCH=ON ;;
    *) echo "usage: $0 {baseline|pch} [reps]" >&2; exit 2 ;;
esac

if [[ ! -x "$CBA" ]]; then
    echo "ClangBuildAnalyzer not found at $CBA (set CBA=...)" >&2
    exit 3
fi

cd "$ROOT"
rm -rf "$RESULTS"
mkdir -p "$RESULTS"
: > "$RESULTS/timing.txt"
{
    echo "mode=$MODE reps=$REPS jobs=$JOBS"
    echo "cxx=$($CXX --version | head -1)"
    echo "cmake=$(cmake --version | head -1)"
    echo "nproc=$(nproc)"
    uname -a
} > "$RESULTS/meta.txt"

for i in $(seq 1 "$REPS"); do
    echo "=== $MODE run $i/$REPS ==="
    rm -rf "$BUILD_DIR"

    cmake -S "$ROOT" -B "$BUILD_DIR" -G Ninja \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_C_COMPILER="$CC" \
        -DCMAKE_CXX_COMPILER="$CXX" \
        -DUSERVER_FEATURE_GRPC=ON \
        -DUSERVER_FEATURE_POSTGRESQL=ON \
        -DUSERVER_FEATURE_MONGODB=ON \
        -DUSERVER_DEBUG_INFO_COMPRESSION=none \
        -DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
        "$PCH_FLAG" > "$RESULTS/configure-$i.log" 2>&1
    if [[ $? -ne 0 ]]; then
        echo "cmake configure failed, see $RESULTS/configure-$i.log" >&2
        exit 4
    fi

    "$CBA" --start "$BUILD_DIR"

    START_NS=$(date +%s%N)
    cmake --build "$BUILD_DIR" -j "$JOBS" --target research \
        > "$RESULTS/build-$i.log" 2>&1
    BUILD_RC=$?
    END_NS=$(date +%s%N)
    WALL=$(awk -v s="$START_NS" -v e="$END_NS" "BEGIN { printf \"%.2f\", (e-s)/1e9 }")
    printf "%s\n" "$WALL" > "$RESULTS/time-$i.txt"
    python3 "$ROOT/scripts/extract_tu_times.py" "$BUILD_DIR" "$RESULTS/tu-times-$i.csv" \
        > "$RESULTS/tu-times-$i.log" 2>&1 || true
    python3 "$ROOT/scripts/extract_phases.py" "$BUILD_DIR/.ninja_log" "$RESULTS/phases-$i.csv" \
        > "$RESULTS/phases-$i.log" 2>&1 || true
    cp "$BUILD_DIR/.ninja_log" "$RESULTS/ninja-log-$i.log" 2>/dev/null || true

    "$CBA" --stop "$BUILD_DIR" "$RESULTS/cba-capture-$i.bin"
    "$CBA" --analyze "$RESULTS/cba-capture-$i.bin" > "$RESULTS/cba-report-$i.txt" 2>&1

    echo "run=$i build_rc=$BUILD_RC wall_s=$WALL" | tee -a "$RESULTS/timing.txt"

    cp "$RESULTS/cba-report-$i.txt" "$RESULTS/cba-report.txt"
    cp "$RESULTS/cba-capture-$i.bin" "$RESULTS/cba-capture.bin"

    if [[ $BUILD_RC -ne 0 ]]; then
        echo "NOTE: build failed (rc=$BUILD_RC), compilation metrics are still valid" >&2
    fi
done

# Keep one canonical capture per mode; per-run text reports are enough for the rest.
rm -f "$RESULTS"/cba-capture-[0-9]*.bin

echo "Done. Results in $RESULTS"
