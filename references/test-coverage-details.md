# Test Coverage Details per Type

Each selected test type must cover all 6 mandatory test points. This document details what each test type should specifically cover beyond the 6 points.

---

## 1. API Testing

- Full CRUD coverage (all HTTP methods)
- **Auth:** No token, expired token, insufficient permissions
- **Pagination:** First page, last page, out-of-range, negative values
- **Concurrency:** Duplicate creation, optimistic lock conflicts
- **Idempotency:** Repeated identical requests
- **Response time baseline:** Establish and verify performance thresholds

## 2. Page E2E Testing

- Core business flows end-to-end
- **Forms:** Normal submission, validation errors, post-submit state
- **Routing:** Direct URL access, forward/back navigation, page refresh
- **Async interactions:** Loading states, failure prompts, retry behavior
- **Responsive:** Usability across different viewport sizes

## 3. Unit Testing

- Pure function input/output combinations
- Data transformation and mapping logic
- Business rule conditional branches
- Utility functions
- State machine transitions

## 4. Integration Testing

- **Database:** Read/write consistency, transaction rollback, connection pool behavior
- **Third-party services:** Normal response, timeout, error scenarios
- **Message queues:** Send, consume, retry, dead letter handling
- **Caching:** Cache hit, cache miss, expiration behavior

---

## Critical Rule: Test Point 4 — Data Validation

**Data validation means querying the storage layer, not inspecting the response.**

Wrong approach (shallow, catches nothing real):
```python
assert isinstance(response.json()["email"], str)
assert "id" in response.json()
```

Correct approach (queries DB to verify actual stored state):
```python
response = client.post("/users", json=payload)
assert response.status_code == 201
user_id = response.json()["id"]

# Query DB directly
db_user = db.query("SELECT * FROM users WHERE id = ?", user_id)
assert db_user["email"] == payload["email"]
assert db_user["username"] == payload["username"]
assert db_user["password_hash"] != payload["password"]  # must be hashed
assert db_user["created_at"] is not None
assert db_user["deleted_at"] is None
```

The test must:
1. Perform the action (API call, UI interaction, function call)
2. Query the storage layer directly (DB, cache, file system)
3. Assert that stored values match what was sent — field by field
4. Assert that derived values are correct (hashed passwords, generated IDs, timestamps)
5. Assert that no extra/unexpected mutations occurred

---

## 6 Mandatory Test Points Applied

For every module × test_type combination, ensure these 6 points are covered:

| # | Test Point | API Example | E2E Example | Unit Example | Integration Example |
|---|-----------|-------------|-------------|--------------|---------------------|
| 1 | Basic Effect | POST returns 201 + created resource | User completes checkout flow | `add(2,3)` returns `5` | Write to DB, read back, verify match |
| 2 | Boundary Cases | Empty body, 10KB payload, special chars in fields | Form with max-length input, empty required fields | Null input, max int, empty array | Bulk insert 10K rows, connection pool exhaustion |
| 3 | Status Code | Verify HTTP 200/201/400/401/403/404/500 + business codes | Verify page shows correct error/success state | Verify thrown error type and message | Verify error propagation across service boundaries |
| 4 | Data Validation | Query DB directly after write — verify stored values match request; verify response fields match DB record | Query API after UI action — verify displayed values match DB record | Output structure and values match expected schema | Query DB after write — verify every field stored correctly, no truncation, no type coercion loss |
| 5 | Log Validation | Request/response logged, no PII in logs | User action triggers expected log entry | Function entry/exit logged at correct level | Cross-service call logged with correlation ID |
| 6 | Exception Handling | Malformed JSON, missing headers, service down | Network error shows user-friendly message | Invalid input throws, not crashes | Service timeout triggers retry, not silent failure |
