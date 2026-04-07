---
name: test-creator
description: >
  Build a complete, language-agnostic testing system for any project. Guides agents through
  pre-research, test planning, implementation, and quality verification using a structured
  methodology. Covers API, E2E, Unit, and Integration testing with 6 mandatory test points
  per type. Includes automated quality scripts and sub-agent review workflows.
  USE THIS SKILL whenever the user mentions: testing, test suite, test coverage, writing tests,
  test automation, test framework, QA, quality assurance, E2E, unit tests, API tests,
  integration tests, test plan, test strategy, or wants to add/improve tests for their project.
---

# test-creator

Build a complete testing system for any project. This skill is **language/framework agnostic** — it defines methodology, not code generation.

**Core philosophy:** Testing exists to **expose problems, not hide them.** A test suite full of failures is more valuable than one that passes but misses real bugs.

---

## Workflow Overview

```
Step 0: Project Analysis        — scan tech stack, modules, existing tests
Step 1: Pre-research Q&A Page   — interactive HTML page collects user requirements
Step 2: Test System Design      — generate test plan from user config + test matrix
Step 3: Implementation          — generate test files, mocks, fixtures, CI config
Step 4: Verification            — run tests, generate coverage via run-all-checks.sh
Step 5: Quality Evaluation      — automated scripts + sub-agent deep review
```

**Every step must complete before proceeding.** Do not skip steps or merge them together.

---

## Step 0: Project Analysis

Before anything else, scan the project to understand:

1. **Tech stack** — language, framework, test runner (if any)
2. **Module list** — all services, pages, utilities, API routes
3. **Existing tests** — what's already covered, what framework is used
4. **Project structure** — entry points, config files, dependency management

Store results for injection into the Q&A page.

---

## Step 1: Pre-research Q&A Page

Generate an interactive HTML page so users can visually select options instead of answering questions one by one in the terminal.

### What the page collects

**1. Test types (multi-select):**

| Type | Description |
|------|-------------|
| API Testing | Full API layer coverage — CRUD, auth, error handling |
| Page E2E Testing | Browser-based user flow verification |
| Unit Testing | Function/module-level logic verification |
| Integration Testing | Cross-module collaboration verification |

**2. Modules to cover:**

- Module list is auto-generated from Step 0 analysis
- User selects which modules to cover and which test types apply to each

**3. Test environment:**

| Option | Use case |
|--------|----------|
| Dev environment | Quick iteration, early validation |
| Dedicated test/staging | Near-production verification |
| Production (read-only) | Smoke tests, monitoring |
| Temporary environment | Created per-run, destroyed after |
| Transaction rollback | DB tests without side effects |

User fills in: environment URL, auth method, credentials (if any). URL supports **"Agent自行获取"** — agent auto-detects from project config.

**4. Database configuration (supports Test Point 4: Data Validation):**

| Option | Description |
|--------|-------------|
| Agent自行获取 | Agent reads DB connection from project config (default) |
| User provides | User supplies connection string and DB type manually |
| No database | In-memory store, skip DB-related tests |

**5. Log configuration (supports Test Point 5: Log Validation):**

| Option | Description |
|--------|-------------|
| Agent自行获取 | Agent reads log config from project (default) |
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
Agent scans project
  → Generates HTML page with injected project data (modules, stack, etc.)
  → User opens page in browser, fills in selections
  → Page returns structured JSON to agent
  → Agent uses JSON to drive the entire testing workflow
