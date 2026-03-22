# Playbook: pr-triage

> This file is seeded from oss-contrib-setup and evolves via /evolve-playbooks
> based on real PR outcomes logged in ~/.claude/outcomes/outcomes.log

## Strategies
- Before writing any code: can you reproduce/understand root cause in <15 minutes? If no, skip.
- Estimate fix size: if >50 lines of non-trivial changes, it's probably too large — find smaller issues
- Always check for an existing open PR: `gh pr list --repo <org>/<repo> --search "<keywords>" --state open`
- Green flags: reproducible bug, fix <50 lines, similar to a past fix, maintainer confirmed it's real
- Red flags: no activity >3 months, requires reading >500 lines of unfamiliar code, labeled needs-design
- Read the full comment thread — maintainers often hint at the expected fix approach

## Time Budget
Spend max 20 minutes evaluating an issue. If root cause is unclear after 20 minutes → skip.

## Confidence Score
(can-reproduce? +3) + (fix<50lines? +2) + (proven-repo? +2) + (similar-to-past-fix? +2) + (maintainer-confirmed? +1) = max 10
Score ≥7 = proceed. Score <7 = reconsider.

## Common Mistakes
- Spending 2+ hours only to have PR closed because maintainers had a different approach — read the thread first
- Picking issues in repos you have never read the codebase for
- Not checking for competing PRs before writing code
