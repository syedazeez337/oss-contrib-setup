---
description: Record a PR outcome. Writes to ACE via MCP if connected, otherwise to the local outcomes log.
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
Extract from $ARGUMENTS: `merged`, `closed`, or `stalled`.
If not present, ask: "What was the outcome? (merged / closed / stalled)"

### Step 2 — Check ACE connection
The ACE MCP server should be in the connected tools list.

**If ACE MCP is available:** use the ACE `record_outcome` MCP tool with:
- outcome: the type
- repo: from git remote
- pr_url: from gh pr view
- files_changed: from git diff
- notes: any text after the outcome type in $ARGUMENTS

**If ACE MCP is not available:** fall back to the local log:
```bash
mkdir -p ~/.claude/outcomes
```
Append a structured entry to `~/.claude/outcomes/outcomes.log`:
```
---
date: <YYYY-MM-DD>
outcome: <type>
repo: <org/repo>
branch: <branch>
pr_url: <url or none>
files_changed: <list>
notes: <notes>
---
```

To start ACE: `~/ace-platform/start-ace.sh`
Then reconnect: `source ~/.ace-credentials && claude mcp add --transport http ace http://localhost:8000/mcp --header "X-API-Key: $ACE_API_KEY"`

### Step 3 — Count total outcomes
If ACE: query the outcomes count via MCP.
If local: `grep -c "^outcome:" ~/.claude/outcomes/outcomes.log 2>/dev/null || echo 0`

### Step 4 — Output
```
✓ Outcome recorded
  Type:    <merged|closed|stalled>
  Repo:    <repo>
  Storage: ACE (MCP) | local log
  Total:   <N> outcomes
```

If total ≥ 5: suggest running `/evolve-playbooks`
