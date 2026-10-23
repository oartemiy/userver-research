#!/usr/bin/env python3
"""Parse ninja's .ninja_log into build-phase timings.

Usage: scripts/extract_phases.py <build_dir>/.ninja_log <out.csv>

Ninja writes start/end timestamps in milliseconds relative to the start of the
build. We report the end of protobuf/gRPC code generation, the end of the last
compilation, and the duration of the final link of the `research` executable.
"""

import csv
import os
import sys

GENERATED_SUFFIXES = (".h", ".hpp", ".cc", ".cpp")


def main():
    log_path, out_path = sys.argv[1], sys.argv[2]
    if not os.path.exists(log_path):
        raise SystemExit(f"no ninja log at {log_path}")

    entries = []
    with open(log_path, encoding="utf-8", errors="replace") as fh:
        for line in fh:
            if line.startswith("#"):
                continue
            parts = line.rstrip("\n").split("\t")
            if len(parts) < 5:
                continue
            try:
                start, end = float(parts[0]), float(parts[1])
            except ValueError:
                continue
            entries.append((start, end, parts[3]))

    generated = [
        e for e in entries
        if "/proto/handlers/" in e[2] and e[2].endswith(GENERATED_SUFFIXES)
    ]
    compilations = [
        e for e in entries
        if e[2].endswith((".o", ".a", ".pch"))
    ]
    links = [e for e in entries if os.path.basename(e[2]) == "research"]

    row = {
        "proto_gen_end_ms": max((e[1] for e in generated), default=0),
        "compile_end_ms": max((e[1] for e in compilations), default=0),
        "link_start_ms": min((e[0] for e in links), default=0),
        "link_ms": max((e[1] - e[0] for e in links), default=0),
        "total_ms": max((e[1] for e in entries), default=0),
    }
    with open(out_path, "w", newline="", encoding="utf-8") as fh:
        writer = csv.DictWriter(fh, fieldnames=list(row))
        writer.writeheader()
        writer.writerow(row)
    print(row)


if __name__ == "__main__":
    main()
