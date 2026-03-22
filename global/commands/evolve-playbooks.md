---
description: Analyse the outcomes log and rewrite the playbooks with improved strategies based on real PR results. Run after every 5+ recorded outcomes.
---

## Outcomes Log

!`cat ~/.claude/outcomes/outcomes.log 2>/dev/null || echo "No outcomes logged yet. Run /record-outcome after each PR."`

## Outcome Count

!`grep -c "^outcome:" ~/.claude/outcomes/outcomes.log 2>/dev/null || echo 0`

## Current Playbooks

### cncf-issue-finder
!`cat ~/.claude/playbooks/cncf-issue-finder.md 2>/dev/null || echo "not found — run install.sh"`

### cncf-pr-quality
!`cat ~/.claude/playbooks/cncf-pr-quality.md 2>/dev/null || echo "not found"`

### maintainer-response
!`cat ~/.claude/playbooks/maintainer-response.md 2>/dev/null || echo "not found"`

### pr-triage
!`cat ~/.claude/playbooks/pr-triage.md 2>/dev/null || echo "not found"`

---

## Instructions

If there are fewer than 3 outcomes logged, output:
```
Not enough data yet. Log at least 3 PR outcomes with /record-outcome first.
Current count: <N>
```
Then stop.

Otherwise, perform the following analysis and evolution:

### Step 1 — Pattern extraction
Read all outcomes and identify:
- Which repos produced merges vs closures?
- Which issue types (gosec, CRD, Helm, workqueue) had the best hit rate?
- What was the typical diff size for merged PRs?
- How quickly did reviews respond in each repo?
- Were there any patterns in why PRs were closed (competing PR, wrong scope, stale, requested approach change)?

### Step 2 — Strategy updates
For each of the 4 playbooks, decide what to add, strengthen, downgrade, or remove:
- Add a strategy if a pattern appears in ≥2 outcomes
- Strengthen (`helpful` score) if a strategy consistently led to merges
- Downgrade or add a mistake if a pattern consistently led to closures
- Remove or mark harmful if something clearly backfired

### Step 3 — Rewrite playbooks
Rewrite all 4 playbook files at:
- `~/.claude/playbooks/cncf-issue-finder.md`
- `~/.claude/playbooks/cncf-pr-quality.md`
- `~/.claude/playbooks/maintainer-response.md`
- `~/.claude/playbooks/pr-triage.md`

Keep the same format (Strategies, Common Mistakes sections). Keep the evolve note at the top.
Add a `## Last evolved` line at the top with today's date and outcome count.

Do not remove strategies that are still valid — only add, adjust, or deprecate.

### Step 4 — Summary
Output:
```
✓ Playbooks evolved
  Outcomes analysed: <N>
  cncf-issue-finder: <what changed>
  cncf-pr-quality:   <what changed>
  maintainer-response: <what changed>
  pr-triage:         <what changed>
```
