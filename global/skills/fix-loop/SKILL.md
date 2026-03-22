---
name: fix-loop
description: Iterative fix loop — runs build, lint, and tests; reads every failure; applies targeted fixes; re-runs until all checks are clean or max iterations reached. Works across any language or build system. Reads commands from repo-ingest profile if available. Invoke when lint or tests are failing and you need to iterate to green. Trigger phrases: "fix lint", "make tests pass", "iterate until clean", "fix all issues", "get this to pass CI".
version: 1.0.0
author: oss-contrib-setup
license: MIT
metadata:
  tags: [lint, fix, loop, iterate, build, test, ci]
  related_skills: [repo-ingest, pr-preflight, systematic-debugging, tdd-go]
---

# Fix Loop

Run checks → read failures → apply targeted fixes → re-run → repeat until clean.

**Iron law:** Never mark a check as passing without running it and seeing exit code 0.
**Max iterations:** 5 per phase. If still failing after 5 rounds, stop and report — the approach is wrong.

---

## Step 0 — Resolve commands

### 0a — Load repo profile
```bash
ls .claude/plans/repo-*.md 2>/dev/null | head -1
```

If a profile exists: **read it** and extract the exact values for:
- `BUILD_CMD` — the build command
- `LINT_CMD` — the lint command
- `LINT_FIX_CMD` — auto-fix command (may be "NOT SUPPORTED")
- `TEST_CMD` — the test command
- `SRC_EXT` — source file extension(s) (e.g. `*.go`, `*.java`, `*.rs`)

If a profile exists, skip Step 0b entirely and go to Step 0c.

### 0b — Auto-detect (only if no profile)

Detect language and build system:
```bash
[ -f go.mod ]                                     && echo "LANG=go"
[ -f pom.xml ]                                    && echo "LANG=java-maven"
[ -f build.gradle ] || [ -f build.gradle.kts ]    && echo "LANG=java-gradle"
[ -f Cargo.toml ]                                 && echo "LANG=rust"
[ -f package.json ]                               && echo "LANG=node"
[ -f pyproject.toml ] || [ -f setup.py ]          && echo "LANG=python"
[ -f Makefile ] && grep -q "^lint:" Makefile      && echo "HAS_MAKE_LINT=true"
[ -f Makefile ] && grep -q "^test:" Makefile      && echo "HAS_MAKE_TEST=true"
```

Assign commands from this table — **prefer Makefile targets when they exist**:

| Language | BUILD_CMD | LINT_CMD | LINT_FIX_CMD | TEST_CMD | SRC_EXT |
|---|---|---|---|---|---|
| go | `go build ./...` | `golangci-lint run --timeout 5m` | `golangci-lint run --fix` | `go test ./... -count=1` | `*.go` |
| java-maven | `./mvnw package -DskipTests` | `./mvnw checkstyle:check` | NOT SUPPORTED | `./mvnw test` | `*.java` |
| java-gradle | `./gradlew build -x test` | `./gradlew checkstyle` | NOT SUPPORTED | `./gradlew test` | `*.java` |
| rust | `cargo build` | `cargo clippy -- -D warnings` | `cargo clippy --fix` | `cargo test` | `*.rs` |
| node | `npm run build` | `npm run lint` | `npm run lint -- --fix` | `npm test` | `*.ts,*.js` |
| python | _(none)_ | `ruff check .` | `ruff check . --fix` | `pytest` | `*.py` |

If Makefile has `lint:` target → use `make lint` as LINT_CMD.
If Makefile has `test:` target → use `make test` as TEST_CMD.
If Makefile has `build:` or default target builds the project → use `make` as BUILD_CMD.

### 0c — Detect base branch

```bash
BASE=$(git remote show origin 2>/dev/null | grep 'HEAD branch' | awk '{print $NF}')
[ -z "$BASE" ] && BASE=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||')
[ -z "$BASE" ] && BASE=$(git branch -r | grep -E 'origin/(main|master|trunk|develop)' | head -1 | sed 's|.*origin/||' | tr -d ' ')
[ -z "$BASE" ] && BASE="main"
echo "Base branch: $BASE"
```

Use `$BASE` everywhere instead of hardcoded `main`.

Print the resolved commands before starting:
```
Resolved:
  Language:  <lang>
  Base:      <BASE>
  Build:     <BUILD_CMD>
  Lint:      <LINT_CMD>
  Lint fix:  <LINT_FIX_CMD | NOT SUPPORTED>
  Test:      <TEST_CMD>
  Source:    <SRC_EXT>
  Source:    from <profile | auto-detected>
```

---

## Step 1 — Initial run (all phases)

Run all three phases and capture full output. Do not stop on first failure.

