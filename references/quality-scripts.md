# Quality Scripts Documentation

## Architecture

```
run-all-checks.sh (single entry point — agent only calls this)
  ├── auto-detects project language/framework
  ├── loads appropriate adapter from adapters/
  ├── executes 3 mechanical checks in sequence:
  │   ├── check-coverage.sh
  │   ├── check-flaky.sh
  │   └── check-performance.sh
  └── generates quality-report.json + quality-report.md
```

## Adapter Interface

Each adapter is a shell script implementing these functions:

```bash
detect()                    # Returns 0 if project matches this adapter, 1 otherwise
get_test_cmd()              # Prints base test command (e.g., "npm test")
get_coverage_cmd()          # Prints test command with coverage flags
get_timing_cmd()            # Prints test command with timing output flags
parse_results(raw_output)   # Parses framework output → standard JSON
parse_coverage(raw_output)  # Parses coverage output → standard JSON
parse_timing(raw_output)    # Parses timing output → standard JSON
```

### Adapter Directory

```
adapters/
├── node-jest.sh            # Node.js + Jest
├── node-vitest.sh          # Node.js + Vitest
├── python-pytest.sh        # Python + pytest
├── go-test.sh              # Go + go test
└── java-junit.sh           # Java + JUnit
```

### Detection Order

1. Check for `package.json` → try Node adapters (jest, vitest)
2. Check for `pyproject.toml` / `setup.py` → try Python adapter
3. Check for `go.mod` → try Go adapter
4. Check for `pom.xml` / `build.gradle` → try Java adapter
5. If no adapter matches, output error with instructions

### Reference Implementations

Start with `node-jest.sh` and `python-pytest.sh` as reference adapters. Others can be added following the same interface.

---

## run-all-checks.sh

### Usage

```bash
run-all-checks.sh --project-path <path> --test-cmd <command> [--config <path>] [--output <path>]
```

### Parameters

| Param | Required | Description |
|-------|----------|-------------|
| `--project-path` | Yes | Project root directory |
| `--test-cmd` | Yes | Test command (e.g., `npm test`, `pytest`, `go test ./...`) |
| `--config` | No | Config file path, defaults to `.test-creator-quality.json` |
| `--output` | No | Output directory, defaults to `.test-creator-reports/` |

### Configuration File

`.test-creator-quality.json`:

```json
{
  "coverage": {
    "line_threshold": 80,
    "branch_threshold": 70
  },
  "flaky": {
    "runs": 5
  },
  "performance": {
    "slow_unit_threshold_ms": 1000,
    "slow_api_threshold_ms": 5000,
    "slow_e2e_threshold_ms": 30000
  }
}
```

### Execution Flow

```
1. Parse arguments, load config (or use defaults)
2. Detect project language/framework → load adapter
3. Coverage check: run tests with coverage, parse output, compare thresholds
4. Stability check: run tests N times, diff results, flag inconsistencies
5. Performance check: run tests with timing, flag cases exceeding thresholds
6. Aggregate results → generate reports
```

### Output Files

#### quality-report.json

```json
{
  "timestamp": "2026-04-07T10:00:00Z",
  "project": "my-app",
  "detected_framework": "node-jest",
  "dimensions": {
    "coverage": {
      "pass": true,
      "line": 85.2,
      "branch": 72.1,
      "function": 90.5,
      "uncovered_files": 3
    },
    "flaky": {
      "pass": true,
      "rate": 1.5,
      "total_cases": 200,
      "flaky_cases": 3
    },
    "performance": {
      "pass": true,
      "total_ms": 480000,
      "slow_cases": 8
    }
  },
  "overall_pass": true,
  "issues": [
    {
      "dimension": "flaky",
      "severity": "medium",
      "file": "tests/api/order.test.js",
      "detail": "Failed 2 out of 5 runs",
      "suggestion": "Increase timeout or mock external dependencies"
    }
  ]
}
```

#### quality-report.md

```markdown
# Test Quality Report

## Summary
| Dimension | Result | Status |
|-----------|--------|--------|
| Coverage | 85.2% line / 72.1% branch | PASS |
| Stability | Flaky rate 1.5% | PASS |
| Performance | Total 8min | PASS |

## Issues
1. [Stability] tests/api/order.test.js — Flaky case
```

---

## Sub-scripts (internal, agent does not call directly)

| Script | Purpose |
|--------|---------|
| `check-coverage.sh` | Run tests with coverage, parse report, compare thresholds |
| `check-flaky.sh` | Re-run tests N times, flag inconsistent results |
| `check-performance.sh` | Record per-case timing, flag slow tests |

Each sub-script receives the adapter as input and uses its interface to interact with the test framework.
