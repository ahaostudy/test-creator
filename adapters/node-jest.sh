#!/usr/bin/env bash
# adapter: node-jest.sh — Node.js + Jest adapter

detect() {
  if [[ -f "package.json" ]] && grep -q "jest" package.json 2>/dev/null; then
    return 0
  fi
  if [[ -f "jest.config.js" || -f "jest.config.ts" || -f "jest.config.json" ]]; then
    return 0
  fi
  return 1
}

get_test_cmd() {
  if [[ -f "package.json" ]] && jq -e '.scripts.test' package.json &>/dev/null; then
    echo "npm test --"
  else
    echo "npx jest"
  fi
}

get_coverage_cmd() {
  echo "$(get_test_cmd) --coverage --coverageReporters=json-summary --coverageReporters=text"
}

get_timing_cmd() {
  echo "$(get_test_cmd) --verbose"
}

parse_results() {
  local raw="$1"
  # Jest outputs JSON with --json flag; simplified parser
  echo '{"raw": "'$(echo "$raw" | head -c 500 | tr '\n' ' ')'", "total_cases": 0, "passed": 0, "failed": 0}'
}

parse_coverage() {
  local raw="$1"
  # Try to read coverage-summary.json if it exists
  if [[ -f "coverage/coverage-summary.json" ]]; then
    jq '{
      line: .total.lines.pct,
      branch: .total.branches.pct,
      function: .total.functions.pct,
      uncovered_files: [to_entries[] | select(.value.lines.pct == 0)] | length
    }' coverage/coverage-summary.json
  else
    echo '{"line": 0, "branch": 0, "function": 0, "uncovered_files": 0}'
  fi
}

parse_timing() {
  local raw="$1"
  echo '{"cases": [], "total_ms": 0}'
}
