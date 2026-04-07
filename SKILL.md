---
name: test-creator
description: >
  Build a complete, language-agnostic testing system for any project. Guides agents through
  deep project analysis, pre-research, test planning, implementation, and quality verification
  using a structured methodology. Covers API, E2E, Unit, and Integration testing with 6 mandatory
  test points per type. Includes automated quality scripts and sub-agent review workflows.
  USE THIS SKILL whenever the user mentions: testing, test suite, test coverage, writing tests,
  test automation, test framework, QA, quality assurance, E2E, unit tests, API tests,
  integration tests, test plan, test strategy, or wants to add/improve tests for their project.
---

# test-creator

Build a complete testing system for any project. This skill is **language/framework agnostic** — it defines methodology, not code generation.

**Core philosophy:** Testing exists to **expose problems, not hide them.** A test suite full of failures is more valuable than one that passes but misses real bugs.

**Skill boundary:** This skill covers test system development only. When tests reveal bugs, document them — do not fix the source code. The goal is a correct, comprehensive test system that accurately exposes the current state of the project.

---

## Workflow Overview

```
Step 0: Deep Project Analysis   — sub-agents extract APIs, pages, data models, logs
Step 1: Pre-research Q&A Page   — interactive HTML page collects user requirements
Step 1.5: Test Development Plan — written doc: what to test, how, where files go
Step 2: Test System Design      — generate test plan from user config + test matrix
Step 3: Implementation          — generate test files, mocks, fixtures, CI config
Step 4: Verification            — run-all-checks.sh produces quality report
Step 5: Quality Evaluation      — automated scripts + sub-agent deep review
```

**Every step must complete before proceeding.** Do not skip steps or merge them together.

---

## Step 0: Deep Project Analysis

**This step is mandatory and must be thorough.** Shallow analysis is the root cause of incomplete tests. Do not proceed to Step 1 until all 4 sub-agents have returned results.

### Run 4 sub-agents in parallel

Use the prompt templates in `references/project-analysis-prompts.md` to invoke:

| Sub-agent | Extracts |
|-----------|----------|
| API Discovery | Every endpoint: method, path, headers, request/response schema, auth, error codes |
| Page & UI Flow Discovery | Every page: URL, purpose, forms, user flows, data sources |
| Data Model & Storage Discovery | DB schema, ORM layer, connection config, cache, queues |
| Logging & Observability Discovery | Log library, config, output location, query command, what gets logged |

```
Author agent:
  → Sub-agent 1: API discovery       (parallel)
  → Sub-agent 2: Page discovery      (parallel)
  → Sub-agent 3: Data model          (parallel)
  → Sub-agent 4: Logging config      (parallel)
  ↓
Collect all 4 results before proceeding
```

### What to store from analysis results

- Complete endpoint inventory (used to ensure every endpoint has a test)
- Complete page/flow inventory (used to ensure every flow has an E2E test)
- DB connection string / config file path (used for Test Point 4: Data Validation)
- Log query command + format (used for Test Point 5: Log Validation)
- Tech stack + test framework (used for adapter selection in Step 4)

---

## Step 1: Pre-research Q&A Page

Generate an interactive HTML page so users can visually select options instead of answering questions one by one in the terminal.

Use `scripts/generate-qa-page.sh` to generate the page with project data injected from Step 0.

### What the page collects

**1. Test types (multi-select, all checked by default):**

| Type | Description |
|------|-------------|
| API Testing | Full API layer coverage — CRUD, auth, error handling |
| Page E2E Testing | Browser-based user flow verification |
| Unit Testing | Function/module-level logic verification |
| Integration Testing | Cross-module collaboration verification |

**2. Modules to cover:**

- Module list is auto-generated from Step 0 analysis
- All modules checked by default; all use the same selected test types

**3. Test environment:**

| Option | Use case |
|--------|----------|
| Dev environment | Quick iteration, early validation |
| Dedicated test/staging | Near-production verification |
| Production (read-only) | Smoke tests, monitoring |
| Temporary environment | Created per-run, destroyed after |
| Transaction rollback | DB tests without side effects |

URL supports **"Auto-detect"** — agent reads from project config.

**4. Database configuration (required for Test Point 4: Data Validation):**

| Option | Description |
|--------|-------------|
| Auto-detect | Agent reads DB connection from project config (default) |
| User provides | User supplies connection string and DB type manually |
| No database | In-memory store, skip DB-level validation |

**5. Log configuration (required for Test Point 5: Log Validation):**

| Option | Description |
|--------|-------------|
| Auto-detect | Agent reads log config from project (default) |
| User provides | User supplies log query method and format |
| No logging | Skip log validation tests |

**6. Test data strategy:**

| Option | Description |
|--------|-------------|
| User provides | Accounts, tokens, datasets supplied by user |
| Agent creates | Auto-generate mock data, cleanup after |
| Fixed fixtures | Pre-set data, same every run |
| Dynamic generation | Random data per run |

