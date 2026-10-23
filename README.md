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
* `make docker-COMMAND` - run `make COMMAND` in docker environment
* `make docker-clean-data` - stop docker containers


## Build-time profiling (test assignment)

The repo contains a reproducible experiment that measures where the build time
of this service goes and checks one optimization hypothesis (precompiled
headers). See [REPORT.md](REPORT.md) for the results.

### Quick start (recommended: Docker)

From the repository root:

```bash
scripts/run_in_docker.sh
```

This runs the whole experiment in the pinned assignment image with the required
limits: 4 CPUs, 8 GiB RAM, x86-64 Ubuntu 22.04. The first run needs network
access: it installs `clang-18` if needed and builds ClangBuildAnalyzer locally
into `.tools/ClangBuildAnalyzer`. Later runs reuse both.

For a quick smoke test (one build per mode instead of five):

```bash
REPS=1 scripts/run_in_docker.sh
```

### Quick start (already inside the image)

```bash
REPS=5 JOBS=4 scripts/run_all.sh
```

`scripts/run_all.sh` is self-contained: it prepares Clang, installs
ClangBuildAnalyzer into `.tools/ClangBuildAnalyzer` if it is missing, runs the
baseline and PCH measurements, and generates the comparison.

### What the scripts do

1. Install Clang 18 if the image does not have it (`scripts/setup_env.sh`; the
   base image ships without a compiler with `-ftime-trace`).
2. Locate ClangBuildAnalyzer, or clone and build it into
   `.tools/ClangBuildAnalyzer` (`scripts/bootstrap_cba.sh`). The analyzer is
   local to the checkout, so no system-wide installation is required.
3. For every mode (`baseline`, `pch`) and every repetition: remove the build
   directory, configure a Release build with Clang 18 and `-ftime-trace`,
   run `ClangBuildAnalyzer --start`, build `research` with `ninja -j4`, save
   `--stop`/`--analyze` output and the wall clock.
4. Produce `results/comparison.md`, `results/summary.json` and per-run raw
   reports `results/<mode>/cba-report-N.txt`.

Useful environment variables: `REPS` (default 5), `JOBS` (default 4),
`CBA=/path/to/ClangBuildAnalyzer` (use an existing binary instead of the local
build), `CBA_SRC=/path/to/ClangBuildAnalyzer` (use another source tree).

### Where to look after the run

```bash
cat results/comparison.md     # medians: frontend/backend, phases, per-TU
cat results/summary.json      # the same data for scripts
head -n 8 cba-report.txt      # canonical full CBA output, baseline
head -n 8 cba-report-pch.txt  # canonical full CBA output, PCH
```

The canonical root `cba-report*.txt` files are single runs; all numbers in
`REPORT.md` are medians of five clean builds.

The PCH hypothesis is enabled by `-DRESEARCH_USE_PCH=ON`; the precompiled
header sets are `src/pch_userver.hpp` and `src/pch_proto.hpp`.

Note: the image is x86-64. On Apple Silicon it runs under emulation, so
absolute times are distorted; baseline and PCH are measured under the same
conditions, so the relative deltas remain comparable (see REPORT.md).


## License

The original template is distributed under the [Apache-2.0 License](https://github.com/userver-framework/userver/blob/develop/LICENSE)
and [CLA](https://github.com/userver-framework/userver/blob/develop/CONTRIBUTING.md). Services based on the template may change
the license and CLA.
