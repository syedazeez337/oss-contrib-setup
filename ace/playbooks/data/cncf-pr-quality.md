# CNCF PR Quality

## Strategies & Insights
- [s1] helpful=3 harmful=0 :: Keep scope tight — one issue, one fix, one PR. Never bundle unrelated changes even if they are nearby in the code.
- [s2] helpful=3 harmful=0 :: Match the repo CONTRIBUTING.md format exactly before opening. CoreDNS, Cilium, Strimzi all have specific requirements.
- [s3] helpful=2 harmful=0 :: For Cilium: run `make lint` locally before pushing. Reference the exact gosec rule number in the PR title (e.g., G115, G114).
- [s4] helpful=2 harmful=0 :: For CoreDNS: small scoped fixes merge fast — both gosec PRs merged in <24h. Keep it simple. Add DCO sign-off: `git commit -s`.
- [s5] helpful=2 harmful=0 :: PR description structure: Problem (1 sentence) → Root cause (1-2 sentences) → Fix (1 sentence) → Verification command → Fixes #<n>
- [s6] helpful=2 harmful=0 :: Never open a draft for a ready fix. Open ready-to-merge or do not open.
- [s7] helpful=1 harmful=0 :: Add a regression test if the project has tests for the area you changed. Maintainers notice when you skip tests.

## Formulas & Calculations
- [f1] helpful=2 harmful=0 :: PR size guideline: <100 lines changed = fast review track; 100-300 lines = needs justification in PR body; >300 lines = split it

## Code Snippets
- [c1] helpful=2 harmful=0 :: Standard PR title: `fix(component): short description` — conventional commits format
- [c2] helpful=1 harmful=0 :: Always link the issue: `Fixes #<n>` or `Closes #<n>` on its own line in the PR body

## Common Mistakes
- [m1] helpful=0 harmful=3 :: Changing more than what the issue asks — maintainers will ask you to revert unrelated changes
- [m2] helpful=0 harmful=2 :: Not running the project's lint/test suite locally before pushing — CI failures look careless
- [m3] helpful=0 harmful=2 :: Vague PR description — maintainers should not have to ask what the problem was
- [m4] helpful=0 harmful=1 :: Missing DCO sign-off in repos that require it (CoreDNS, Cilium, Strimzi) — bot will block merge
