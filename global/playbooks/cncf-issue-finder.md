# Playbook: cncf-issue-finder

> This file is seeded from oss-contrib-setup and evolves via /evolve-playbooks
> based on real PR outcomes logged in ~/.claude/outcomes/outcomes.log

## Strategies
- Target repos with confirmed merge history: cilium/cilium, coredns/coredns, strimzi/strimzi-kafka-operator, kagent-dev/kagent, clastix/kamaji
- Winning issue types: gosec lint warnings (G114/G115/G301/G304), workqueue metrics conflicts, CRD schema duplicate fields, Helm chart misconfiguration, integer overflow type conversions
- Filter: opened <30 days ago, no assignee, <5 comments, label kind/bug or good-first-issue
- CoreDNS is fastest-merging — gosec PRs merged in <24h consistently; start there when time is short
- Search query: `repo:<org>/<repo> is:issue is:open no:assignee label:kind/bug`

## Scoring Formula
Mergeable score = (age<30d?+2:0) + (no-assignee?+2:0) + (comments<5?+1:0) + (bug/lint label?+2:0) + (proven-repo?+2:0) + (win-pattern-match?+2:0)
Max = 11. Score ≥ 7 = worth pursuing. Score 5–6 = check competing PRs first. Score <5 = skip.

## Disqualifiers (skip regardless of score)
- Open competing PR already exists for the issue
- Label: needs-design, needs-discussion, blocked, wontfix, invalid
- Last maintainer commit >90 days ago
- Fix scope >300 lines

## Common Mistakes
- Opening a PR for an issue that already has an unmerged PR — always check first
- Spending time in repos where maintainers are inactive
- Picking issues requiring >500 lines of unfamiliar code to understand root cause
- Multiple issues in one PR