```bash
# Build
<BUILD_CMD> 2>&1; echo "BUILD_EXIT:$?"

# Lint
<LINT_CMD> 2>&1; echo "LINT_EXIT:$?"

# Test — targeted changed packages first, then full suite
CHANGED_DIRS=$(git diff ${BASE}...HEAD --name-only | grep -E '\.(go|java|rs|ts|js|py)$' | xargs -I{} dirname {} | sort -u | tr '\n' ' ')
# Run targeted test if the test command supports path arguments (Go, Rust, Python):
# <TEST_CMD targeting CHANGED_DIRS>
# Then full suite:
<TEST_CMD> 2>&1; echo "TEST_EXIT:$?"
```

Record the full output of each. If all exit codes are 0: output PASS summary and stop — no loop needed.

---

## Step 2 — Classify failures

Group every failure into one of three buckets:

### Bucket A — Auto-fixable (tool handles it automatically)
LINT_FIX_CMD is supported for this language AND the specific warning is formatting/style.

Examples by language:
- Go: `gofmt`, `goimports`, `whitespace`, `unconvert`, `perfsprint`, `canonicalheader`, `intrange`, `modernize`
- Rust: `cargo clippy --fix` can fix most suggestions
- Node/Python: `eslint --fix`, `ruff --fix` handle formatting
- Java: NOT SUPPORTED (checkstyle is report-only)

### Bucket B — Pattern fix (known security/correctness patterns with standard fixes)
See @references/fix-patterns.md for language-specific before/after examples:
- Go gosec: G114, G115, G301, G304, G401/G501
- Any: duplicate metric registration, missing error check, unchecked type assertion
- Java: common checkstyle violations (line length, import order)

### Bucket C — Requires investigation (test failures, compile errors, logic bugs)
Everything else. Requires reading the code and understanding the failure.

---

## Step 3 — Fix loop (max 5 iterations)

Print at the start of each iteration:
```
── Fix Loop iteration <N>/5 ──────────────────────
Build:  <PASS | N errors>
Lint:   <PASS | N warnings>
Tests:  <PASS | N failures>
```

### 3a — Bucket A: auto-fix

If LINT_FIX_CMD is supported and Bucket A warnings exist:
```bash
<LINT_FIX_CMD> 2>&1
```

Re-run lint immediately:
```bash
<LINT_CMD> 2>&1; echo "LINT_EXIT:$?"
```

If lint exits 0 → Bucket A done.

### 3b — Bucket B: pattern fixes

For each remaining lint warning:
1. Read the file at the reported line
2. Look up the pattern in @references/fix-patterns.md
3. Apply the standard fix
4. Re-run lint for that specific file (if the tool supports it), otherwise full lint
5. Confirm warning is gone before moving to the next
6. Fix one at a time — never batch Bucket B fixes

### 3c — Bucket C: investigate and fix

**Build errors:**
1. Read the exact error (file, line, message)
2. Read that line plus surrounding context
3. Fix the error (import missing, type mismatch, undefined symbol, syntax error)
4. Re-run: `<BUILD_CMD> 2>&1; echo "EXIT:$?"`
5. Confirm exit 0

**Test failures:**
1. Read the full test output: exact test name, assertion, got vs want
2. Determine: is the fix in production code or in the test assertion?
   - Production code wrong → apply systematic-debugging: state root cause in ONE sentence first
   - Test expectation wrong (intentional behaviour change) → fix the test
3. Run only the failing test first (if tool supports it), then the full suite
4. Never silence a test with skip/xfail/`//nolint` to make the loop pass

### 3d — End of iteration: re-run all

```bash
<BUILD_CMD> 2>&1; echo "BUILD_EXIT:$?"
<LINT_CMD>  2>&1; echo "LINT_EXIT:$?"
<TEST_CMD>  2>&1; echo "TEST_EXIT:$?"
```

All exit 0 → CLEAN → go to Step 4.
Still failing → next iteration (back to 3a).
Iteration 5 reached and still failing → go to Step 4 with PARTIAL status.

---

## Step 4 — Output report

### All clean:
```
✓ Fix Loop PASSED — all checks clean

  Language:   <lang>
  Iterations: <N>
  Build:      PASS
  Lint:       PASS (<N> warnings fixed)
  Tests:      PASS

  Fixes applied:
  - [auto]    <linter>: <N> files reformatted
  - [pattern] <rule>: <file>:<line> — <description of fix>
  - [manual]  <test name>: <description of fix>

  Ready for /pre-pr
```

### Partial (max iterations reached):
```
✗ Fix Loop PARTIAL — <N> issues remain after 5 iterations

  Build:  PASS | FAIL
  Lint:   FAIL — <N> remaining
  Tests:  FAIL — <N> failing

  Remaining issues:
  ─────────────────────────────────────────
  1. <file>:<line> — <rule>: <description>
     Requires: <what needs to happen>

  2. <TestName> FAILED
     Assertion: got=<X> want=<Y>
     Likely cause: <one sentence>

  Suggested next steps:
  - For lint: see fix-patterns.md for <rule>
  - For tests: run systematic-debugging on <TestName>

  Do NOT open PR until all checks pass.
```

## References
@references/fix-patterns.md — Standard before/after code for common lint and security patterns across Go, Java, Rust, and Node
