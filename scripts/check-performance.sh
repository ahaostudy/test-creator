#!/usr/bin/env bash
# check-performance.sh — Performance dimension check
# Called by run-all-checks.sh, not directly by agent

run_performance_check() {
  local project_path="$1"
  local test_cmd="$2"
  local slow_threshold_ms="$3"

  cd "$project_path"

  local timing_cmd
  timing_cmd=$(get_timing_cmd)

  echo "Running tests with timing..."

  local start_ms
  start_ms=$(date +%s%N 2>/dev/null || echo "0")

  local raw_output
  raw_output=$(eval "$timing_cmd" 2>&1) || true

  local end_ms
  end_ms=$(date +%s%N 2>/dev/null || echo "0")

  local total_ms=0
  if [[ "$start_ms" != "0" && "$end_ms" != "0" ]]; then
    total_ms=$(( (end_ms - start_ms) / 1000000 ))
  fi

  local parsed
  parsed=$(parse_timing "$raw_output")

  local slow_cases
  slow_cases=$(echo "$parsed" | jq --argjson threshold "$slow_threshold_ms" \
    '[.cases[]? | select(.duration_ms > $threshold)] | length')

  echo "  Total duration: ${total_ms}ms"
  echo "  Slow cases (>${slow_threshold_ms}ms): $slow_cases"

  # Write report
  cat > "$OUTPUT_DIR/performance.json" <<EOF
{
  "pass": true,
  "total_ms": $total_ms,
  "slow_cases": $slow_cases
}
EOF
}
