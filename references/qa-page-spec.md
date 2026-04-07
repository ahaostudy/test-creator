# Q&A Page Specification

## Purpose

The Q&A page is a dynamically generated HTML file that allows users to visually configure their testing requirements. The agent generates it after project analysis, injects project-specific data, and the user fills it in via browser.

## Generation Flow

```
1. Agent scans project → extracts modules, tech stack, existing tests
2. Agent generates HTML page with injected data
3. User opens page in browser
4. User makes selections and fills in details
5. Page outputs structured JSON
6. Agent consumes JSON for test planning
```

## HTML Page Structure

### Section 1: Test Type Selection

Multi-select checkboxes for test types:
- API Testing
- Page E2E Testing
- Unit Testing
- Integration Testing

### Section 2: Module Coverage Matrix

A table generated from the agent's project analysis. Each row is a discovered module/service/page. Columns are the selected test types from Section 1. User checks which test types apply to which modules.

Example:
```
Module              | API | E2E | Unit | Integration
--------------------|-----|-----|------|----------
user-service        |  ✓  |     |  ✓   |
order-service       |  ✓  |     |  ✓   |     ✓
checkout-page       |     |  ✓  |      |
payment-gateway     |  ✓  |     |      |     ✓
```

### Section 3: Test Environment

Radio select for environment type:
- Dev environment
- Dedicated test/staging
- Production (read-only)
- Temporary environment
- Transaction rollback

Text inputs for: Environment URL, Auth method, Credentials

### Section 4: Test Data Strategy

Radio select:
- User provides test accounts/data
- Agent creates mock data
- Fixed fixtures
- Dynamic generation

### Section 5: Additional Context

Textarea inputs for:
- Existing test coverage (freeform description)
- Known bugs or weak areas
- CI/CD pipeline details

## Output JSON Format

```json
{
  "test_types": ["api", "e2e", "unit"],
  "module_coverage": {
    "user-service": ["api", "unit"],
    "order-service": ["api", "unit", "integration"],
    "checkout-page": ["e2e"]
  },
  "environment": {
    "type": "dev",
    "url": "http://localhost:3000",
    "auth_method": "bearer_token",
    "credentials_ref": "provided_separately"
  },
  "test_data": {
    "strategy": "agent_creates",
    "user_provided_accounts": null,
    "fixture_sets": null
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
- Module list must come from actual project scanning, not hardcoded
- The page should be self-contained (inline CSS/JS), no external dependencies
- Output JSON should be copyable and also downloadable as a file
- The page should validate that at least one test type and one module are selected before submission
