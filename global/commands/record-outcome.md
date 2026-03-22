---
description: Record a PR outcome to the local outcomes log. Feeds /evolve-playbooks which improves playbooks from real results.
argument-hint: [merged|closed|stalled] [optional note]
---

## Outcome to Record

Type: $ARGUMENTS

## Current Context

Repo: !`git remote get-url origin 2>/dev/null || echo "not in a git repo"`
Branch: !`git branch --show-current 2>/dev/null || echo "unknown"`
PR: !`gh pr view --json number,title,url,state 2>/dev/null || echo "no PR on this branch"`
Files changed: !`git diff main...HEAD --name-only 2>/dev/null || git diff master...HEAD --name-only 2>/dev/null || echo "no diff"`

---

## Instructions

### Step 1 — Parse the outcome type
Extract the outcome type from $ARGUMENTS: `merged`, `closed`, or `stalled`.
If not provided, ask: "What was the outcome? (merged / closed / stalled)"

### Step 2 — Ensure outcomes directory exists
```bash
mkdir -p ~/.claude/outcomes
```

### Step 3 — Append to outcomes log
Write a structured entry to `~/.claude/outcomes/outcomes.log`:

```
---
date: <today YYYY-MM-DD>
outcome: <merged|closed|stalled>
repo: <org/repo from git remote>
branch: <branch name>
pr_url: <from gh pr view, or "none">
files_changed: <list from git diff>
notes: <anything after the outcome type in $ARGUMENTS>
---
```

Use the Write or Edit tool to append this entry to `~/.claude/outcomes/outcomes.log`.
If the file does not exist yet, create it.

### Step 4 — Count outcomes
Check how many entries are in `~/.claude/outcomes/outcomes.log`:
```bash
grep -c "^outcome:" ~/.claude/outcomes/outcomes.log 2>/dev/null || echo 0
```

### Step 5 — Output summary
```
✓ Outcome recorded
  Type:    <merged|closed|stalled>
  Repo:    <repo>
  Total outcomes logged: <N>
```

If total outcomes ≥ 5:
```
  → You have <N> outcomes logged. Run /evolve-playbooks to improve your playbooks.
```
