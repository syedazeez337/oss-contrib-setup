# Azeez — Global Dev Profile

## Identity
Go/cloud-native engineer contributing to CNCF open source projects.
Primary goal: maximize merged PRs per month to build a track record for
cloud-native/Kubernetes engineering roles.

GitHub: syedazeez337

## Stack
- **Primary:** Go (idiomatic patterns, CNCF conventions, controller-runtime)
- **Secondary:** C, C++, Rust, eBPF
- **Infrastructure:** Kubernetes, Cilium, CoreDNS, Strimzi, Kafka, Helm, CRDs
- **Tooling:** gh CLI, docker, make, git, golangci-lint, gosec

## Proven Merge History
Repos with confirmed successful merges — prioritize these for new issues:
- `cilium/cilium` — gosec G114/G115, workqueue metrics conflicts
- `coredns/coredns` — gosec fixes, fast reviews (<24h)
- `strimzi/strimzi-kafka-operator` — CRD schema bugs, Helm config fixes
- `kagent-dev/kagent` — Go bugs
- `clastix/kamaji`, `fluvio-community/fluvio`, `aquasecurity/trivy-checks`

## Winning Issue Patterns (Highest Merge Probability)
1. gosec lint warnings — G114 (http timeouts), G115 (integer overflow), G301 (dir perms), G304 (file path taint)
2. Workqueue metrics registration conflicts (duplicate metric names)
3. CRD schema duplicate or invalid fields
4. Helm chart variable misconfiguration
5. Integer overflow in type conversions (int64 → int32, uint casting)

## Daily Workflow
1. `/find-issue [repo]` — Scout issues, score for merge probability
2. `issue-analyst` agent — Triage: root cause, scope, go/no-go
3. `writing-plans` skill — Produce a .claude/plans/*.md before touching code
4. `tdd-go` skill — Red-green-refactor, no production code without a failing test first
5. `systematic-debugging` skill — Root cause before any fix, no exceptions
6. `/pre-pr` — Quality gate before any PR opens
7. `/review` — go-reviewer agent on final diff
8. `/commit [push]` — Conventional commit + push
9. `/record-outcome [merged|closed|stalled]` — Feed ACE for playbook evolution

## Playbooks (Self-Improving)
Playbooks evolve from real PR outcomes. No external API key needed — evolution runs in-session.

ACE is the preferred backend (Docker: postgres + redis + MCP).
Local files (`~/.claude/playbooks/`) are the fallback when ACE is offline.

Start ACE: `~/ace-platform/start-ace.sh`
Verify MCP: `claude mcp list` — look for "ace"
Setup guide: `~/oss-contrib-setup/ace/README.md`

After each PR outcome: `/record-outcome [merged|closed|stalled]`
After 5+ outcomes: `/evolve-playbooks` — reads outcomes, rewrites playbooks in-session

## Non-Negotiable Rules
- One issue → one PR. Never bundle unrelated changes.
- PRs under 100 lines of change. 100–300 needs written justification. 300+ means split.
- Always run `make lint` or `golangci-lint run` before pushing.
- Always check for an existing open PR on the issue before writing any code.
- Never open a draft for a ready fix — open ready-to-merge or don't open.
- Respond to review comments within 24 hours.
- Ping once if PR stalls 2 weeks post-update. Close after another week of silence.
