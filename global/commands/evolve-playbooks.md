---
description: Analyse the PR outcomes log and rewrite playbooks with improved strategies. Reads from ACE MCP if connected, otherwise from the local outcomes log. Writes back via the same path.
---

## Outcomes Data

### From ACE (if MCP connected)
Use ACE MCP tool to fetch all recorded outcomes. If ACE is not available, fall back to local log below.

### From local log (fallback)
!`cat ~/.claude/outcomes/outcomes.log 2>/dev/null || echo "No local outcomes logged yet."`

## Current Playbooks

### From ACE (if MCP connected)
Use ACE MCP tool to fetch each playbook: cncf-issue-finder, cncf-pr-quality, maintainer-response, pr-triage.
If ACE not available, read from local files below.

### Local files (fallback)
!`cat ~/.claude/playbooks/cncf-issue-finder.md 2>/dev/null || echo "not found — run install.sh"`
!`cat ~/.claude/playbooks/cncf-pr-quality.md 2>/dev/null || echo "not found"`
!`cat ~/.claude/playbooks/maintainer-response.md 2>/dev/null || echo "not found"`
!`cat ~/.claude/playbooks/pr-triage.md 2>/dev/null || echo "not found"`

---

## Instructions

### Step 0 — Check data availability
Count available outcomes (ACE or local log).
If fewer than 3 outcomes: output "Not enough data. Log at least 3 outcomes with /record-outcome." then stop.

### Step 1 — Extract patterns from outcomes

Analyse all outcomes and identify:
- Which repos had the highest merge rate?
- Which issue types (gosec, CRD, Helm, workqueue, overflow) had best hit rate?
- What diff sizes correlated with merges vs closures?
- How quickly did each repo respond?
- Why were PRs closed? (competing PR, scope, stale, maintainer preference)
- Any patterns in what the user got wrong repeatedly?

### Step 2 — Decide what to update in each playbook

For each playbook, identify:
- New strategies to add (pattern seen ≥2 times)
- Strategies to strengthen (consistently led to merges)
- Mistakes to add (pattern consistently led to closures)
- Strategies to deprecate (proved wrong)

Keep everything not contradicted by data.

### Step 3 — Rewrite all 4 playbooks

Rewrite each playbook with improved content. Keep the same format.
Add at the top: `> Last evolved: <YYYY-MM-DD> — based on <N> outcomes`

**If ACE MCP is connected:** write each updated playbook back via the ACE MCP update tool.
**If local files:** write updated content to `~/.claude/playbooks/<name>.md`.

### Step 4 — Output summary

```
✓ Playbooks evolved
  Outcomes analysed: <N>
  Storage: ACE (MCP) | local files

  cncf-issue-finder:   <1 line summary of what changed>
  cncf-pr-quality:     <1 line summary>
  maintainer-response: <1 line summary>
  pr-triage:           <1 line summary>
```
