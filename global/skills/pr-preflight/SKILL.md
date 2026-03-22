---
name: pr-preflight
description: Pre-submission quality gate for pull requests. Run before opening any PR to catch scope creep, lint failures, missing tests, oversized diffs, and description gaps. Works across any language or repo. Reads repo profile from repo-ingest if available — falls back to auto-detection. Gates 2 and 3 use fix-loop to iterate until clean before reporting failure. All gates must pass — this is not optional.
version: 2.0.0
author: oss-contrib-setup
license: MIT
metadata:
  tags: [pr, quality, lint, cncf, go, gate]
  related_skills: [repo-ingest, fix-loop, systematic-debugging, tdd-go]
---

# PR Preflight

Quality gate. Run before every PR. All 6 gates must pass or the PR does not open.
Gates 2 and 3 run fix-loop automatically — they iterate to clean, not just report failure.

---

## Step 0 — Resolve context

### Load repo profile
```bash
ls .claude/plans/repo-*.md 2>/dev/null | head -1
```

If a profile exists: read it and extract:
- `BASE` — default branch (main / master / trunk / develop)
- `BUILD_CMD`, `LINT_CMD`, `TEST_CMD` — exact commands
- `SIGN_OFF` — DCO | CLA | none
- `COMMIT_FORMAT` — exact format with example from git log
- `PR_SECTIONS` — required PR body sections for this repo

If no profile: note "no repo profile found — run `repo-ingest` first for best results" and auto-detect:

```bash
# Detect base branch
BASE=$(git remote show origin 2>/dev/null | grep 'HEAD branch' | awk '{print $NF}')
[ -z "$BASE" ] && BASE=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||')
[ -z "$BASE" ] && BASE=$(git branch -r | grep -E 'origin/(main|master|trunk|develop)' | head -1 | sed 's|.*origin/||' | tr -d ' ')
[ -z "$BASE" ] && BASE="main"

# Detect language
[ -f go.mod ]      && LANG=go
[ -f pom.xml ]     && LANG=java-maven
[ -f Cargo.toml ]  && LANG=rust
[ -f package.json ] && LANG=node
```

**Playbook:**
Read `cncf-pr-quality` playbook: via ACE MCP if connected, otherwise `~/.claude/playbooks/cncf-pr-quality.md`.

Print resolved context before running gates:
```
Context:
  Profile:     <path | not found>
  Base branch: <BASE>
  Language:    <lang>
  Lint:        <LINT_CMD>
  Test:        <TEST_CMD>
  Sign-off:    <SIGN_OFF>
```

---

## Gate 1 — Scope Check

```bash
git diff ${BASE}...HEAD --name-only
git diff ${BASE}...HEAD --stat
```

Check every changed file against the issue being fixed:
- [ ] Every changed file is directly required to fix the reported issue
- [ ] No unrelated refactors, formatting fixes, or style cleanups in the diff
- [ ] No commented-out code added
- [ ] No TODO comments added (create a follow-up issue instead)

**FAIL action:** Stash unrelated changes (`git stash`), create a follow-up issue for them.
Scope failures are never auto-fixed — they require a judgement call.

---

## Gate 2 — Build & Lint (with fix-loop)

**Phase 1 — Initial run:**
```bash
<LINT_CMD>   # from profile or auto-detected
```

If exit code 0: gate passes immediately — no loop needed.

**Phase 2 — If failures exist, run fix-loop (lint only, max 3 iterations):**
- Auto-fix what the tool can handle automatically (if LINT_FIX_CMD is supported)
- Apply pattern fixes from fix-loop references/fix-patterns.md
- Re-run lint after each fix
- Never use `//nolint`, `@SuppressWarnings`, `#noqa`, or similar silencing without a comment explaining why

After fix-loop:
- Clean → note what was fixed, mark gate PASS
- Still failing → mark gate FAIL, list remaining issues with exact file:line:rule

