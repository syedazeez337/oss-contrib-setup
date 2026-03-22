---
name: pr-preflight
description: Pre-submission quality gate for pull requests. Run before opening any PR to catch scope creep, lint failures, missing tests, oversized diffs, and description gaps. All gates must pass — this is not optional.
version: 1.0.0
author: oss-contrib-setup
license: MIT
metadata:
  tags: [pr, quality, lint, cncf, go, gate]
  related_skills: [cncf-issue-scout, systematic-debugging, tdd-go]
---

# PR Preflight

Quality gate. Run before every PR. All 6 gates must pass or the PR does not open.

## Trigger
Invoked via `/pre-pr` command or when the user says "check before PR", "run preflight",
"is this ready to submit", or similar.

## ACE Integration
If ACE MCP is connected, fetch the `cncf-pr-quality` playbook first:
the playbook may contain evolved insights from recent PR outcomes that override defaults here.

---

## Gate 1 — Scope Check

```bash
git diff main...HEAD --name-only
git diff main...HEAD --stat
```

Check every changed file against the issue being fixed:
- [ ] Every changed file is directly required to fix the reported issue
- [ ] No unrelated refactors, formatting fixes, or style cleanups in the diff
- [ ] No commented-out code added
- [ ] No TODO comments added (create a follow-up issue instead)

**FAIL action:** Stash unrelated changes (`git stash`), create a follow-up issue for them.

---

## Gate 2 — Build & Lint

Detect the project and run the appropriate command:

```bash
# Auto-detect and run:
# Cilium
[ -f "Makefile" ] && grep -q "golangci" Makefile && make lint

# CoreDNS / default Go
go vet ./... && golangci-lint run --timeout 5m

# Strimzi (Java)
./mvnw checkstyle:check

# Fallback
go build ./... && go vet ./...
```

- [ ] Build exits with code 0
- [ ] Zero new lint warnings introduced by this branch's changes
  - Pre-existing warnings in other files are acceptable; new ones in touched files are not

**FAIL action:** Fix all lint issues before proceeding. Do not use `//nolint` without a comment.

---

## Gate 3 — Tests

```bash
go test ./... -count=1
# Or targeted:
go test ./path/to/changed/pkg/... -count=1 -v
```

- [ ] All existing tests pass (zero failures, zero panics)
- [ ] If new logic was added: at least one test case covers the new behaviour
- [ ] If a bug was fixed: a regression test exists that would have caught the bug

**FAIL action:** Fix failing tests or write the missing regression test. See tdd-go skill.

---

## Gate 4 — Diff Size

```bash
git diff main...HEAD --stat
```

| Lines changed | Action |
|---|---|
| < 100 | Proceed |
| 100–300 | Add "Scope justification" section to PR body |
| > 300 | **STOP** — identify what can be split into a follow-up PR/issue |

**FAIL action for > 300:** Split the diff. Create a smaller focused PR + a follow-up issue for the rest.

---

## Gate 5 — PR Description Quality

Draft a PR description and validate it against @references/description-template.md:

- [ ] **Problem:** present in one sentence — describes the observable issue
- [ ] **Root cause:** present in 1–2 sentences — explains *why* the issue exists
- [ ] **Fix:** present in one sentence — describes *what* the change does
- [ ] **Verification:** exact command to reproduce the problem and confirm the fix
- [ ] **Issue link:** `Fixes #<n>` or `Closes #<n>` on its own line
- [ ] **No vague language:** "various improvements", "misc fixes", "cleanup", "refactor" are not acceptable alone

**FAIL action:** Revise the description until all five elements are present.

---

## Gate 6 — Competing PRs

```bash
gh pr list --repo <org>/<repo> \
  --state open \
  --search "<2–3 keywords from issue title>"
```

- [ ] No open PR exists targeting the same issue
- [ ] No open PR exists that modifies the same files with the same intent

**FAIL action:** If a competing PR exists → close your branch. If the competing PR is stale (no activity > 30 days), you may comment on it asking if the author needs help or has abandoned it before proceeding.

---

## Preflight Output

**All gates pass:**
```
✓ PR Preflight PASSED

  Gate 1 Scope:       3 files, all related to gosec G115 fix
  Gate 2 Lint:        clean (go vet + golangci-lint)
  Gate 3 Tests:       47 passed, 0 failed — regression test added
  Gate 4 Diff size:   68 lines (+41 / -27) — fast review track
  Gate 5 Description: complete — all 5 elements present
  Gate 6 Competing:   none found

Suggested PR title:
  fix(forward): prevent G115 integer overflow in port conversion

Draft PR body: [generated from description-template.md]
```

**Any gate fails:**
```
✗ PR Preflight FAILED — do not open PR yet

  Gate 1 Scope:       FAIL — pkg/util/strings.go unrelated to issue
  Gate 5 Description: FAIL — missing root cause, missing verification command

Action required:
  1. Stash pkg/util/strings.go changes
  2. Add root cause and verification to PR description
  Then re-run /pre-pr
```

## References
@references/description-template.md — PR description format with repo-specific examples
@references/repo-specific.md — Per-repo lint commands, CI requirements, sign-off rules
