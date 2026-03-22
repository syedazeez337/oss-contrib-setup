# Mergeable Score Formula

## Base Formula

```
score = age_score + assignee_score + comment_score + label_score + repo_score + pattern_score
```

Maximum possible: 11 points.

## Scoring Breakdown

### age_score (0 or 2)
- +2 if issue was opened < 30 days ago
- +0 if issue is 30–90 days old
- −1 if issue is > 90 days old (maintainers may have moved on)

To calculate: compare `createdAt` field from gh JSON output to today's date.

### assignee_score (0 or 2)
- +2 if `assignees` array is empty
- +0 if anyone is assigned (even yourself — don't double-assign)

### comment_score (0 or 1)
- +1 if total comments < 5
- +0 if 5 or more comments (more comments = more contested or complex)

### label_score (0 or 2)
- +2 if any label matches: `kind/bug`, `bug`, `lint`, `gosec`, `chore`, `good-first-issue`
- +1 if label matches: `help-wanted`, `backlog`
- +0 for all other labels or no labels

### repo_score (0 or 2)
- +2 if repo is in the proven merge list:
  - coredns/coredns
  - cilium/cilium
  - strimzi/strimzi-kafka-operator
  - kagent-dev/kagent
  - clastix/kamaji
  - fluvio-community/fluvio
  - aquasecurity/trivy-checks
- +0 for all other repos

### pattern_score (0 or 2)
- +2 if the issue title or body contains any of:
  - `gosec`, `G114`, `G115`, `G116`, `G301`, `G302`, `G304`, `G401`, `G501`
  - `integer overflow`, `type conversion`, `int32`, `uint16`
  - `workqueue`, `metrics`, `duplicate metric`, `already registered`
  - `CRD`, `schema`, `OpenAPIV3Schema`, `x-kubernetes-`
  - `helm`, `values.yaml`, `chart`, `template`
  - `lint`, `vet`, `golangci`
- +0 otherwise

## Decision Thresholds

| Total Score | Decision | Action |
|---|---|---|
| 9–11 | HIGH CONFIDENCE | Proceed immediately after checking for competing PRs |
| 7–8 | GOOD | Check competing PRs, then proceed |
| 5–6 | BORDERLINE | Read full issue thread; only proceed if root cause is obvious |
| 3–4 | LOW | Skip unless no better options exist |
| 0–2 | SKIP | Move to next candidate |

## Automatic Disqualifiers (Score Irrelevant)

Regardless of score, disqualify if ANY of the following are true:
1. An open PR already exists targeting this issue
2. Issue has label `needs-design`, `needs-discussion`, `blocked`, `wontfix`, `invalid`
3. Last maintainer commit in the repo was > 90 days ago
4. The issue body describes a change requiring > 300 lines (estimate from description)
5. Issue requires deep understanding of a subsystem you have not read (e.g., eBPF datapath internals if unfamiliar)

## Tie-Breaking

When two issues have the same score:
1. Prefer the one in a faster-review repo (coredns > kagent > cilium > strimzi)
2. Prefer the newer issue
3. Prefer the one matching a known win pattern exactly (e.g., gosec G115 > generic bug)
