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

One command in the pinned assignment environment (4 CPUs, 8 GiB, x86-64 image):

```bash
scripts/run_in_docker.sh          # or, inside the container: scripts/run_all.sh
```

What it does:

1. Installs Clang 18 if the image does not have it (`scripts/setup_env.sh`; the
   base image ships without a compiler with `-ftime-trace`).
2. Locates ClangBuildAnalyzer, or builds it to `~/tools/ClangBuildAnalyzer`
   (`scripts/bootstrap_cba.sh`).
3. For every mode (`baseline`, `pch`) and every repetition: removes the build
   directory, configures a Release build with Clang 18 and `-ftime-trace`,
   runs `ClangBuildAnalyzer --start`, builds `research` with `ninja -j4`,
   saves `--stop`/`--analyze` output and the wall clock.
4. Produces `results/comparison.md`, `results/summary.json` and per-run raw
   reports `results/<mode>/cba-report-N.txt`.

The first run needs network access to install `clang-18` and clone
ClangBuildAnalyzer; later runs reuse both.

Useful environment variables: `REPS` (default 5), `JOBS` (default 4),
`CBA=/path/to/ClangBuildAnalyzer`.

The PCH hypothesis is enabled by `-DRESEARCH_USE_PCH=ON`; the precompiled
header sets are `src/pch_userver.hpp` and `src/pch_proto.hpp`.

Note: the image is x86-64. On Apple Silicon it runs under emulation, so
absolute times are distorted; baseline and PCH are measured under the same
conditions, so the relative deltas remain comparable (see REPORT.md).


## License

The original template is distributed under the [Apache-2.0 License](https://github.com/userver-framework/userver/blob/develop/LICENSE)
and [CLA](https://github.com/userver-framework/userver/blob/develop/CONTRIBUTING.md). Services based on the template may change
the license and CLA.
