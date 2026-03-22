---
description: Rules for contributing to CNCF and open source Go projects — applied globally
---

# CNCF Contribution Rules

## Scope Discipline
- One issue → one PR. Never bundle unrelated changes, even if nearby in the code.
- PR title: conventional commits format — `fix(component): short present-tense description`
  - Examples: `fix(forward): prevent integer overflow in port conversion`
  - Examples: `chore(lint): fix gosec G115 in metrics registration`
- PR body structure (mandatory):
  1. **Problem:** one sentence — what is wrong
  2. **Root cause:** 1–2 sentences — why it is wrong
  3. **Fix:** one sentence — what the change does
  4. **Verification:** the exact command to confirm the fix
  5. `Fixes #<issue-number>` or `Closes #<issue-number>` on its own line

## Before Writing Any Code
1. Read the full issue including every comment
2. Check for existing open PRs: `gh pr list --repo <org>/<repo> --search "<keywords>" --state open`
3. Read the project's CONTRIBUTING.md: `gh api repos/<org>/<repo>/contents/CONTRIBUTING.md | jq -r '.content' | base64 -d`
4. Confirm you can reproduce the issue or understand the root cause in < 15 minutes
5. If you cannot reproduce it in 15 minutes → skip the issue

## Size Limits
| Diff size | Action |
|---|---|
| < 100 lines | Proceed normally — fast review track |
| 100–300 lines | Add a "Why the diff is this size" section to the PR body |
| > 300 lines | Stop. Split into a smaller PR + follow-up issue. |

## Lint / CI Before Every Push
Run the project's own suite locally — CI failures look careless:
- **Cilium:** `make lint` (needs Docker) or `golangci-lint run --timeout 10m`
- **CoreDNS:** `go vet ./... && golangci-lint run`
- **Strimzi:** `./mvnw checkstyle:check` or `./gradlew checkstyle`
- **Default Go:** `go vet ./... && golangci-lint run --timeout 5m`

## Review Response Protocol
- Respond to every review comment within 24 hours
- Never argue about style — do it their way, move on
- After pushing fixes, add a comment summarising what changed: "Addressed: added bounds check per feedback, updated test to cover overflow case"
- Mark each reviewer comment as resolved after addressing it
- Force-push only if the project explicitly asks for rebased commits (most do)

## Stall Protocol
- PR stalled > 2 weeks after your last update → ping once: "Any chance to get another look? Happy to address more feedback."
- No response after another week → close the PR and move on

## Absolute Disqualifiers
Stop immediately — do not spend time on these:
- An open unmerged PR already targets the same issue
- Issue labeled `needs-design`, `needs-discussion`, or `blocked`
- Last maintainer commit in the repo > 3 months ago
- Fix cannot be scoped under 300 lines
- You cannot find the affected code with Grep/Glob in 5 minutes
