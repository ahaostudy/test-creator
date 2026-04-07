#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# generate-qa-page.sh — Generate a test-config QA page
#
# Usage:
#   generate-qa-page.sh [OPTIONS]
#
# Options:
#   --project-name NAME        Project name (default: "my-project")
#   --project-desc DESC        Short description (default: "")
#   --modules MOD1,MOD2,...    Comma-separated module list (name:path,...)
#   --output PATH              Output file path (default: ./qa-page.html)
#
# Example:
#   generate-qa-page.sh \
#     --project-name "my-express-app" \
#     --project-desc "Node.js + Express 4.18 + Jest 29" \
#     --modules "user-model:src/models/user.js,order-model:src/models/order.js" \
#     --output ./qa-page.html
# ============================================================

PROJECT_NAME="my-project"
PROJECT_DESC=""
MODULES=""
OUTPUT="./qa-page.html"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project-name) PROJECT_NAME="$2"; shift 2 ;;
    --project-desc) PROJECT_DESC="$2"; shift 2 ;;
    --modules)      MODULES="$2"; shift 2 ;;
    --output)       OUTPUT="$2"; shift 2 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

# Build module JSON array
build_module_json() {
  if [[ -z "$MODULES" ]]; then
    echo '[]'
    return
  fi

  local result="["
  local first=true
  IFS=',' read -ra MODS <<< "$MODULES"
  for mod in "${MODS[@]}"; do
    local name="${mod%%:*}"
    local path="${mod#*:}"
    if [[ "$name" == "$path" ]]; then
      path=""
    fi
    if [[ "$first" == true ]]; then
      first=false
    else
      result+=","
    fi
    result+="{\"name\":\"$name\",\"path\":\"$path\"}"
  done
  result+="]"
  echo "$result"
}

MODULES_JSON="$(build_module_json)"

# Build project desc line
if [[ -n "$PROJECT_DESC" ]]; then
  DESC_LINE=" (${PROJECT_DESC})"
else
  DESC_LINE=""
fi

# Write template to a temp file first (avoid sed conflicting with JS/content)
TMPFILE="$(mktemp)"
trap 'rm -f "$TMPFILE"' EXIT

