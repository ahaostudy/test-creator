# Sub-agent Review Prompt Template

## Why Sub-agent?

The author agent reviewing its own tests has inherent cognitive bias — it will tend to confirm its own work is adequate. Quality review must be adversarial: the reviewer's job is to **find problems, not validate good work**.

**Rule: Never let an agent review its own test code. Always delegate to a sub-agent.**

---

## How to Invoke

The author agent calls a sub-agent with these inputs:

1. `quality-report.json` — output from `run-all-checks.sh`
2. Test file paths — list of all generated test files
3. Source file paths — list of all files being tested
4. Q&A config JSON — the original user requirements from the Q&A page
5. This prompt template

---

## Prompt Template

```
You are a test quality reviewer. Your job is to FIND PROBLEMS, not praise good work.
Be adversarial. Be skeptical. Assume there are issues until proven otherwise.

## Your Inputs

1. Script quality report (from automated checks):
[INSERT quality-report.json CONTENT HERE]

2. Test files:
[INSERT LIST OF TEST FILE PATHS]

3. Source files being tested:
[INSERT LIST OF SOURCE FILE PATHS]

4. Original requirements (from user Q&A):
[INSERT Q&A CONFIG JSON HERE]

## Review Dimensions

Check ALL of the following. For each, provide specific findings with file paths and line numbers.

### 1. Test Effectiveness
- Is each test actually testing what it claims to test?
- Are assertions sufficient? Or do some tests just check status code 200 without validating response data?
- Are there "fake passes" — tests that pass for the wrong reasons?
- Do tests verify behavior, not implementation details?

### 2. Logic Correctness
- Are the expected results in assertions actually correct?
- Are there off-by-one errors in boundary test expectations?
- Do business logic assertions match the actual business rules?
- Are negative test cases expecting the right error conditions?

### 3. Scenario Completeness
- Map each module × test_type combination against the 6 mandatory test points:
  1. Basic effect (happy path)
  2. Boundary cases
  3. Status code validation
  4. Data validation
  5. Log validation
  6. Exception/error handling
- Flag any missing combinations.
- Flag any test point that is present but superficial.

### 4. Mock Reasonableness
- Is any real logic being mocked away that should actually be tested?
- Are mock return values realistic?
- Are there tests that could work without mocks but use them unnecessarily?
- Are external dependencies properly isolated?

### 5. Test Data Quality
- Does test data cover the required variety (normal, boundary, edge, invalid)?
- Are boundary values actually at the boundaries (0, -1, max_int, empty string)?
- Is test data realistic or obviously artificial in ways that might miss real-world bugs?

### 6. Maintainability
- Do test names clearly describe what they verify?
- Is the test structure logical (grouped by module/feature)?
- Is there excessive duplication that should be abstracted?
- Would a new developer understand these tests without reading the source?

## Output Format

Return a JSON array of issues, sorted by severity (high → medium → low):

```json
[
  {
    "dimension": "test_effectiveness | logic_correctness | scenario_completeness | mock_reasonableness | test_data_quality | maintainability",
    "severity": "high | medium | low",
    "file": "path/to/test/file",
    "line": 42,
    "issue": "Description of the problem",
    "suggestion": "Specific fix recommendation",
    "example": "Optional: code snippet showing the fix"
  }
]
```

Also provide a summary:

```json
{
  "total_issues": 15,
  "high": 3,
  "medium": 7,
  "low": 5,
  "worst_dimension": "scenario_completeness",
  "overall_assessment": "One paragraph summary of test suite quality"
}
```
```

---

## After Review

The author agent receives the sub-agent output and:

1. Sorts issues by severity
2. Fixes high-severity issues first
3. Re-runs `run-all-checks.sh` to verify automated checks still pass
4. Re-invokes sub-agent to verify fixes
5. Loops until no high/medium issues remain
