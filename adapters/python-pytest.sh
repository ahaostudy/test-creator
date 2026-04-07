#!/usr/bin/env bash
# adapter: python-pytest.sh — Python + pytest adapter

detect() {
  if [[ -f "pyproject.toml" ]] && grep -q "pytest" pyproject.toml 2>/dev/null; then
    return 0
  fi
  if [[ -f "setup.cfg" ]] && grep -q "pytest" setup.cfg 2>/dev/null; then
    return 0
  fi
  if [[ -f "pytest.ini" || -f "tox.ini" ]]; then
    return 0
  fi
  if command -v pytest &>/dev/null; then
    return 0
  fi
  return 1
}

get_test_cmd() {
  echo "pytest"
}

get_coverage_cmd() {
  echo "pytest --cov --cov-branch --cov-report=json --cov-report=term-missing"
}

get_timing_cmd() {
  echo "pytest --durations=0"
}

parse_results() {
  local raw="$1"
  local raw_escaped
  raw_escaped=$(echo "$raw" | head -c 500 | tr '\n' ' ' | jq -Rsa '.')
  # Parse pytest summary line like "5 passed, 2 failed in 1.23s"
  local passed=0 failed=0 total=0
  if echo "$raw" | grep -q " passed"; then
    passed=$(echo "$raw" | grep -oP '\d+(?= passed)' | head -1 || echo 0)
  fi
  if echo "$raw" | grep -q " failed"; then
    failed=$(echo "$raw" | grep -oP '\d+(?= failed)' | head -1 || echo 0)
  fi
  if echo "$raw" | grep -q " error"; then
    local errors
    errors=$(echo "$raw" | grep -oP '\d+(?= error)' | head -1 || echo 0)
    failed=$((failed + errors))
  fi
  total=$((passed + failed))
  echo "{\"raw\": $raw_escaped, \"total_cases\": $total, \"passed\": $passed, \"failed\": $failed}"
}

parse_coverage() {
  local raw="$1"
  if [[ -f "coverage.json" ]]; then
    jq '{
      line: .totals.percent_covered,
      branch: (.totals.percent_branches_covered // 0),
      function: 0,
      uncovered_files: [to_entries[] | select(.value.summary.percent_covered == 0)] | length
    }' coverage.json
  else
    echo '{"line": 0, "branch": 0, "function": 0, "uncovered_files": 0}'
  fi
}

parse_timing() {
  local raw="$1"
  # pytest --durations=0 outputs lines like "0.05s call test_foo.py::test_bar"
  local cases="[]"
  if echo "$raw" | grep -q "s call"; then
    cases=$(echo "$raw" | grep "s call" | awk '{
      gsub(/s/, "", $1)
      printf "{\"name\": \"%s\", \"duration_ms\": %s}\n", $3, $1*1000
    }' | jq -s '.')
  fi
  echo "{\"cases\": $cases}"
}
