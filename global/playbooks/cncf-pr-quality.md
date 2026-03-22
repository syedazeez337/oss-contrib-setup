# Playbook: cncf-pr-quality

> This file is seeded from oss-contrib-setup and evolves via /evolve-playbooks
> based on real PR outcomes logged in ~/.claude/outcomes/outcomes.log

## Strategies
- One issue → one PR. Never bundle unrelated changes.
- Match the repo CONTRIBUTING.md format exactly before opening
- For Cilium: run `make lint` locally, reference the exact gosec rule number in PR title
- For CoreDNS: small scoped fixes merge fast. Always add DCO sign-off: `git commit -s`
- PR description: Problem → Root cause → Fix → Verification command → Fixes #N
- Never open a draft for a ready fix — open ready-to-merge or don't open
- Add a regression test if the project has tests for the area changed

## Size Limits
- <100 lines changed = fast review track
- 100–300 lines = add justification in PR body
- >300 lines = split into smaller PR + follow-up issue

## Commit Format
`fix(component): short present-tense description` — conventional commits
Always link: `Fixes #<n>` or `Closes #<n>` on its own line

## Common Mistakes
- Changing more than what the issue asks — maintainers request reverts
- Not running lint/tests locally before pushing — CI failures look careless
- Vague PR description — maintainers should not need to ask what the problem was
- Missing DCO sign-off in repos that require it (CoreDNS, Cilium, Strimzi)
