# Raw measurement results

Medians of 5 clean builds per mode. Environment: Ubuntu 22.04 userver image
(`--cpus=4 --memory=8g`), Clang 18.1.8, userver 3.3-rc, Release, target
`research` (10 translation units), `-ftime-trace`.

| file | content |
|---|---|
| `../cba-report.txt` | full ClangBuildAnalyzer output for the canonical baseline run |
| `../cba-report-pch.txt` | full ClangBuildAnalyzer output for the canonical PCH run |
| `comparison.md` | median comparison: frontend/backend, build phases, per-TU, headers |
| `summary.json` | the same numbers in machine-readable form |
| `baseline/cba-report-N.txt` | raw CBA output of every baseline run (N=1..5) |
| `pch/cba-report-N.txt` | raw CBA output of every PCH run (N=1..5) |
| `baseline/cba-capture.bin`, `pch/cba-capture.bin` | CBA captures for `--analyze` |
| `*/tu-times-N.csv` | per-TU `Total Frontend` / `Total Backend` from the trace JSON |
| `*/phases-N.csv`, `*/ninja-log-N.log` | protobuf codegen / compile / link timings from `.ninja_log` |
| `*/timing.txt`, `*/time-N.txt` | clean-build wall clock |

Canonical summaries (medians):

* baseline: frontend 37.9 s, backend 16.4 s, CPU 54.3 s, wall 29.9 s, link 11.9 s
* PCH: frontend 27.5 s, backend 16.3 s, CPU 43.8 s, wall 29.5 s, link 11.9 s

The canonical root `cba-report*.txt` files are single runs (not medians); use
`comparison.md` for the aggregated numbers.

Reproduce: `scripts/run_all.sh` (or `scripts/run_in_docker.sh`).