**Checklist:**
- [ ] Build exits with code 0
- [ ] Zero new warnings in files touched by this branch (pre-existing in untouched files are acceptable)

---

## Gate 3 — Tests (with fix-loop)

**Phase 1 — Run tests:**
```bash
<TEST_CMD>   # from profile or auto-detected
# If profile specifies additional flags (e.g. race detector, coverage): use them
```

If exit code 0: gate passes.

**Phase 2 — If test failures, run fix-loop (test phase only, max 3 iterations):**
For each failing test:
1. Read the exact failure: test name, assertion, got vs want
2. Determine: production code wrong or test expectation wrong?
3. Fix the code — never silence with skip/xfail to make the loop pass
4. Re-run the specific failing test, then the full suite

**Checklist:**
- [ ] All existing tests pass (zero failures, zero panics)
- [ ] If new logic added: at least one test case covers it
- [ ] If a bug fixed: regression test exists that would have caught it
- [ ] Any extra flags required by the repo profile pass (e.g. `-race`, `--strict`)

---

## Gate 4 — Diff Size

```bash
git diff ${BASE}...HEAD --stat
```

| Lines changed | Action |
|---|---|
| < 100 | Proceed |
| 100–300 | Add "Scope justification" section to PR body |
| > 300 | **STOP** — split into a smaller PR + follow-up issue |

---

## Gate 5 — PR Description Quality

Use sections from the repo profile if available — repo-specific sections override the defaults.

**Default required sections:**
- [ ] **Problem:** one sentence — what is observably wrong
- [ ] **Root cause:** 1–2 sentences — why it exists
- [ ] **Fix:** one sentence — what the change does
- [ ] **Verification:** exact command to reproduce and confirm the fix
- [ ] **Issue link:** `Fixes #<n>` or `Closes #<n>` on its own line
- [ ] No vague language ("various", "misc", "cleanup" alone are not acceptable)

**Repo-specific sections (from profile — override defaults when present):**
Read the `PR_SECTIONS` field from the profile and validate those instead.
Examples: CoreDNS uses `Why / Issues / Docs / Breaking changes`;
Cilium uses `Problem / Solution / Related issues`.

**FAIL action:** Draft the missing sections and present for approval. Never leave placeholder text.

---

## Gate 6 — Competing PRs

```bash
gh pr list --repo <org>/<repo> \
  --state open \
  --search "<2–3 keywords from issue title>"
```

- [ ] No open PR exists targeting the same issue
- [ ] No open PR exists modifying the same files with the same intent

**FAIL action:** Competing PR exists → close your branch. Stale (> 30 days no activity) → comment asking if abandoned before proceeding.

---

## Final Output

**All gates pass:**
```
✓ PR Preflight PASSED

  Profile:        <path | not found>
  Base branch:    <BASE>
  Gate 1 Scope:   <N> files, all related to <issue>
  Gate 2 Lint:    PASS (<N> warnings fixed in <N> iterations | clean on first run)
  Gate 3 Tests:   PASS (<N> passed, 0 failed)
  Gate 4 Diff:    <N> lines — <fast track | needs justification>
  Gate 5 Desc:    complete — all sections present
  Gate 6 Compete: none found

Sign-off:  <DCO: add -s flag | CLA: already signed | none required>

Suggested PR title:
  <format from repo profile — uses repo's actual commit convention>

Draft PR body:
  [generated from description-template.md and repo-specific sections]
```

**Any gate fails:**
```
✗ PR Preflight FAILED — do not open PR yet

  Gate 2 Lint:   FAIL — 1 warning remains after fix-loop (3 iterations)
    <file>:<line> <rule> — <description>
    Fix: see fix-loop/references/fix-patterns.md

  Gate 5 Desc:   FAIL — missing root cause section

Action required:
  1. <exact fix for each failing gate>
  Then re-run /pre-pr
```

## References
@references/description-template.md — PR description format with repo-specific examples
@references/repo-specific.md — Per-repo lint commands, CI requirements, sign-off rules
