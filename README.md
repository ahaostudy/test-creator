# test-creator

> Stop guessing what to test. Give your project a professional, production-grade test suite — with one sentence.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Language Agnostic](https://img.shields.io/badge/Language-Any-green.svg)]()
[![Framework Agnostic](https://img.shields.io/badge/Framework-Any-green.svg)]()

**English** | [中文](README_CN.md)

---

test-creator is a **skill** that transforms any project into a well-tested codebase. No configuration files to write. No test templates to paste. Just describe your project, and test-creator handles the rest.

It works with **any language, any framework** — Go, Python, Node.js, Java, Rust, you name it.

---

## What It Does

test-creator gives your AI coding agent a structured, battle-tested methodology for building test suites. It's not a code generator — it's a **thinking framework** with automated quality tooling that ensures nothing falls through the cracks.

### The 6-Point Coverage Guarantee

Every test type must pass all 6 mandatory checkpoints. No shortcuts.

| | Checkpoint | Why It Matters |
|---|-----------|----------------|
| 1 | **Happy Path** | Does it actually work? |
| 2 | **Boundaries** | What happens with empty inputs, max values, special characters? |
| 3 | **Status Codes** | Are you getting the right HTTP/business codes — not just 200? |
| 4 | **Data Integrity** | Are responses complete? Types correct? Matches the database? |
| 5 | **Logging** | Do critical operations log properly? Is sensitive data staying out of logs? |
| 6 | **Error Handling** | What happens when things go wrong? Graceful degradation or crash? |

### 4 Test Types

Pick what your project needs — or use all four:

- **API Testing** — CRUD, auth, pagination, concurrency, idempotency
- **E2E Testing** — User flows, forms, routing, async state
- **Unit Testing** — Pure functions, transforms, business rules, state machines
- **Integration Testing** — Database consistency, 3rd-party services, message queues

### Dual-Layer Quality Assurance

**Layer 1: Automated Scripts** — Coverage, stability (flaky test detection), and performance are measured mechanically. Three dimensions, one report.

**Layer 2: Adversarial Sub-Agent Review** — A separate AI agent reviews the test code from 6 dimensions, finding issues scripts can't: incorrect assertions, missing scenarios, unreasonable mocks, poor test data. The reviewer's job is to **find problems, not validate good work**.

---

## Why test-creator?

| The old way | With test-creator |
|-------------|-------------------|
| Ask the agent "write tests" and hope for the best | Structured 6-step workflow: analyze → plan → implement → verify → review |
| Tests pass but miss real bugs | 6 mandatory test points per type — no cherry-picking |
| No idea if the suite is actually good | Multi-dimensional quality report (coverage + stability + performance) |
| Self-review (agent checking its own work) | Adversarial sub-agent review with 6 dimensions |
| Works with one framework | Works with any language/framework via adapter system |

---

## Supported Frameworks

Auto-detected — zero configuration needed:

- **JavaScript/TypeScript** — Jest, Vitest
- **Python** — pytest
- **Go** — go test
- **Java** — JUnit

Don't see your framework? The adapter system is extensible — add your own in under 50 lines of shell script.

---

## Installation

### Claude Code

Global:

```bash
curl -sSL https://raw.githubusercontent.com/ahaostudy/test-creator/main/scripts/install.sh | bash -s -- --tool claude-code
```

Project-local:

```bash
curl -sSL https://raw.githubusercontent.com/ahaostudy/test-creator/main/scripts/install.sh | bash -s -- --tool claude-code --project
```

### Codex

```bash
curl -sSL https://raw.githubusercontent.com/ahaostudy/test-creator/main/scripts/install.sh | bash -s -- --tool codex
```

Installs to `~/.agents/skills/test-creator/`. Use `/skills` or `$` to invoke.

### OpenClaw

```bash
curl -sSL https://raw.githubusercontent.com/ahaostudy/test-creator/main/scripts/install.sh | bash -s -- --tool openclaw
```

Installs to `~/.agents/skills/test-creator/`.

### Manual / Any Tool

```bash
curl -sSL https://raw.githubusercontent.com/ahaostudy/test-creator/main/scripts/install.sh | bash -s -- --tool generic --dir /your/target/dir
```

Or just copy the directory yourself — the skill needs `SKILL.md` plus the `adapters/`, `scripts/`, and `references/` folders alongside it.

## Quick Start

### 1. Install

Pick your tool above and run the install command.

### 2. Use it

Ask your AI agent to build tests for any project:

> *"Help me create a test suite for my Flask API"*
>
> *"I want to add integration tests to this Go project"*
>
> *"Build E2E tests for this React app"*

test-creator activates automatically.

### 3. Let it work

Your agent will:

1. Scan your project — tech stack, modules, existing tests
2. Generate an interactive Q&A page for you to pick what to cover
3. Design and implement the test suite
4. Run automated quality checks across 3 dimensions
5. Have a sub-agent review the tests from 6 angles
6. Fix issues until everything passes

---

## Benchmark

We tested test-creator against baseline (same agents, no skill):

| | With Skill | Without Skill |
|--|-----------|---------------|
| **Pass Rate** | 90.3% | 36.1% |
| **Consistency** | ±8.7% std dev | ±12.7% std dev |

**+54 percentage points** improvement in test quality. The skill turns "vibes-based testing" into systematic, measurable quality.

---

## License

[MIT](LICENSE)
