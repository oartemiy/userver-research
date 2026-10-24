PROJECT_NAME = research
NPROCS ?= $(shell nproc)
CLANG_FORMAT ?= clang-format
CMAKE_OPTS ?=
PRESETS ?= debug release debug-custom release-custom
REPS ?= 5
JOBS ?= 4

.PHONY: all
all: test-debug test-release

# Run cmake
.PHONY: $(addprefix cmake-, $(PRESETS))
$(addprefix cmake-, $(PRESETS)): cmake-%:
	cmake --preset $* $(CMAKE_OPTS)

$(addsuffix /CMakeCache.txt, $(addprefix build-, $(PRESETS))): build-%/CMakeCache.txt:
	$(MAKE) cmake-$*

# Build using cmake
.PHONY: $(addprefix build-, $(PRESETS))
$(addprefix build-, $(PRESETS)): build-%: build-%/CMakeCache.txt
	cmake --build build-$* -j $(NPROCS) --target $(PROJECT_NAME)

# Test
.PHONY: $(addprefix test-, $(PRESETS))
$(addprefix test-, $(PRESETS)): test-%: build-%/CMakeCache.txt
	cmake --build build-$* -j $(NPROCS)
	cd build-$* && ((test -t 1 && GTEST_COLOR=1 TESTSUITE_ALLOW_ROOT=1 PYTEST_ADDOPTS="$${PYTEST_ADDOPTS:+$$PYTEST_ADDOPTS }--color=yes" ctest -V) || TESTSUITE_ALLOW_ROOT=1 ctest -V)

# Start the service (via testsuite service runner)
.PHONY: $(addprefix start-, $(PRESETS))
$(addprefix start-, $(PRESETS)): start-%:
	cmake --build build-$* -v --target start-$(PROJECT_NAME)

# Cleanup data
.PHONY: $(addprefix clean-, $(PRESETS))
$(addprefix clean-, $(PRESETS)): clean-%:
	cmake --build build-$* --target clean

.PHONY: dist-clean
dist-clean:
	rm -rf build*
	rm -rf tests/__pycache__/
	rm -rf tests/.pytest_cache/
	rm -rf .ccache
	rm -rf .vscode/.cache
	rm -rf .vscode/compile_commands.json

# Install
.PHONY: $(addprefix install-, $(PRESETS))
$(addprefix install-, $(PRESETS)): install-%: build-%
	cmake --install build-$* -v --component $(PROJECT_NAME)

.PHONY: install
install: install-release

# Format the sources
.PHONY: format
format:
	find src -name '*pp' -type f | xargs $(CLANG_FORMAT) -i
	find tests -name '*.py' -type f | xargs autopep8 -i

# Reviewer shortcuts (build-time experiment)
.PHONY: help build test test-fast test-all check verify measure measure-quick results results-quick cba report review clean-quick clean-results
help:
	@printf '%s\n' \
		'Targets:' \
		'  make build                 build the release target' \
		'  make test                  fast tests: unit test + benchmark (Release)' \
		'  make test-all              full ctest suite (needs PostgreSQL/MongoDB)' \
		'  make check                 alias for make test' \
		'  make verify                tests + one quick measurement' \
		'  make measure-quick         1 clean build per mode (baseline, PCH)' \
		'  make measure               5 clean builds per mode' \
		'  make results               print results/comparison.md' \
		'  make results-quick         print results-quick/comparison.md' \
		'  make cba                   print CBA time summaries' \
		'  make review                print REVIEWER.md' 

build: build-release
test: test-fast
test-fast: build-release/CMakeCache.txt
	cmake --build build-release -j $(NPROCS)
	cd build-release && TESTSUITE_ALLOW_ROOT=1 ctest -R 'research_unittest|research_benchmark' -V
test-all: test-release
check: test
verify: test measure-quick
measure:
	RESULTS_ROOT=results REPS=$(REPS) JOBS=$(JOBS) scripts/run_all.sh
measure-quick:
	RESULTS_ROOT=results-quick REPS=1 JOBS=$(JOBS) scripts/run_all.sh
results:
	@cat results/comparison.md
results-quick:
	@cat results-quick/comparison.md
cba:
	@printf '%s\n' '=== baseline ===' && head -n 8 cba-report.txt && printf '%s\n' '=== PCH ===' && head -n 8 cba-report-pch.txt
clean-quick:
	rm -rf results-quick
clean-results:
	rm -rf results results-quick