cat > "$TMPFILE" << 'HTMLEOF'
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Test Configuration — %%PROJECT_NAME%%</title>
<style>
  * { box-sizing: border-box; margin: 0; padding: 0; }
  body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background: #f5f7fa; color: #1a1a2e; line-height: 1.6; padding: 24px; }
  .container { max-width: 960px; margin: 0 auto; }
  h1 { font-size: 1.8rem; margin-bottom: 8px; color: #16213e; }
  .subtitle { color: #666; margin-bottom: 32px; }
  .section { background: #fff; border-radius: 12px; padding: 24px; margin-bottom: 20px; box-shadow: 0 1px 3px rgba(0,0,0,0.08); }
  .section h2 { font-size: 1.2rem; margin-bottom: 16px; color: #0f3460; border-bottom: 2px solid #e8eaf0; padding-bottom: 8px; }
  .section h3 { font-size: 1rem; margin: 16px 0 8px; color: #333; }
  label { display: block; margin-bottom: 8px; cursor: pointer; }
  input[type="checkbox"], input[type="radio"] { margin-right: 8px; cursor: pointer; }
  .checkbox-group label, .radio-group label { padding: 8px 12px; border-radius: 6px; transition: background 0.15s; }
  .checkbox-group label:hover, .radio-group label:hover { background: #f0f4ff; }
  input[type="text"], textarea { width: 100%; padding: 10px 12px; border: 1px solid #d1d5db; border-radius: 6px; font-size: 0.95rem; margin-top: 4px; }
  textarea { min-height: 80px; resize: vertical; }
  .hint { font-size: 0.85rem; color: #888; margin-top: 2px; }
  .btn { display: inline-block; padding: 12px 32px; background: #4361ee; color: #fff; border: none; border-radius: 8px; font-size: 1rem; font-weight: 600; cursor: pointer; transition: background 0.2s; }
  .btn:hover { background: #3a56d4; }
  .btn-sm { padding: 6px 16px; font-size: 0.85rem; border-radius: 6px; background: #6366f1; margin-left: 8px; vertical-align: middle; }
  .btn-sm:hover { background: #4f46e5; }
  #output { display: none; margin-top: 24px; }
  #output pre { background: #1e293b; color: #e2e8f0; padding: 20px; border-radius: 8px; overflow-x: auto; font-size: 0.9rem; max-height: 500px; }
  .actions { display: flex; gap: 12px; margin-top: 12px; }
  .btn-secondary { background: #6b7280; }
  .btn-secondary:hover { background: #4b5563; }
  .error { color: #dc2626; font-size: 0.9rem; margin-top: 8px; display: none; }
  .info-box { background: #eff6ff; border: 1px solid #bfdbfe; border-radius: 8px; padding: 12px 16px; margin-bottom: 16px; font-size: 0.9rem; color: #1e40af; }
  .desc { display: inline-block; font-size: 0.85rem; color: #6b7280; margin-left: 4px; }
  .input-row { display: flex; align-items: center; gap: 8px; margin-top: 4px; }
  .input-row input[type="text"] { flex: 1; margin-top: 0; }
</style>
</head>
<body>
<div class="container">
  <h1>Test Configuration Wizard</h1>
  <p class="subtitle">Project: <strong>%%PROJECT_NAME%%</strong>%%PROJECT_DESC%%</p>

  <div class="info-box">
    Select your testing requirements below, then click <strong>Generate Config</strong> to produce the JSON configuration that drives the test plan.
  </div>

  <!-- Section 1: Test Types -->
  <div class="section">
    <h2>1. Test Types</h2>
    <p class="hint">Select which test types to include. All modules will use the same selection (unsupported types will be skipped).</p>
    <div class="checkbox-group" style="margin-top: 12px;">
      <label><input type="checkbox" name="test_type" value="api" checked> API Testing <span class="desc">CRUD, auth, pagination, error handling</span></label>
      <label><input type="checkbox" name="test_type" value="e2e" checked> Page E2E Testing <span class="desc">Browser-based user flows</span></label>
      <label><input type="checkbox" name="test_type" value="unit" checked> Unit Testing <span class="desc">Function/module-level logic</span></label>
      <label><input type="checkbox" name="test_type" value="integration" checked> Integration Testing <span class="desc">Cross-module collaboration</span></label>
    </div>
    <div class="error" id="testTypeErr">Please select at least one test type.</div>
  </div>

  <!-- Section 2: Modules -->
  <div class="section">
    <h2>2. Modules</h2>
    <p class="hint">Modules detected from project analysis. All selected test types apply to every module.</p>
    <div id="moduleList" class="checkbox-group" style="margin-top: 12px;"></div>
  </div>

  <!-- Section 3: Test Environment -->
  <div class="section">
    <h2>3. Test Environment</h2>
    <div class="radio-group">
      <label><input type="radio" name="env_type" value="dev" checked> Dev environment</label>
      <label><input type="radio" name="env_type" value="staging"> Dedicated test/staging</label>
      <label><input type="radio" name="env_type" value="production_readonly"> Production (read-only)</label>
      <label><input type="radio" name="env_type" value="temporary"> Temporary environment</label>
      <label><input type="radio" name="env_type" value="transaction_rollback"> Transaction rollback</label>
    </div>
    <h3 style="margin-top: 16px;">Environment Details</h3>
    <label style="margin-top: 8px;">
      URL
      <div class="input-row">
        <input type="text" name="env_url" value="http://localhost:3000" placeholder="http://localhost:3000">
        <button type="button" class="btn btn-sm" onclick="agentFetch('env_url')">Auto-detect</button>
      </div>
    </label>
    <label>Auth Method
      <input type="text" name="auth_method" value="none" placeholder="none, bearer_token, api_key, basic">
    </label>
  </div>

  <!-- Section 4: Database Config -->
  <div class="section">
    <h2>4. Database Configuration</h2>
    <div class="radio-group">
      <label><input type="radio" name="db_mode" value="agent_auto" checked> Auto-detect <span class="desc">Agent reads connection from project config</span></label>
      <label><input type="radio" name="db_mode" value="user_provide"> User provides connection</label>
      <label><input type="radio" name="db_mode" value="none"> No database / In-memory</label>
    </div>
    <div id="dbManual" style="display: none; margin-top: 12px;">
      <label>Connection string
        <input type="text" name="db_connection" placeholder="e.g., postgres://user:pass@localhost:5432/mydb">
      </label>
      <label style="margin-top: 8px;">Database type
        <input type="text" name="db_type" placeholder="e.g., mysql, postgres, mongodb, sqlite">
      </label>
    </div>
  </div>

  <!-- Section 5: Log Configuration -->
  <div class="section">
    <h2>5. Log Configuration</h2>
    <div class="radio-group">
      <label><input type="radio" name="log_mode" value="agent_auto" checked> Auto-detect <span class="desc">Agent reads log config from project</span></label>
      <label><input type="radio" name="log_mode" value="user_provide"> User provides log query method</label>
      <label><input type="radio" name="log_mode" value="none"> No logging / Skip log validation</label>
    </div>
    <div id="logManual" style="display: none; margin-top: 12px;">
      <label>Log location / query command
        <input type="text" name="log_query" placeholder="e.g., tail -f ./logs/app.log, or journalctl -u myapp">
      </label>
      <label style="margin-top: 8px;">Log format
        <input type="text" name="log_format" placeholder="e.g., json, text, winston, pino">
      </label>
    </div>
  </div>

  <!-- Section 6: Test Data Strategy -->
  <div class="section">
    <h2>6. Test Data Strategy</h2>
    <div class="radio-group">
      <label><input type="radio" name="data_strategy" value="user_provides"> User provides test accounts/data</label>
      <label><input type="radio" name="data_strategy" value="agent_creates" checked> Agent creates mock data</label>
      <label><input type="radio" name="data_strategy" value="fixed_fixtures"> Fixed fixtures (pre-set, same every run)</label>
      <label><input type="radio" name="data_strategy" value="dynamic"> Dynamic generation (random per run)</label>
    </div>
  </div>

  <!-- Section 7: Additional Context -->
  <div class="section">
    <h2>7. Additional Context</h2>
    <label>Existing test coverage estimate
      <input type="text" name="existing_coverage" value="No existing tests" placeholder="e.g., 20%, or 'No existing tests'">
    </label>
    <label style="margin-top: 12px;">Known bugs or weak areas
      <textarea name="known_issues" placeholder="e.g., Payment timeout on slow networks"></textarea>
    </label>
    <label style="margin-top: 12px;">CI/CD pipeline
      <input type="text" name="ci_cd" value="None configured" placeholder="e.g., GitHub Actions, run on PR">
    </label>
  </div>

  <!-- Actions -->
  <div style="text-align: center; margin: 32px 0;">
    <button class="btn" onclick="generateConfig()">Generate Config</button>
  </div>

  <!-- Output -->
  <div id="output">
    <div class="section">
      <h2>Generated Configuration JSON</h2>
      <pre id="jsonOutput"></pre>
      <div class="actions">
        <button class="btn btn-secondary" onclick="copyToClipboard()">Copy to Clipboard</button>
        <button class="btn btn-secondary" onclick="downloadJson()">Download as File</button>
      </div>
    </div>
  </div>
</div>

<script>
const __MODULES__ = %%MODULES_JSON%%;

// Render modules
(function() {
  const container = document.getElementById('moduleList');
  if (__MODULES__.length === 0) {
    container.innerHTML = '<p class="hint">No modules detected. Agent will auto-discover modules during analysis.</p>';
    return;
  }
  __MODULES__.forEach(function(mod) {
    const label = document.createElement('label');
    const cb = document.createElement('input');
    cb.type = 'checkbox';
    cb.name = 'module';
    cb.value = mod.name;
    cb.checked = true;
    label.appendChild(cb);
    label.appendChild(document.createTextNode(mod.name));
    if (mod.path) {
      const span = document.createElement('span');
      span.className = 'desc';
      span.textContent = mod.path;
      label.appendChild(span);
    }
    container.appendChild(label);
  });
})();

// Toggle db manual fields
document.querySelectorAll('input[name="db_mode"]').forEach(function(radio) {
  radio.addEventListener('change', function() {
    document.getElementById('dbManual').style.display = this.value === 'user_provide' ? 'block' : 'none';
  });
});

// Toggle log manual fields
document.querySelectorAll('input[name="log_mode"]').forEach(function(radio) {
  radio.addEventListener('change', function() {
    document.getElementById('logManual').style.display = this.value === 'user_provide' ? 'block' : 'none';
  });
});

// Agent auto-fetch placeholder
function agentFetch(field) {
  var input = document.querySelector('input[name="' + field + '"]');
  input.value = '[Agent will auto-detect]';
  input.style.color = '#6366f1';
}

function generateConfig() {
  // Validate test types
  const testTypes = [...document.querySelectorAll('input[name="test_type"]:checked')].map(function(el) { return el.value; });
  const testTypeErr = document.getElementById('testTypeErr');
  if (testTypes.length === 0) { testTypeErr.style.display = 'block'; return; }
  testTypeErr.style.display = 'none';

  // Modules
  const modules = [...document.querySelectorAll('input[name="module"]:checked')].map(function(el) { return el.value; });

  // DB config
  const dbMode = document.querySelector('input[name="db_mode"]:checked').value;
  const dbConfig = { mode: dbMode };
  if (dbMode === 'user_provide') {
    dbConfig.connection = document.querySelector('input[name="db_connection"]').value;
    dbConfig.type = document.querySelector('input[name="db_type"]').value;
  }

  // Log config
  const logMode = document.querySelector('input[name="log_mode"]:checked').value;
  const logConfig = { mode: logMode };
  if (logMode === 'user_provide') {
    logConfig.query = document.querySelector('input[name="log_query"]').value;
    logConfig.format = document.querySelector('input[name="log_format"]').value;
  }

  const config = {
    test_types: testTypes,
    modules: modules,
    environment: {
      type: document.querySelector('input[name="env_type"]:checked').value,
      url: document.querySelector('input[name="env_url"]').value,
      auth_method: document.querySelector('input[name="auth_method"]').value
    },
    database: dbConfig,
    logging: logConfig,
    test_data: {
      strategy: document.querySelector('input[name="data_strategy"]:checked').value
    },
    additional_context: {
      existing_coverage: document.querySelector('input[name="existing_coverage"]').value,
      known_issues: document.querySelector('textarea[name="known_issues"]').value,
      ci_cd: document.querySelector('input[name="ci_cd"]').value
    }
  };

  document.getElementById('jsonOutput').textContent = JSON.stringify(config, null, 2);
  document.getElementById('output').style.display = 'block';
  window.__generatedConfig = config;
}

function copyToClipboard() {
  navigator.clipboard.writeText(JSON.stringify(window.__generatedConfig, null, 2));
  alert('Copied to clipboard!');
}

function downloadJson() {
  var blob = new Blob([JSON.stringify(window.__generatedConfig, null, 2)], { type: 'application/json' });
  var a = document.createElement('a');
  a.href = URL.createObjectURL(blob);
  a.download = 'test-config.json';
  a.click();
}
</script>
</body>
</html>
HTMLEOF

# Replace placeholders using python for safe multi-line/string replacement
python3 - "$TMPFILE" "$OUTPUT" "$PROJECT_NAME" "$DESC_LINE" "$MODULES_JSON" << 'PYEOF'
import sys

tmpfile = sys.argv[1]
outfile = sys.argv[2]
project_name = sys.argv[3]
desc_line = sys.argv[4]
modules_json = sys.argv[5]

with open(tmpfile, 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace('%%PROJECT_NAME%%', project_name)
content = content.replace('%%PROJECT_DESC%%', desc_line)
content = content.replace('%%MODULES_JSON%%', modules_json)

with open(outfile, 'w', encoding='utf-8') as f:
    f.write(content)
PYEOF

echo "QA page generated: $OUTPUT"

# Print file:// URL for direct browser access
ABS_OUTPUT="$(cd "$(dirname "$OUTPUT")" && pwd)/$(basename "$OUTPUT")"
echo "Open in browser: file://$ABS_OUTPUT"