```

Key: The page is **dynamically generated per project**, not a static template. See `references/qa-page-spec.md` for HTML structure details.

---

## Step 2: Test System Design

Using the Q&A JSON output + the test matrix below, generate a test plan and confirm with the user.

### 4 Test Categories

| # | Type | Scope |
|---|------|-------|
| 1 | API Testing | CRUD, auth, pagination, concurrency, idempotency |
| 2 | Page E2E Testing | Core flows, forms, routing, async interactions, responsive |
| 3 | Unit Testing | Pure functions, data transforms, business rules, state machines |
| 4 | Integration Testing | DB consistency, 3rd-party services, message queues, caching |

### 6 Mandatory Test Points (per selected type)

Once a test type is selected, ALL 6 points must be covered. No cherry-picking.

| # | Test Point | What it checks |
|---|-----------|----------------|
| 1 | **Basic Effect** | Happy path: normal input → expected output |
| 2 | **Boundary Cases** | Empty values, max-length strings, extreme numbers, special chars, duplicate concurrent submissions |
| 3 | **Status Code Validation** | HTTP status + business status code dual verification — never just check 200 |
| 4 | **Data Validation** | Response field completeness, type correctness, DB-vs-response consistency |
| 5 | **Log Validation** | Key operations produce logs, correct log level, no sensitive data leakage |
| 6 | **Exception/Error Handling** | Graceful degradation on bad input, timeouts, service unavailability — no crashes, no silence |

See `references/test-coverage-details.md` for per-type coverage specifics.

---

## Step 3: Implementation

Generate the following based on the approved test plan:

1. **Test files** — organized by type in separate directories
2. **Mock data / Fixtures** — data factories and static fixtures
3. **Test runner config** — framework configuration
4. **CI integration** — pipeline config if user requested it

---

## Step 4: Verification

This step uses `run-all-checks.sh` to run all tests and produce standardized reports.

### How to invoke

```bash
<skill-root>/scripts/run-all-checks.sh --project-path <path> --test-cmd <command> [--config <path>] [--output <path>]
```

For example, if your skill root is at `/home/user/.claude/skills/test-creator`:

```bash
/home/user/.claude/skills/test-creator/scripts/run-all-checks.sh --project-path ./my-project --test-cmd "npm test"
```

**This script auto-detects your project's test framework** via adapters (see below). You do NOT need to configure adapters manually.

### What it does

1. Detects your test framework (Jest, pytest, Go test, etc.) via adapter
2. Runs tests with coverage and parses the results
3. Re-runs tests N times to detect flaky tests
4. Records per-case timing to flag slow tests
5. Generates `quality-report.json` and `quality-report.md`

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

The script provides standardized reporting, adapter auto-detection, and multi-dimensional analysis (coverage + stability + performance) that raw test commands do not give you.

---

## Step 5: Quality Evaluation

Testing the tests. Two layers: **automated scripts** for mechanical checks, **sub-agent review** for semantic checks.

### Layer 1: Automated Quality Scripts (already done in Step 4)

The `run-all-checks.sh` output from Step 4 IS the Layer 1 result. Review the generated `quality-report.json` and `quality-report.md`.

**Config file** (`.test-creator-quality.json`):

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

1. Pass the sub-agent: `quality-report.json`, test file paths, source file paths, and original Q&A config JSON
2. Use the prompt template in `references/sub-agent-review-prompt.md`
3. Sub-agent returns a prioritized issue list
4. Author agent fixes issues, re-runs `run-all-checks.sh` + sub-agent review
5. Loop until all dimensions pass

### Complete Quality Flow

```
Step 4: run-all-checks.sh produces quality-report.json
  → Step 5 Layer 1: Review quality-report for mechanical issues
  → Step 5 Layer 2: Invoke sub-agent with report + test code + requirements
  → Merge results: scripts = quantitative, sub-agent = qualitative
  → Fix by severity → re-run run-all-checks.sh → re-invoke sub-agent → loop until clean
```

---

## Delivery Checklist

| Deliverable | Description |
|-------------|-------------|
| Q&A Page | Interactive HTML for requirement collection |
| Test Plan | Confirmed test design document |
| Test Files | Organized by type |
| Test Config | Framework + CI configuration |
| Mock/Fixtures | Test data factories and static fixtures |
| Coverage Report | Generated by run-all-checks.sh |
| Quality Report | Multi-dimensional evaluation (scripts + sub-agent) |
