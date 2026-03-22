---
description: Record a PR outcome to ACE platform to feed playbook evolution. Run after any PR is merged, closed, or has stalled for 2+ weeks.
argument-hint: [merged|closed|stalled] [optional context note]
---

## Outcome to Record

Outcome type: $ARGUMENTS

## Current Context

Repo: !`git remote get-url origin 2>/dev/null || echo "not a git repo"`
Branch: !`git branch --show-current 2>/dev/null || echo "unknown"`
PR info: !`gh pr view --json number,title,url,state,mergedAt 2>/dev/null || echo "no PR found for current branch"`
Files changed: !`git diff main...HEAD --name-only 2>/dev/null || echo "no diff"`

---

## Steps

### Step 1 — Verify ACE connection

```bash
claude mcp list
```

Look for "ace" in the output.

**If ACE is connected:** proceed to Step 2.

**If ACE is NOT connected:**
Output these instructions:
```
ACE is not connected. To connect:

1. Start ACE:
   ~/ace-platform/start-ace.sh

2. Get your API key from ACE:
   curl http://localhost:8000/api-keys \
     -H "Authorization: Bearer <your-token>"

3. Connect via MCP:
   claude mcp add --transport http ace http://localhost:8000/mcp \
     --header "X-API-Key: <YOUR_API_KEY>"

4. Restart the session and re-run /record-outcome
```
Then stop — do not proceed without ACE.

### Step 2 — Record the outcome via ACE MCP

Use the ACE MCP `record_outcome` tool with:
- outcome: the type from $ARGUMENTS (merged / closed / stalled)
- pr_url: from the gh pr view output above
- repo: from git remote
- notes: any context from $ARGUMENTS after the outcome type
- files_changed: from git diff output

### Step 3 — Confirm

After recording, output:
```
✓ Outcome recorded to ACE
  Type: <merged|closed|stalled>
  PR: <url>
  Playbooks affected: cncf-pr-quality, cncf-issue-finder (if applicable)
  Evolution status: triggers automatically after 5 outcomes per playbook
```

### Step 4 — Reflection (merged or closed only)

Ask one question to capture a lesson:
- **If merged:** "What was the single most important factor that got this merged? (speed of response, issue type, PR size, etc.)"
- **If closed:** "What was the main reason it was closed? (competing PR, scope, maintainer preference, wrong approach)"

Record the answer as a note on the outcome if ACE supports it.
