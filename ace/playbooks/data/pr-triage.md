# PR Triage

## Strategies & Insights
- [s1] helpful=3 harmful=0 :: Before writing any code: can you reproduce the bug or understand the root cause locally in <15 minutes? If no, skip it.
- [s2] helpful=3 harmful=0 :: Estimate fix size: if it looks like >50 lines of non-trivial changes, it is probably too large for a quick merge PR — look for smaller issues
- [s3] helpful=2 harmful=0 :: Check if there is already an open PR for the issue — if yes, skip. Check with: `gh pr list --repo <org>/<repo> --search "<issue title keywords>" --state open`
- [s4] helpful=2 harmful=0 :: Green flags: bug you can reproduce, fix is <50 lines, similar to something you have already fixed in another repo, issue has maintainer response confirming it is a real bug
- [s5] helpful=2 harmful=0 :: Red flags: no activity on the issue for >3 months, issue requires reading >500 lines of unfamiliar code to understand, issue is labeled needs-design or needs-discussion
- [s6] helpful=2 harmful=0 :: Check the issue's comment thread for maintainer direction — they often hint at the expected fix approach or say "we want to fix this differently"

## Formulas & Calculations
- [f1] helpful=2 harmful=0 :: Time budget rule: spend max 20 minutes evaluating an issue. If you cannot understand the root cause in 20 minutes, it is too complex for now — move to the next one.
- [f2] helpful=1 harmful=0 :: Confidence score: (can reproduce? +3) + (fix < 50 lines? +2) + (proven repo? +2) + (similar to past fix? +2) + (maintainer confirmed? +1) = max 10. Score >= 7 = proceed.

## Common Mistakes
- [m1] helpful=0 harmful=3 :: Spending 2+ hours on a PR only to have it closed because the maintainers already had a different approach in mind — always read the full comment thread first
- [m2] helpful=0 harmful=2 :: Picking issues in repos where you have never read the codebase — start in repos you already know
- [m3] helpful=0 harmful=2 :: Not checking for competing PRs before writing code — wasted effort if someone else is already working on it
- [m4] helpful=0 harmful=1 :: Overestimating your familiarity with a codebase — if you haven't touched it in 3+ months, re-read the relevant package before starting
