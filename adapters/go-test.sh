#!/usr/bin/env bash
# adapter: go-test.sh — Go + go test adapter

detect() {
  if [[ -f "go.mod" ]]; then
    return 0
  fi
  return 1
}

get_test_cmd() {
  echo "go test -v -count=1 ./..."
}

get_coverage_cmd() {
  echo "go test -coverprofile=coverage.out ./... && go tool cover -func=coverage.out"
}

get_timing_cmd() {
  echo "go test -v -count=1 ./..."
}

parse_results() {
  local raw="$1"
  local passed failed total
  passed=$(echo "$raw" | grep -c "^--- PASS" 2>/dev/null || true)
  failed=$(echo "$raw" | grep -c "^--- FAIL" 2>/dev/null || true)
  passed=${passed:-0}
  failed=${failed:-0}
  total=$((passed + failed))
  echo "{\"total_cases\": $total, \"passed\": $passed, \"failed\": $failed}"
}

parse_coverage() {
  local raw="$1"
  if [[ -f "coverage.out" ]]; then
    local total_cov
    total_cov=$(go tool cover -func=coverage.out 2>/dev/null | grep "total:" | awk '{print $NF}' | tr -d '%')
    echo "{\"line\": ${total_cov:-0}, \"branch\": 0, \"function\": ${total_cov:-0}, \"uncovered_files\": 0}"
  else
    echo '{"line": 0, "branch": 0, "function": 0, "uncovered_files": 0}'
  fi
}

parse_timing() {
  local raw="$1"
  # Go test -v outputs lines like: --- PASS: TestFoo (0.00s)
  local cases
  cases=$(echo "$raw" | grep -E "^--- (PASS|FAIL):" | awk '{
    name = $3
    gsub(/[()]/, "", $4)
    duration = $4
    # Convert seconds to ms
    ms = duration * 1000
    printf "{\"name\": \"%s\", \"duration_ms\": %.0f}\n", name, ms
  }' | jq -s '.' 2>/dev/null || echo "[]")
  echo "{\"cases\": $cases}"
}
