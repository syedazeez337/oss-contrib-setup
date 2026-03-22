---
name: cncf-issue-scout
description: Find and score high-probability mergeable issues across CNCF Go projects. Invoke when looking for issues to work on, evaluating which repos to target today, or when asked to find open source contribution opportunities. Returns top 3 scored candidates with triage previews.
version: 1.0.0
author: oss-contrib-setup
license: MIT
metadata:
  tags: [cncf, github, go, issues, open-source, contribution]
  related_skills: [pr-preflight, writing-plans]
---

# CNCF Issue Scout

Find and score open issues across proven CNCF repositories using the mergeable score formula.

## Prerequisites
- `gh` CLI authenticated: run `gh auth status` to verify
- Read the `cncf-issue-finder` playbook before starting: via ACE MCP if connected, otherwise `~/.claude/playbooks/cncf-issue-finder.md`

## Workflow

### Step 1 — Determine Target Repos

If the user specifies a repo (e.g., `cilium`, `cilium/cilium`), search only that repo.

If no repo specified, use this priority order (confirmed merge history):
1. `coredns/coredns` — fastest reviews, gosec PRs merged in <24h
2. `cilium/cilium` — high issue volume, good CI automation
3. `strimzi/strimzi-kafka-operator` — CRD/Helm fixes welcome
4. `kagent-dev/kagent` — small team, responsive maintainers
5. `clastix/kamaji`
6. `fluvio-community/fluvio`
7. `aquasecurity/trivy-checks`

Search the top 3 from this list in parallel.

### Step 2 — Search Each Repo

Run both queries per repo:

```bash
# Bug issues (no assignee, recent)
gh issue list --repo <org>/<repo> \
  --label "kind/bug" --state open \
  --json number,title,createdAt,comments,assignees,labels \
  --limit 20

# Good first issue / help wanted
gh issue list --repo <org>/<repo> \
  --label "good-first-issue" --state open \
  --json number,title,createdAt,comments,assignees,labels \
  --limit 10
```

For repos without `kind/bug`, try `bug` or no label filter with `--search "gosec OR overflow OR lint"`.

### Step 3 — Score Each Issue

Compute a **Mergeable Score** for every candidate:

| Criterion | Points |
|---|---|
| Issue opened < 30 days ago | +2 |
| No assignee | +2 |
| < 5 comments | +1 |
| Label includes bug / lint / gosec / chore | +2 |
| Repo is in proven list | +2 |
| Title matches known win pattern | +2 |

**Known win patterns** (title keywords): `gosec`, `G114`, `G115`, `G301`, `G304`, `overflow`,
`workqueue`, `metrics`, `duplicate`, `CRD`, `schema`, `helm`, `lint`, `vet`, `conversion`

Scoring thresholds — see @references/scoring-formula.md for detailed rules.

| Score | Decision |
|---|---|
| ≥ 7 | Worth pursuing |
| 5–6 | Borderline — check for competing PRs before deciding |
| < 5 | Skip |

### Step 4 — Disqualify Competing PRs

For every issue scoring ≥ 5, run:

```bash
gh pr list --repo <org>/<repo> \
  --search "<2-3 keywords from issue title>" \
  --state open \
  --json number,title,createdAt
```

If any open PR targets the same issue → **disqualify immediately**. Do not proceed with that issue.

### Step 5 — Output

Return exactly **top 3 surviving candidates** in this format:

```
## Top Issues Found — <date>

### 1. [Score: 9/11] coredns/coredns #1234
**Title:** fix gosec G115 integer overflow in forward plugin
**Age:** 4 days | **Assignee:** none | **Comments:** 2
**Labels:** kind/bug
**Win pattern match:** gosec G115, integer overflow
**Competing PRs:** none found
**Recommendation:** HIGH CONFIDENCE — run /plan next

---

### 2. [Score: 7/11] cilium/cilium #5678
...

### 3. [Score: 6/11] strimzi/strimzi-kafka-operator #910
...

---
Next step: run `issue-analyst` agent on issue #1 for root cause + scope estimate.
```

## References
@references/scoring-formula.md — Full scoring algorithm with edge cases
@references/repo-profiles.md — Per-repo CONTRIBUTING quirks, lint commands, review speed
