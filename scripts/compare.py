#!/usr/bin/env python3
"""Compare ClangBuildAnalyzer reports produced by scripts/measure.sh.

Usage: scripts/compare.py

Reads results/<mode>/{cba-report-N.txt,tu-times-N.csv,phases-N.csv,timing.txt}
for the modes "baseline" and "pch", prints median-based markdown tables and
writes results/comparison.md + results/summary.json.
"""

import csv
import glob
import json
import os
import re
import statistics

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RESULTS = os.environ.get("RESULTS_ROOT", os.path.join(ROOT, "results"))
MODES = ["baseline", "pch"]

RE_SUMMARY = re.compile(r"Compilation \((\d+) times\)")
RE_FRONTEND = re.compile(r"Parsing \(frontend\):\s+([\d.]+) s")
RE_BACKEND = re.compile(r"Codegen & opts \(backend\):\s+([\d.]+) s")
RE_RUN = re.compile(r"run=(\d+) build_rc=(\d+) wall_s=([\d.]+)")
RE_FILE = re.compile(r"^\s+(\d+) ms: (\S+)$")
RE_HEADER = re.compile(r"^(\d+) ms: (.*?) \(included (\d+) times, avg (\d+) ms\)")
RE_TARGET = re.compile(r"^CMakeFiles/([^/]+)\.dir/(.*)$")

PHASES = ["proto_gen_end_ms", "compile_end_ms", "link_ms", "total_ms"]


def median(values):
    return statistics.median(values) if values else None


def header_key(path):
    path = path.strip()
    if path.startswith(ROOT + "/"):
        path = path[len(ROOT) + 1:]
    elif path.startswith("/usr/include/"):
        path = path[len("/usr/include/"):]
    else:
        match = re.match(r"^.*?/build-[^/]+/(.*)$", path)
        if match:
            path = match.group(1)
    return re.sub(r"^build-[^/]+/", "", path)


def tu_key(relpath):
    rel = relpath.replace("\\", "/")
    if rel.endswith(".json"):
        rel = rel[:-5]
    match = RE_TARGET.match(rel)
    if not match:
        return rel
    target, rest = match.group(1), match.group(2)
    if rest == "cmake_pch.hxx":
        return f"cmake_pch.hxx [{target}]"
    return rest


def parse_report(path):
    text = open(path, encoding="utf-8", errors="replace").read()
    m = RE_SUMMARY.search(text)
    f = RE_FRONTEND.search(text)
    b = RE_BACKEND.search(text)
    if not (m and f and b):
        raise ValueError(f"cannot parse summary in {path}")

    files, headers = {}, {}
    for line in text.splitlines():
        fm = RE_FILE.match(line)
        if fm:
            files[os.path.basename(fm.group(2))] = int(fm.group(1))
        hm = RE_HEADER.match(line)
        if hm:
            headers[header_key(hm.group(2))] = int(hm.group(1))

    return {
        "compilations": int(m.group(1)),
        "frontend_s": float(f.group(1)),
        "backend_s": float(b.group(1)),
        "files_ms": files,
        "headers_ms": headers,
    }


def numbered(directory, prefix, suffix):
    return sorted(
        glob.glob(os.path.join(directory, f"{prefix}-[0-9]*{suffix}")),
        key=lambda p: int(re.search(r"-(\d+)" + re.escape(suffix) + r"$", p).group(1)),
    )


def load_tu_csv(directory):
    """Median per-TU times over all runs, keyed by normalized TU name."""
    runs = []
    for path in numbered(directory, "tu-times", ".csv"):
        rows = {}
        with open(path, newline="", encoding="utf-8") as fh:
            for row in csv.DictReader(fh):
                rows[tu_key(row["tu"])] = (float(row["frontend_ms"]), float(row["backend_ms"]))
        runs.append(rows)

    result = {}
    for name in {n for run in runs for n in run}:
        frontends = [run[name][0] for run in runs if name in run]
        backends = [run[name][1] for run in runs if name in run]
        result[name] = (median(frontends), median(backends), len(frontends))
    return result


def load_phases(directory):
    runs = []
    for path in numbered(directory, "phases", ".csv"):
        with open(path, newline="", encoding="utf-8") as fh:
            rows = list(csv.DictReader(fh))
        if rows:
            runs.append({key: float(rows[0][key]) for key in PHASES})
    return {key: median([run[key] for run in runs]) for key in PHASES} if runs else {}


def load_mode(mode):
    directory = os.path.join(RESULTS, mode)
    reports = numbered(directory, "cba-report", ".txt")
    if not reports:
        raise SystemExit(f"no reports in {directory}; run scripts/measure.sh {mode} first")

    runs = [parse_report(p) for p in reports]
    walls = []
    timing = os.path.join(directory, "timing.txt")
    if os.path.exists(timing):
        for line in open(timing, encoding="utf-8"):
            rm = RE_RUN.search(line)
            if rm:
                walls.append(float(rm.group(3)))

    headers = {}
    for name in {n for r in runs for n in r["headers_ms"]}:
        values = [r["headers_ms"][name] for r in runs if name in r["headers_ms"]]
        headers[name] = median(values)

    return {
        "runs": runs,
        "walls": walls,
        "frontend": median([r["frontend_s"] for r in runs]),
        "backend": median([r["backend_s"] for r in runs]),
        "wall": median(walls),
        "compilations": runs[0]["compilations"],
        "tu": load_tu_csv(directory),
        "phases": load_phases(directory),
        "headers": headers,
    }


