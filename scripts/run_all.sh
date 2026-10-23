#!/usr/bin/env bash
# Run the whole experiment: baseline build, PCH build, comparison table.
#
#   scripts/run_all.sh            # 5 clean builds per mode, 4 jobs
#   REPS=3 JOBS=4 scripts/run_all.sh
#
# Results: results/{baseline,pch}/cba-report-N.txt, timing.txt, canonical
# cba-capture.bin; summary in results/comparison.md and results/summary.json.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPS="${REPS:-5}"
JOBS="${JOBS:-4}"

# Build ClangBuildAnalyzer if it is not already present, and make sure a
# Clang with -ftime-trace is available (the base image has no compiler tools).
eval "$("$ROOT/scripts/setup_env.sh")"
eval "$("$ROOT/scripts/bootstrap_cba.sh")"

REPS="$REPS" JOBS="$JOBS" bash "$ROOT/scripts/measure.sh" baseline "$REPS"
REPS="$REPS" JOBS="$JOBS" bash "$ROOT/scripts/measure.sh" pch "$REPS"

python3 "$ROOT/scripts/compare.py" | tee "$ROOT/results/comparison.txt"
echo
echo "See results/comparison.md and results/summary.json"
