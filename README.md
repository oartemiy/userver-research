# research

Template of a C++ service that uses [userver framework](https://github.com/userver-framework/userver).


## Download and Build

To create your own userver-based service follow the following steps:

1. Press the "Use this template button" at the top right of this GitHub page
2. Clone the service `git clone your-service-repo && cd your-service-repo && git submodule update --init`
3. Give a proper name to your service and replace all the occurrences of "research" string with that name
4. Feel free to tweak, adjust or fully rewrite the source code of your service.


## Makefile

`PRESET` is either `debug`, `release`, or if you've added custom presets in `CMakeUserPresets.json`, it
can also be `debug-custom`, `release-custom`.

* `make cmake-PRESET` - run cmake configure, update cmake options and source file lists
* `make build-PRESET` - build the service
* `make test-PRESET` - build the service and run all tests
* `make start-PRESET` - build the service, start it in testsuite environment and leave it running
* `make install-PRESET` - build the service and install it in directory set in environment `PREFIX`
* `make` or `make all` - build and run all tests in `debug` and `release` modes
* `make format` - reformat all C++ and Python sources
* `make dist-clean` - clean build files and cmake cache


## Build-time profiling (test assignment)

The repo contains a reproducible experiment that measures where the build time
of this service goes and checks one optimization hypothesis (precompiled
headers). See [report.pdf](report.pfd) for the results.

### Quick start (inside the prepared container)

From the repository root:

```bash
REPS=5 JOBS=4 scripts/run_all.sh
```

This runs the whole experiment in the prepared x86-64 Ubuntu 22.04 container
(4 CPUs, 8 GiB RAM). The first run needs network access: it installs `clang-18`
if needed and builds ClangBuildAnalyzer locally into `.tools/ClangBuildAnalyzer`.
Later runs reuse both.

For a quick smoke test (one build per mode instead of five):

```bash
REPS=1 scripts/run_all.sh
```

`scripts/run_all.sh` is self-contained: it prepares Clang, installs
ClangBuildAnalyzer into `.tools/ClangBuildAnalyzer` if it is missing, runs the
baseline and PCH measurements, and generates the comparison.

### Make targets

For a reviewer, the most useful shortcuts are:

```bash
make help                  # list all reviewer commands
make build                 # build the release target
make test                  # fast tests: unit test + benchmark
make test-all              # full ctest suite (needs PostgreSQL/MongoDB)
make check                 # alias for make test
make verify                # tests + one quick measurement
make measure-quick         # 1 clean build per mode (baseline, PCH)
make measure               # 5 clean builds per mode
make results               # print results/comparison.md
make results-quick         # print results-quick/comparison.md
make cba                   # print CBA time summaries
```

`make measure*` uses the scripts from this repository and installs
ClangBuildAnalyzer locally into `.tools/ClangBuildAnalyzer` on the first run.
`make measure-quick` writes to `results-quick/` and leaves the canonical
`results/` intact; `make measure` writes to `results/`.

### Reviewer checklist

See [REVIEWER.md](REVIEWER.md) for a short step-by-step path:
`make test` -> `make results` -> `make cba` -> optional `make measure-quick`.

### What the scripts do

1. Install Clang 18 if the environment does not have it (`scripts/setup_env.sh`).
2. Locate ClangBuildAnalyzer, or clone and build it into
   `.tools/ClangBuildAnalyzer` (`scripts/bootstrap_cba.sh`). The analyzer is
   local to the checkout, so no system-wide installation is required.
3. For every mode (`baseline`, `pch`) and every repetition: remove the build
   directory, configure a Release build with Clang 18 and `-ftime-trace`,
   run `ClangBuildAnalyzer --start`, build `research` with `ninja -j4`, save
   `--stop`/`--analyze` output and the wall clock.
4. Produce `results/comparison.md`, `results/summary.json` and per-run raw
   reports `results/<mode>/cba-report-N.txt` (or the same under `results-quick/`
   for a quick run).

Useful environment variables: `REPS` (default 5), `JOBS` (default 4),
`CBA=/path/to/ClangBuildAnalyzer` (use an existing binary instead of the local
build), `CBA_SRC=/path/to/ClangBuildAnalyzer` (use another source tree).

### Where to look after the run

```bash
cat results/comparison.md     # medians: frontend/backend, phases, per-TU
cat results/summary.json      # the same data for scripts
cat results-quick/comparison.md  # quick-run medians, if you ran make measure-quick
head -n 8 cba-report.txt      # canonical full CBA output, baseline
head -n 8 cba-report-pch.txt  # canonical full CBA output, PCH
```

The PCH hypothesis is enabled by `-DRESEARCH_USE_PCH=ON`; the precompiled
header sets are `src/pch_userver.hpp` and `src/pch_proto.hpp`.

Absolute times depend on the host and its current load. Baseline and PCH are
measured under the same conditions, so the relative deltas remain comparable


## License

The original template is distributed under the [Apache-2.0 License](https://github.com/userver-framework/userver/blob/develop/LICENSE)
and [CLA](https://github.com/userver-framework/userver/blob/develop/CONTRIBUTING.md). Services based on the template may change
the license and CLA.
