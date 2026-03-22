---
name: systematic-debugging
description: Systematic debugging methodology for Go and cloud-native code. Use when investigating a bug, unexpected test failure, build error, runtime panic, or flaky test. Iron law — no fix without a stated root cause.
version: 1.0.0
author: oss-contrib-setup (adapted from NousResearch/hermes-agent)
license: MIT
metadata:
  tags: [debugging, go, methodology, root-cause, panic, test-failure]
  related_skills: [tdd-go, writing-plans]
---

# Systematic Debugging

## Iron Law

**NO FIX MAY BE WRITTEN UNTIL THE ROOT CAUSE IS STATED IN ONE SENTENCE.**

"It panics" is not a root cause.
"The int64 value exceeds MaxInt32 before the unchecked cast on line 47" is a root cause.

---

## Phase 1 — Root Cause Investigation

### 1.1 Read the full error
- For Go panics: read the complete goroutine stack trace — the panic site AND all callers
- For build errors: the **first** compiler error is the real one; later errors are usually cascades
- For test failures: read the test name, the `FAIL` message, AND the diff between got/want
- For lint warnings: read the rule number (e.g., G115), not just "lint failed"

### 1.2 Reproduce it consistently

```bash
# Reproduce a test failure deterministically
go test -run TestExactName ./path/to/pkg -v -count=1

# Reproduce a data race
go test -race -run TestName ./pkg/... -v -count=1

# Reproduce a build error
go build ./... 2>&1 | head -20
```

If you cannot reproduce the failure consistently, you cannot verify the fix. Stop here and find the reproduction path first.

### 1.3 Check what changed recently

```bash
git log --oneline -20
git diff HEAD~1
git diff main...HEAD --name-only
```

Most bugs in open source PRs are introduced by the change being reviewed, not pre-existing.

### 1.4 Gather evidence — trace the data flow

For each relevant component, answer:
- What input enters this function?
- What output or side-effect is expected?
- At exactly which line does the actual behaviour diverge from expected?

```bash
# Add temporary stderr debug output (remove before committing)
fmt.Fprintf(os.Stderr, "DEBUG %s:%d: val=%v type=%T\n", "file.go", 47, val, val)

# Or use delve for interactive debugging
dlv test ./pkg/forward -- -test.run TestParsePort -test.v
```

### 1.5 For multi-component issues (controllers, gRPC, Kafka)

Trace the path: producer → broker → consumer → controller → reconciler.
Add structured log output at each boundary. Look for the first point where the data
diverges from invariant expectations.

---

## Phase 2 — Pattern Analysis

1. Find a working example in the codebase that performs the same operation successfully
2. `grep -rn "int32(" . --include="*.go"` — find all similar conversions
3. Compare the working path vs the broken path line by line
4. Identify the structural difference (missing bounds check, wrong channel direction, uninitialized field)
5. If the same broken pattern appears in 3+ places: fix all of them in the PR

---

## Phase 3 — Hypothesis and Testing

1. Form **one specific hypothesis**: "I believe the panic occurs because `port` is `int64` with value 70000, and `int32(port)` silently wraps to a negative value at line 47 in `pkg/forward/forward.go`."
2. Design the minimal test that proves or disproves this hypothesis (see tdd-go skill)
3. Verify the hypothesis explains ALL observed symptoms — not just the reported one
4. If the hypothesis explains only some symptoms: you have the wrong root cause

---

## Phase 4 — Implementation

Only after phases 1–3 are complete:

1. Write the failing test (RED) — see tdd-go skill
2. Write the minimal fix (GREEN) — the smallest change that makes the test pass
3. Run the full test suite: `go test ./... -count=1`
4. If the fix is more than 20 lines: step back — you likely misidentified the root cause

---

## The Rule of Three

If you have made **3 or more fix attempts** and the problem persists:
- You have the wrong root cause
- Stop. Do not try a fourth fix.
- Re-read the error message as if you are seeing it for the first time
- Ask: is this a design problem, not an implementation problem?
- Widen your search: `git log --all --oneline -- path/to/file.go`

---

## Go-Specific Quick Diagnostics

```bash
# Race conditions — always run on concurrent code
go test -race ./...

# Build constraints issue
go build -tags integration ./...

# Wrong Go version
go version
cat go.mod | grep "^go "

# Module cache corruption
go clean -modcache && go mod download

# Stale test cache
go clean -testcache && go test ./...

# Circular import
go build 2>&1 | grep "import cycle"

# Interface not satisfied
# The error "does not implement" always names the missing method — read it carefully
```

See @references/go-diagnostics.md for the full diagnostics reference including pprof,
delve, and common panic pattern catalogue.

---

## Red Flags — You Are Violating the Process

- Writing a fix before articulating the root cause in a sentence
- Running `go test` repeatedly hoping it passes
- Adding `time.Sleep` to "fix" a flaky test (the sleep masks a race — find the race)
- Using `recover()` to suppress panics without fixing the underlying nil dereference
- Describing symptoms as root cause: "it returns the wrong value" ≠ root cause
- Making a change, seeing it doesn't work, reverting it, trying something else — without understanding why the revert worked

---

## Output Format

When reporting a completed investigation:

```
Root cause: <one precise sentence>
Affected code: path/to/file.go:L42 — <why this line>
Hypothesis tested: <what you tried to prove/disprove>
Fix: <one sentence describing the minimal change>
Regression test: <test name and command>
```
