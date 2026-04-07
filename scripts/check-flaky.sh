#!/usr/bin/env bash
# check-flaky.sh — Stability dimension check
# Called by run-all-checks.sh, not directly by agent

run_flaky_check() {
  local project_path="$1"
  local test_cmd="$2"
  local runs="$3"

  cd "$project_path"

  local test_cmd_resolved
  test_cmd_resolved=$(get_test_cmd)

  echo "Running tests $runs times to detect flaky cases..."

  local results_dir
  results_dir=$(mktemp -d)
  local all_pass=true

  for i in $(seq 1 "$runs"); do
    echo "  Run $i/$runs..."
    local raw_output
    raw_output=$(eval "$test_cmd_resolved" 2>&1) || true
    local parsed
    parsed=$(parse_results "$raw_output")
    echo "$parsed" > "$results_dir/run-$i.json"
  done

  # Compare runs to find inconsistencies
  local total_cases
  total_cases=$(jq '.total_cases // 0' "$results_dir/run-1.json")
  local flaky_cases=0

  # Simple diff: if any run differs from the first, flag it
  for i in $(seq 2 "$runs"); do
    if ! diff <(jq -S . "$results_dir/run-1.json") <(jq -S . "$results_dir/run-$i.json") &>/dev/null; then
      all_pass=false
    fi
  done

  if [[ "$all_pass" == "false" ]]; then
    flaky_cases=1  # Simplified — real impl would diff per-case
  fi

  local rate=0
  if [[ "$total_cases" -gt 0 ]]; then
    rate=$(echo "scale=2; $flaky_cases * 100 / $total_cases" | bc -l 2>/dev/null || echo "0")
  fi

  echo "  Total cases: $total_cases"
  echo "  Flaky cases: $flaky_cases"
  echo "  Flaky rate: ${rate}%"

  # Write report
  cat > "$OUTPUT_DIR/flaky.json" <<EOF
{
  "pass": $all_pass,
  "rate": $rate,
  "total_cases": $total_cases,
  "flaky_cases": $flaky_cases
}
EOF

  rm -rf "$results_dir"
}
