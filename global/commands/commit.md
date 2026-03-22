---
description: Generate a conventional commit message, stage specific files, commit, and optionally push the branch.
argument-hint: [push — add to also push after committing]
---

## Current State

Status: !`git status --short`

Unstaged diff: !`git diff`

Staged diff: !`git diff --cached`

Recent commits (for message style): !`git log --oneline -5`

Remote: !`git remote get-url origin 2>/dev/null || echo "no remote"`

Current branch: !`git branch --show-current`

---

## Instructions

### Step 1 — Analyse the changes
Read all staged and unstaged diffs above.
Identify the component (scope) and the type of change (fix/chore/feat/test/docs/refactor).

### Step 2 — Propose a commit message
Generate a conventional commit message:
```
<type>(<scope>): <present-tense description under 72 chars>
```

Examples of well-formed messages for this workflow:
- `fix(forward): prevent G115 integer overflow in port conversion`
- `chore(lint): fix gosec G115 in pkg/metrics workqueue registration`
- `test(forward): add regression test for int32 overflow boundary`
- `fix(crd): remove duplicate replicas field from Kafka schema`

Show the proposed message and ask: "Commit with this message? (yes/edit/abort)"

### Step 3 — Stage specific files
Do NOT use `git add -A` or `git add .`
Stage only the files shown in `git status --short` that are directly related to the fix:
```bash
git add path/to/file1.go path/to/file1_test.go
```

Do not stage:
- `.env` files
- `*_test` binaries or coverage output files
- Any file not related to the fix

### Step 4 — Commit
```bash
git commit -m "<approved message>"
```

If the repo requires DCO sign-off (coredns, cilium, strimzi):
```bash
git commit -s -m "<approved message>"
```

Check for DCO requirement: `grep -i "sign" CONTRIBUTING.md 2>/dev/null | head -3`

### Step 5 — Push (only if $ARGUMENTS contains "push")
```bash
git push -u origin HEAD
```

After pushing, output the branch URL and suggest:
```
Branch pushed. To open the PR:
  gh pr create --fill --web
Or directly:
  gh pr create --title "<commit message>" --body "<draft body>"
```

### Step 6 — Confirm
Output the commit hash, message, and file list:
```
✓ Committed: <hash>
  Message: <message>
  Files: <list>
  <If pushed: Branch URL>
```