**7. Additional context:**

- Existing test coverage estimate?
- Known bugs or weak areas to focus on?
- CI/CD pipeline — should tests integrate?

### Page implementation flow

```
Step 0 results (endpoints, modules, stack)
  → scripts/generate-qa-page.sh injects data into HTML template
  → User opens page in browser, fills in selections
  → Page returns structured JSON to agent
  → Agent uses JSON to drive Steps 1.5 → 5
```

See `references/qa-page-spec.md` for HTML structure details.

---

## Step 1.5: Test Development Plan

Before writing any test code, produce a written test development plan document and confirm with the user.

### What the plan must contain

**File: `tests/TEST-PLAN.md`** (or equivalent path under the test directory)

```markdown
# Test Development Plan

## Project: <name>
## Generated: <date>
## Config: <summary of Q&A selections>

## Test Directory Structure
tests/
  api/          — API test files
  e2e/          — E2E test files
  unit/         — Unit test files
  integration/  — Integration test files
  fixtures/     — Shared test data and factories
  helpers/      — Shared test utilities
  TEST-PLAN.md  — This file

## API Test Coverage
For each endpoint from Step 0 analysis:
| Endpoint | Test file | 6 points covered |
|----------|-----------|-----------------|
| POST /api/v1/users | tests/api/test_users.py | 1,2,3,4,5,6 |
...

## E2E Test Coverage
For each page/flow from Step 0 analysis:
| Page/Flow | Test file | Scenarios |
|-----------|-----------|-----------|
| /login → /dashboard | tests/e2e/test_auth_flow.py | happy path, wrong password, session expiry |
...

## Data Validation Strategy
- DB connection: <how tests will connect to DB>
- Validation approach: <query pattern used to verify stored data>

## Log Validation Strategy
- Log query: <command to read logs during tests>
- Key operations to verify: <list>
```

**Do not begin implementation until the user has reviewed and approved this plan.**

---

## Step 2: Test System Design

Using the Q&A JSON output + the test matrix below, finalize the test plan.

### 4 Test Categories

| # | Type | Scope |
|---|------|-------|
| 1 | API Testing | CRUD, auth, pagination, concurrency, idempotency |
| 2 | Page E2E Testing | Core flows, forms, routing, async interactions, responsive |
| 3 | Unit Testing | Pure functions, data transforms, business rules, state machines |
| 4 | Integration Testing | DB consistency, 3rd-party services, message queues, caching |

### 6 Mandatory Test Points (per selected type)

Once a test type is selected, ALL 6 points must be covered. No cherry-picking. If a point genuinely does not apply (e.g., no HTTP layer in a unit test), add a comment explaining why — do not silently omit it.

| # | Test Point | What it checks |
|---|-----------|----------------|
| 1 | **Basic Effect** | Happy path: normal input → expected output |
| 2 | **Boundary Cases** | Empty values, max-length strings, extreme numbers, special chars, duplicate concurrent submissions |
| 3 | **Status Code Validation** | HTTP status + business status code dual verification — never just check 200 |
| 4 | **Data Validation** | Query storage layer directly after write — verify stored values match request, field by field |
| 5 | **Log Validation** | Key operations produce logs, correct log level, no sensitive data leakage |
| 6 | **Exception/Error Handling** | Graceful degradation on bad input, timeouts, service unavailability — no crashes, no silence |

**Test Point 4 — critical rule:** Data validation means querying the DB (or cache) directly, not inspecting response field types. See `references/test-coverage-details.md` for the correct pattern.

See `references/test-coverage-details.md` for per-type coverage specifics.

---

## Step 3: Implementation

### Test file organization

All test-related files go under a single `tests/` directory. Do not scatter test files in the project root or alongside source files (except unit tests co-located by framework convention).

```
tests/
  api/              — API tests
  e2e/              — E2E / browser tests
  unit/             — Unit tests
  integration/      — Integration tests
  fixtures/         — Test data factories and static fixtures
  helpers/          — Shared utilities (DB helpers, log capture, auth helpers)
  TEST-PLAN.md      — Test development plan (from Step 1.5)
  .test-creator-quality.json  — Quality thresholds config
```

### Generate the following

1. **Test files** — one file per module per test type, organized per structure above
2. **Fixtures** — data factories and static fixtures in `tests/fixtures/`
3. **Helpers** — DB query helpers, log capture utilities, auth token helpers in `tests/helpers/`
4. **Test runner config** — framework configuration file
5. **CI integration** — pipeline config if user requested it

### Implementation rules

- Every test file must cover all 6 mandatory test points for its module × type combination
- Test Point 4 must use direct DB/storage queries — never just inspect response fields
- Test Point 5 must capture and assert on actual log output
- Do not fix source code bugs found during implementation — document them in `tests/TEST-PLAN.md` under a "Known Issues" section

