---
description: Search CNCF repos for high-probability mergeable issues. Returns top 3 scored candidates with an automatic triage preview on the top result.
argument-hint: [repo — e.g. cilium, coredns/coredns, or empty for priority list]
---

Target: $ARGUMENTS

Invoke the `cncf-issue-scout` skill with target "$ARGUMENTS".

If $ARGUMENTS is empty, search the full priority list:
coredns/coredns, cilium/cilium, strimzi/strimzi-kafka-operator, kagent-dev/kagent

After the skill returns the top 3 scored candidates, automatically invoke the
`issue-analyst` agent on the #1 ranked issue and append its full triage report
(root cause, scope, score, decision, next step) to the output.

Final output format:
1. Top 3 issue list from cncf-issue-scout
2. Full triage report for issue #1 from issue-analyst
3. One-line recommended action: "Run /plan in <repo directory> to begin" or "No strong candidates — try a different repo"

If the user is already inside a repo directory (git remote matches the target):
- Check if `.claude/plans/repo-*.md` exists for this repo
- If not: "Tip: run `repo-ingest` in this directory to learn the repo's conventions before writing any code."
