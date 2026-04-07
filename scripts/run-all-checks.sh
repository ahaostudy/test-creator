#!/usr/bin/env bash
# run-all-checks.sh — Single entry point for test quality evaluation
# Usage: run-all-checks.sh --project-path <path> --test-cmd <command> [--config <path>] [--output <path>]

set -euo pipefail

# ── Defaults ──────────────────────────────────────────────────────────────────
CONFIG_FILE=".test-creator-quality.json"
OUTPUT_DIR=""
PROJECT_PATH=""
TEST_CMD=""

# ── Parse arguments ───────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --project-path) PROJECT_PATH="$2"; shift 2 ;;
    --test-cmd)     TEST_CMD="$2";     shift 2 ;;
    --config)       CONFIG_FILE="$2";  shift 2 ;;
    --output)       OUTPUT_DIR="$2";   shift 2 ;;
    *) echo "Unknown argument: $1" >&2; exit 1 ;;
  esac
done

if [[ -z "$PROJECT_PATH" || -z "$TEST_CMD" ]]; then
  echo "Usage: run-all-checks.sh --project-path <path> --test-cmd <command> [--config <path>] [--output <path>]"
  exit 1
fi

if [[ -z "$OUTPUT_DIR" ]]; then
  OUTPUT_DIR="$PROJECT_PATH/tests"
fi

# ── Load config ───────────────────────────────────────────────────────────────
COVERAGE_LINE_THRESHOLD=80
COVERAGE_BRANCH_THRESHOLD=70
FLAKY_RUNS=5
SLOW_UNIT_MS=1000
SLOW_API_MS=5000
SLOW_E2E_MS=30000

if [[ -f "$CONFIG_FILE" ]]; then
  # Parse JSON config if jq is available
  if command -v jq &>/dev/null; then
    COVERAGE_LINE_THRESHOLD=$(jq -r '.coverage.line_threshold // 80' "$CONFIG_FILE")
    COVERAGE_BRANCH_THRESHOLD=$(jq -r '.coverage.branch_threshold // 70' "$CONFIG_FILE")
    FLAKY_RUNS=$(jq -r '.flaky.runs // 5' "$CONFIG_FILE")
    SLOW_UNIT_MS=$(jq -r '.performance.slow_unit_threshold_ms // 1000' "$CONFIG_FILE")
    SLOW_API_MS=$(jq -r '.performance.slow_api_threshold_ms // 5000' "$CONFIG_FILE")
    SLOW_E2E_MS=$(jq -r '.performance.slow_e2e_threshold_ms // 30000' "$CONFIG_FILE")
  fi
fi

# ── Detect adapter ────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ADAPTER_DIR="$SCRIPT_DIR/../adapters"
ADAPTER=""

if [[ -d "$ADAPTER_DIR" ]]; then
  for adapter_file in "$ADAPTER_DIR"/*.sh; do
    if [[ -f "$adapter_file" ]]; then
      source "$adapter_file"
      if detect; then
        ADAPTER="$adapter_file"
        break
      fi
    fi
  done
fi

if [[ -z "$ADAPTER" ]]; then
  echo '{"error": "No suitable adapter found for this project"}' >&2
  exit 1
fi

# ── Create output directory ───────────────────────────────────────────────────
mkdir -p "$OUTPUT_DIR"

# ── Run checks ───────────────────────────────────────────────────────────────
echo "Running quality checks with adapter: $(basename "$ADAPTER")"
echo "Project: $PROJECT_PATH"
echo "Test command: $TEST_CMD"
echo ""

# Source sub-scripts
source "$SCRIPT_DIR/check-coverage.sh"
source "$SCRIPT_DIR/check-flaky.sh"
source "$SCRIPT_DIR/check-performance.sh"

# Execute each check and collect results
echo "=== Coverage Check ==="
run_coverage_check "$PROJECT_PATH" "$TEST_CMD" "$COVERAGE_LINE_THRESHOLD" "$COVERAGE_BRANCH_THRESHOLD"

echo ""
echo "=== Stability Check ==="
run_flaky_check "$PROJECT_PATH" "$TEST_CMD" "$FLAKY_RUNS"

echo ""
echo "=== Performance Check ==="
run_performance_check "$PROJECT_PATH" "$TEST_CMD" "$SLOW_UNIT_MS"

echo ""
echo "=== Reports generated in $OUTPUT_DIR ==="
