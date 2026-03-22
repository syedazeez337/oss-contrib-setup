---
description: Analyse the PR outcomes log and rewrite playbooks with improved strategies. Reads from ACE MCP if connected, otherwise from local files. Writes back via the same path.
---

## Instructions

### Step 0 — Load outcomes data

**If ACE MCP is connected:** use ACE MCP tool to fetch all recorded outcomes.

**If ACE is not available (local fallback):**
Use the Read tool to read `~/.claude/outcomes/outcomes.log`.
If the file is empty or missing: output "Not enough data. Log at least 3 outcomes with /record-outcome." then stop.

Count available outcomes. If fewer than 3: stop with the message above.

### Step 1 — Load current playbooks

**If ACE MCP is connected:** use ACE MCP tool to fetch each playbook: cncf-issue-finder, cncf-pr-quality, maintainer-response, pr-triage.

**If local fallback:** use the Read tool to read each file:
- `~/.claude/playbooks/cncf-issue-finder.md`
- `~/.claude/playbooks/cncf-pr-quality.md`
- `~/.claude/playbooks/maintainer-response.md`
- `~/.claude/playbooks/pr-triage.md`

### Step 2 — Extract patterns from outcomes

Analyse all outcomes and identify:
- Which repos had the highest merge rate?
- Which issue types (gosec, CRD, Helm, workqueue, overflow) had best hit rate?
- What diff sizes correlated with merges vs closures?
- How quickly did each repo respond?
- Why were PRs closed? (competing PR, scope, stale, maintainer preference)
- Any patterns in what the user got wrong repeatedly?

### Step 3 — Decide what to update in each playbook

For each playbook, identify:
- New strategies to add (pattern seen ≥2 times)
- Strategies to strengthen (consistently led to merges)
- Mistakes to add (pattern consistently led to closures)
- Strategies to deprecate (proved wrong)

Keep everything not contradicted by data.

### Step 4 — Rewrite all 4 playbooks

Rewrite each playbook with improved content. Keep the same format.
Add at the top: `> Last evolved: <YYYY-MM-DD> — based on <N> outcomes`

**If ACE MCP is connected:** write each updated playbook back via ACE MCP update tool.
**If local files:** use the Write tool to save updated content to `~/.claude/playbooks/<name>.md`.

### Step 5 — Output summary

```
✓ Playbooks evolved
  Outcomes analysed: <N>
  Storage: ACE (MCP) | local files

  cncf-issue-finder:   <1 line summary of what changed>
  cncf-pr-quality:     <1 line summary>
  maintainer-response: <1 line summary>
  pr-triage:           <1 line summary>
```
