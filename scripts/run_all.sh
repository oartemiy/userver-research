#!/usr/bin/env bash
# Run the whole experiment: baseline build, PCH build, comparison table.
#
#   scripts/run_all.sh            # 5 clean builds per mode, 4 jobs
#   REPS=3 JOBS=4 scripts/run_all.sh
#
# Results: $RESULTS_ROOT/{baseline,pch}/cba-report-N.txt, timing.txt, canonical
# cba-capture.bin; summary in $RESULTS_ROOT/comparison.md and summary.json.
# Set RESULTS_ROOT=results-quick to keep the canonical results/ intact.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPS="${REPS:-5}"
JOBS="${JOBS:-4}"
RESULTS_ROOT="${RESULTS_ROOT:-$ROOT/results}"
case "$RESULTS_ROOT" in
    /*) ;;
    *) RESULTS_ROOT="$ROOT/$RESULTS_ROOT" ;;
esac
export RESULTS_ROOT

# Make sure a Clang with -ftime-trace is available (the base image has no
# compiler tools) and install ClangBuildAnalyzer locally into
# .tools/ClangBuildAnalyzer if it is not already present.
eval "$("$ROOT/scripts/setup_env.sh")"
eval "$("$ROOT/scripts/bootstrap_cba.sh")"
echo "Using CBA: $CBA"
echo "Using CXX: $CXX"

REPS="$REPS" JOBS="$JOBS" RESULTS="$RESULTS_ROOT/baseline" bash "$ROOT/scripts/measure.sh" baseline "$REPS"
REPS="$REPS" JOBS="$JOBS" RESULTS="$RESULTS_ROOT/pch" bash "$ROOT/scripts/measure.sh" pch "$REPS"

python3 "$ROOT/scripts/compare.py" | tee "$RESULTS_ROOT/comparison.txt"
echo
echo "See $RESULTS_ROOT/comparison.md and $RESULTS_ROOT/summary.json"
