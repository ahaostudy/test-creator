# Q&A Page Specification

## Purpose

The Q&A page is a dynamically generated HTML file that allows users to visually configure their testing requirements. The agent generates it after project analysis, injects project-specific data, and the user fills it in via browser.

## Generation Flow

```
1. Agent scans project → extracts modules, tech stack, existing tests
2. Agent generates HTML page via scripts/generate-qa-page.sh (or agent inline)
3. User opens page in browser
4. User makes selections and fills in details
5. Page outputs structured JSON
6. Agent consumes JSON for test planning
```

## HTML Page Structure

### Section 1: Test Type Selection

Multi-select checkboxes for test types (all checked by default):
- API Testing
- Page E2E Testing
- Unit Testing
- Integration Testing

All selected types apply to **every module**. Unsupported types are skipped per module.

### Section 2: Modules

Simple checklist of detected modules (all checked by default). No per-module test-type matrix — the same test types from Section 1 apply uniformly.

### Section 3: Test Environment

Radio select for environment type:
- Dev environment (default)
- Dedicated test/staging
- Production (read-only)
- Temporary environment
- Transaction rollback

Text inputs for: Environment URL, Auth method.
URL input includes **"Auto-detect"** button — agent auto-detects from project config.

### Section 4: Database Configuration

Radio select (default: Auto-detect):
- **Auto-detect** — agent reads DB connection string and type from project config
- **User provides** — user manually enters connection string and DB type
- **No database / In-memory** — skip DB-related validation tests

This section supports **Test Point 4: Data Validation** — ensuring tests verify response-vs-DB consistency.

### Section 5: Log Configuration

Radio select (default: Auto-detect):
- **Auto-detect** — agent reads log config (location, format) from project
- **User provides** — user manually enters log query method and format
- **No logging** — skip log validation tests

This section supports **Test Point 5: Log Validation** — ensuring tests verify key operations produce correct logs.

### Section 6: Test Data Strategy

Radio select:
- User provides test accounts/data
- Agent creates mock data (default)
- Fixed fixtures
- Dynamic generation

### Section 7: Additional Context

Text inputs for:
- Existing test coverage estimate
- Known bugs or weak areas
- CI/CD pipeline details

## Output JSON Format

```json
{
  "test_types": ["api", "e2e", "unit", "integration"],
  "modules": ["user-model", "order-model", "user-routes", "order-routes"],
  "environment": {
    "type": "dev",
    "url": "http://localhost:3000",
    "auth_method": "bearer_token"
  },
  "database": {
    "mode": "agent_auto",
    "connection": null,
    "type": null
  },
  "logging": {
    "mode": "agent_auto",
    "query": null,
    "format": null
  },
  "test_data": {
    "strategy": "agent_creates"
  },
  "additional_context": {
    "existing_coverage": "No existing tests",
    "known_issues": "Payment timeout on slow networks",
    "ci_cd": "GitHub Actions, run on PR"
  }
}
```

## Implementation Notes

- The page is **not a static template** — it is generated per project based on analysis results
- Use `scripts/generate-qa-page.sh` to generate the page with dynamic parameters
- Module list must come from actual project scanning, not hardcoded
- The page should be self-contained (inline CSS/JS), no external dependencies
- Output JSON should be copyable and also downloadable as a file
- The page should validate that at least one test type is selected before submission
