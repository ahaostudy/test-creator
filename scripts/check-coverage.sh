#!/usr/bin/env bash
# check-coverage.sh — Coverage dimension check
# Called by run-all-checks.sh, not directly by agent

run_coverage_check() {
  local project_path="$1"
  local test_cmd="$2"
  local line_threshold="$3"
  local branch_threshold="$4"

  local coverage_cmd
  coverage_cmd=$(get_coverage_cmd)

  echo "Running: $coverage_cmd"
  cd "$project_path"

  local raw_output
  raw_output=$(eval "$coverage_cmd" 2>&1) || true

  local parsed
  parsed=$(parse_coverage "$raw_output")

  local line_cov
  line_cov=$(echo "$parsed" | jq -r '.line // 0')
  local branch_cov
  branch_cov=$(echo "$parsed" | jq -r '.branch // 0')

  local pass="true"
  if (( $(echo "$line_cov < $line_threshold" | bc -l 2>/dev/null || echo 0) )); then
    pass="false"
  fi
  if (( $(echo "$branch_cov < $branch_threshold" | bc -l 2>/dev/null || echo 0) )); then
    pass="false"
  fi

  echo "  Line coverage: ${line_cov}% (threshold: ${line_threshold}%)"
  echo "  Branch coverage: ${branch_cov}% (threshold: ${branch_threshold}%)"
  echo "  Pass: $pass"

  # Write to report
  echo "$parsed" | jq --arg pass "$pass" '. + {pass: ($pass == "true")}' \
    > "$OUTPUT_DIR/coverage.json"
}
