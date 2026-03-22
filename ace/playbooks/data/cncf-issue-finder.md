# CNCF Issue Finder

## Strategies & Insights
- [s1] helpful=3 harmful=0 :: Target repos with confirmed merge history first: cilium/cilium, coredns/coredns, strimzi/strimzi-kafka-operator, kagent-dev/kagent, clastix/kamaji
- [s2] helpful=3 harmful=0 :: Winning issue types by merge rate: gosec lint warnings (G114/G115/G301/G304), workqueue metrics registration conflicts, CRD schema duplicate fields, Helm chart variable misconfiguration, integer overflow in type conversions
- [s3] helpful=2 harmful=0 :: Filter criteria: opened <30 days ago, no assignee, <5 comments, label kind/bug or good-first-issue or help-wanted
- [s4] helpful=0 harmful=2 :: Avoid: large feature PRs in any repo, issues requiring deep subsystem knowledge you don't have, issues where an unmerged PR already exists
- [s5] helpful=2 harmful=0 :: CoreDNS is the fastest-merging repo — gosec PRs merged in <24h consistently; start there when time is short
- [s6] helpful=2 harmful=0 :: GitHub search query: `repo:<org>/<repo> is:issue is:open no:assignee label:kind/bug` then filter by recency

## Formulas & Calculations
- [f1] helpful=2 harmful=0 :: Mergeable score = (age<30d?+2:0) + (no-assignee?+2:0) + (comments<5?+1:0) + (bug/lint label?+2:0) + (proven-repo?+2:0) + (win-pattern-match?+2:0); max=11; score>=7 is worth pursuing
- [f2] helpful=1 harmful=0 :: Time budget: spend max 20 minutes evaluating an issue. If root cause is unclear after 20 minutes, move to the next one.

## Common Mistakes
- [m1] helpful=0 harmful=3 :: Opening a PR for an issue that already has an unmerged PR — always check open PRs first: `gh pr list --repo <org>/<repo> --search "<keywords>" --state open`
- [m2] helpful=0 harmful=2 :: Spending time on repos where maintainers are inactive (last commit >3 months)
- [m3] helpful=0 harmful=2 :: Picking issues that require understanding >500 lines of unfamiliar code to understand root cause
- [m4] helpful=0 harmful=1 :: Trying to fix multiple issues in one PR — always one issue, one PR