def pct(new, old):
    return 100.0 * (new - old) / old if old else 0.0


def cell(value, unit=""):
    return "n/a" if value is None else f"{value:.1f}{unit}"


def delta_cell(new, old):
    if new is None or old is None:
        return "n/a"
    return f"{new - old:+.1f} ({pct(new, old):+.1f}%)"


def main():
    data = {mode: load_mode(mode) for mode in MODES}
    base, exp = data["baseline"], data["pch"]

    lines = []
    lines.append("# Baseline vs PCH (median of repeated clean builds)\n")
    lines.append(
        f"Runs: baseline={len(base['runs'])}, pch={len(exp['runs'])}. "
        "Each run is a clean configure + `ninja research` with `-ftime-trace`. "
        "Frontend/backend are CBA sums over all traced compilations, "
        "including the 3 PCH builds in the PCH mode.\n"
    )
    lines.append("| metric | baseline | PCH | delta |")
    lines.append("|---|---:|---:|---:|")
    base_cpu = base["frontend"] + base["backend"]
    exp_cpu = exp["frontend"] + exp["backend"]
    rows = [
        ("TUs compiled (incl. PCH)", f"{base['compilations']}", f"{exp['compilations']}",
         f"{exp['compilations'] - base['compilations']:+d}"),
        ("frontend, s", cell(base["frontend"]), cell(exp["frontend"]), delta_cell(exp["frontend"], base["frontend"])),
        ("backend, s", cell(base["backend"]), cell(exp["backend"]), delta_cell(exp["backend"], base["backend"])),
        ("compile CPU total, s", cell(base_cpu), cell(exp_cpu), delta_cell(exp_cpu, base_cpu)),
        ("wall clock, s", cell(base["wall"]), cell(exp["wall"]), delta_cell(exp["wall"], base["wall"])),
    ]
    for label, b, e, d in rows:
        lines.append(f"| {label} | {b} | {e} | {d} |")

    if base["phases"] and exp["phases"]:
        lines.append("\n## Build phases from .ninja_log (median, ms)\n")
        lines.append("| phase | baseline | PCH | delta |")
        lines.append("|---|---:|---:|---:|")
        phase_rows = [
            ("protobuf/gRPC codegen finished at", "proto_gen_end_ms"),
            ("compilation finished at", "compile_end_ms"),
            ("link `research`", "link_ms"),
            ("build total", "total_ms"),
        ]
        for label, key in phase_rows:
            b, e = base["phases"].get(key), exp["phases"].get(key)
            lines.append(f"| {label} | {cell(b)} | {cell(e)} | {delta_cell(e, b)} |")

    lines.append("\n## Per-run wall clock, s\n")
    lines.append("| run | baseline | pch |")
    lines.append("|---|---:|---:|")
    for i in range(max(len(base["walls"]), len(exp["walls"]))):
        b = f"{base['walls'][i]:.2f}" if i < len(base["walls"]) else ""
        e = f"{exp['walls'][i]:.2f}" if i < len(exp["walls"]) else ""
        lines.append(f"| {i + 1} | {b} | {e} |")

    lines.append("\n## Translation units by frontend time (median, ms)\n")
    lines.append("| TU | baseline | PCH | delta |")
    lines.append("|---|---:|---:|---:|")
    names = sorted(
        set(base["tu"]) | set(exp["tu"]),
        key=lambda n: (base["tu"].get(n, (0,))[0] or 0),
        reverse=True,
    )
    for name in names:
        b = base["tu"].get(name, (None, None, 0))[0]
        e = exp["tu"].get(name, (None, None, 0))[0]
        lines.append(f"| `{name}` | {cell(b)} | {cell(e)} | {delta_cell(e, b)} |")

    lines.append("\n## Top headers by inclusive parse time (median, ms)\n")
    lines.append("| header | baseline | PCH |")
    lines.append("|---|---:|---:|")
    top_h = sorted(base["headers"], key=lambda n: base["headers"][n] or 0, reverse=True)[:10]
    for name in top_h:
        lines.append(f"| `{name}` | {cell(base['headers'][name])} | {cell(exp['headers'].get(name))} |")

    report = "\n".join(lines) + "\n"
    print(report)
    with open(os.path.join(RESULTS, "comparison.md"), "w", encoding="utf-8") as fh:
        fh.write(report)

    summary = {
        mode: {
            "runs": len(mode_data["runs"]),
            "compilations": mode_data["compilations"],
            "frontend_s": mode_data["frontend"],
            "backend_s": mode_data["backend"],
            "cpu_total_s": mode_data["frontend"] + mode_data["backend"],
            "wall_s": mode_data["wall"],
            "walls_s": mode_data["walls"],
            "phases_median_ms": mode_data["phases"],
            "tu_median_ms": {
                name: {"frontend": value[0], "backend": value[1], "runs": value[2]}
                for name, value in mode_data["tu"].items()
            },
            "headers_median_ms": mode_data["headers"],
        }
        for mode, mode_data in data.items()
    }
    with open(os.path.join(RESULTS, "summary.json"), "w", encoding="utf-8") as fh:
        json.dump(summary, fh, indent=2, ensure_ascii=False)


if __name__ == "__main__":
    main()
