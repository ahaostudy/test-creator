#!/usr/bin/env bash
# adapter: node-vitest.sh — Node.js + Vitest adapter

detect() {
  if [[ -f "vitest.config.ts" || -f "vitest.config.js" || -f "vitest.config.mjs" ]]; then
    return 0
  fi
  if [[ -f "vite.config.ts" ]] && grep -q "test:" vite.config.ts 2>/dev/null; then
    return 0
  fi
  if [[ -f "package.json" ]] && grep -q '"vitest"' package.json 2>/dev/null; then
    return 0
  fi
  return 1
}

get_test_cmd() {
  if command -v npx &>/dev/null; then
    echo "npx vitest run"
  else
    echo "vitest run"
  fi
}

get_coverage_cmd() {
  echo "$(get_test_cmd) --coverage"
}

get_timing_cmd() {
  echo "$(get_test_cmd) --reporter=verbose"
}

parse_results() {
  local raw="$1"
  local passed failed total
  passed=$(echo "$raw" | grep -c "✓\|✔\|PASS" 2>/dev/null || echo "0")
  failed=$(echo "$raw" | grep -c "✗\|✘\|FAIL" 2>/dev/null || echo "0")
  total=$((passed + failed))
  echo "{\"total_cases\": $total, \"passed\": $passed, \"failed\": $failed}"
}

parse_coverage() {
  local raw="$1"
  # Vitest with --coverage outputs coverage-summary.json in coverage/ dir
  if [[ -f "coverage/coverage-summary.json" ]]; then
    jq '{
      line: .total.lines.pct,
      branch: .total.branches.pct,
      function: .total.functions.pct,
      uncovered_files: [to_entries[] | select(.key != "total" and .value.lines.pct == 0)] | length
    }' coverage/coverage-summary.json
  else
    echo '{"line": 0, "branch": 0, "function": 0, "uncovered_files": 0}'
  fi
}

parse_timing() {
  local raw="$1"
  echo '{"cases": [], "total_ms": 0}'
}