---

## Step 4: Verification

**After implementation, always run `run-all-checks.sh`. Do not run the test framework directly.**

`run-all-checks.sh` provides coverage analysis, flaky test detection, and performance profiling that raw test commands do not. Running `pytest` or `npm test` directly bypasses all of this.

### How to invoke

```bash
<skill-root>/scripts/run-all-checks.sh --project-path <path> --test-cmd <command> [--config <path>] [--output <path>]
```

For example, if your skill root is at `/home/user/.claude/skills/test-creator`:

```bash
/home/user/.claude/skills/test-creator/scripts/run-all-checks.sh \
  --project-path ./my-project \
  --test-cmd "npm test" \
  --output ./tests/quality-report.json
```

### What it does

1. Detects your test framework (Jest, pytest, Go test, etc.) via adapter
2. Runs tests with coverage and parses the results
3. Re-runs tests N times to detect flaky tests
4. Records per-case timing to flag slow tests
5. Generates `quality-report.json` and `quality-report.md` in the output path

### Available adapters

| Adapter | File | Detects |
|---------|------|---------|
| Node.js + Jest | `adapters/node-jest.sh` | `package.json` with jest, or `jest.config.*` |
| Node.js + Vitest | `adapters/node-vitest.sh` | `vitest.config.*` or vite config with test |
| Python + pytest | `adapters/python-pytest.sh` | `pyproject.toml`/`setup.cfg` with pytest, or `pytest.ini` |
| Go + go test | `adapters/go-test.sh` | `go.mod` file present |
| Java + JUnit | `adapters/java-junit.sh` | `pom.xml` or `build.gradle` |

If your project uses a framework not listed, create a new adapter following the interface in `references/quality-scripts.md`, then re-run.

### If the script fails

**Do NOT bypass it by running test commands directly.** Debug the failure:

1. Check if an adapter was detected — if not, create one for your framework
2. Check if the test command works when run directly — if not, fix test setup first
3. Check adapter functions — `detect()`, `get_test_cmd()`, `get_coverage_cmd()` must all work
4. Re-run the script after fixing

---

## Step 5: Quality Evaluation

Testing the tests. Two layers: **automated scripts** for mechanical checks, **sub-agent review** for semantic checks.

### Layer 1: Automated Quality Scripts (already done in Step 4)

The `run-all-checks.sh` output from Step 4 IS the Layer 1 result. Review the generated `quality-report.json` and `quality-report.md`.

**Config file** (`tests/.test-creator-quality.json`):

```json
{
  "coverage": { "line_threshold": 80, "branch_threshold": 70 },
  "flaky": { "runs": 5 },
  "performance": {
    "slow_unit_threshold_ms": 1000,
    "slow_api_threshold_ms": 5000,
    "slow_e2e_threshold_ms": 30000
  }
}
```

### Layer 2: Sub-agent Deep Review

Scripts cannot judge whether tests are *actually correct or sufficient*. That requires semantic analysis — and **must be done by a sub-agent, not the author agent.**

> An agent reviewing its own work has inherent bias. Sub-agent review provides adversarial perspective.

**How to invoke the sub-agent:**

1. Pass the sub-agent: `quality-report.json`, test file paths, source file paths, Q&A config JSON, and Step 0 project analysis results
2. Use the prompt template in `references/sub-agent-review-prompt.md`
3. Sub-agent returns a prioritized issue list
4. Author agent fixes issues, re-runs `run-all-checks.sh` + sub-agent review
5. Loop until all high/medium issues are resolved

**When bugs are found:** Document them in `tests/TEST-PLAN.md` under "Issues Found". Do not fix source code.

### Complete Quality Flow

```
Step 4: run-all-checks.sh → quality-report.json
  → Step 5 Layer 1: Review quality-report for mechanical issues
  → Step 5 Layer 2: Sub-agent review (report + tests + source + requirements + project analysis)
  → Merge: scripts = quantitative, sub-agent = qualitative
  → Fix test issues by severity → re-run run-all-checks.sh → re-invoke sub-agent → loop until clean
```

---

## Delivery Checklist

| Deliverable | Location | Description |
|-------------|----------|-------------|
| Q&A Page | `tests/qa-page.html` | Interactive HTML for requirement collection |
| Test Plan | `tests/TEST-PLAN.md` | Confirmed test design + coverage map + known issues |
| Test Files | `tests/api/`, `tests/e2e/`, `tests/unit/`, `tests/integration/` | Organized by type |
| Fixtures | `tests/fixtures/` | Test data factories and static fixtures |
| Helpers | `tests/helpers/` | DB query helpers, log capture, auth utilities |
| Test Config | project root or `tests/` | Framework + CI configuration |
| Quality Report | `tests/quality-report.json` | Generated by run-all-checks.sh |
