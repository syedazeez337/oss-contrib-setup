---
name: repo-ingest
description: Learn everything about a repository's contributing conventions, CI requirements, lint config, commit format, DCO/CLA rules, and maintainer patterns before starting any work. Run once per repo session — saves a profile to .claude/plans/repo-<owner>-<name>.md that all other skills read. Invoke when starting work on a new repo, or when asked to "learn this repo", "read the conventions", "understand the contributing guide", or "what does this repo require?".
version: 1.0.0
author: oss-contrib-setup
license: MIT
metadata:
  tags: [repo, conventions, contributing, lint, ci, onboarding, dco, cla]
  related_skills: [fix-loop, pr-preflight, writing-plans, cncf-issue-scout]
---

# Repo Ingest

Learn the repository's full contribution requirements and save a profile that other skills read.
Run this ONCE at the start of working on any repo.

---

## Step 1 — Identify the repo

```bash
git remote get-url origin
git log --oneline -1
```

Parse the remote URL to extract `<owner>/<repo>`. This becomes the profile filename:
`.claude/plans/repo-<owner>-<repo>.md`

If a profile already exists and was generated today, output:
> "Profile already current — last generated: <date>. Re-run with 'refresh repo profile' to force update."
> Then print the summary section of the existing profile and stop.

---

## Step 2 — Read all source material in parallel

Read every file that exists. Skip gracefully if absent.

**Base branch:**
```bash
BASE=$(git remote show origin 2>/dev/null | grep 'HEAD branch' | awk '{print $NF}')
[ -z "$BASE" ] && BASE=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||')
[ -z "$BASE" ] && BASE=$(git branch -r | grep -E 'origin/(main|master|trunk|develop)' | head -1 | sed 's|.*origin/||' | tr -d ' ')
[ -z "$BASE" ] && BASE="main"
echo "Base branch: $BASE"
```

**Contribution guidelines:**
```bash
cat CONTRIBUTING.md 2>/dev/null || echo "NOT FOUND"
cat DEVELOPMENT.md 2>/dev/null || echo "NOT FOUND"
cat .github/PULL_REQUEST_TEMPLATE.md 2>/dev/null || echo "NOT FOUND"
cat DCO 2>/dev/null || echo "NOT FOUND"
cat LICENSE | head -5
```

**Build and lint config:**
```bash
cat Makefile 2>/dev/null | head -100 || echo "NOT FOUND"
cat .golangci.yml 2>/dev/null || cat .golangci.yaml 2>/dev/null || echo "NOT FOUND"
cat go.mod | head -10 2>/dev/null || echo "NOT FOUND"
cat pom.xml | head -30 2>/dev/null || echo "NOT FOUND"  # Java repos
cat build.gradle | head -30 2>/dev/null || echo "NOT FOUND"  # Gradle repos
```

**CI workflows — what must pass before merge:**
```bash
ls .github/workflows/ 2>/dev/null || echo "no .github/workflows"
# Read each workflow file to extract job names and triggers
for f in .github/workflows/*.yml .github/workflows/*.yaml; do
  [ -f "$f" ] && echo "=== $f ===" && cat "$f"
done 2>/dev/null | head -500
```

**Actual conventions in practice — the ground truth:**
```bash
# Last 15 merged PRs (titles = commit format in practice)
gh pr list --repo <owner>/<repo> --state merged --limit 15 \
  --json number,title,body,mergedAt \
  --jq '.[] | "\(.number): \(.title)"' 2>/dev/null

# Last 15 commits (shows sign-off, format, scope)
git log --oneline -15
git log -3 --format="%H%n%s%n%b%n---"
```

---

## Step 3 — Synthesise the profile

Analyse all source material above and answer every field below.
Mark `UNKNOWN` only if genuinely not determinable.
**Prefer what git log shows in practice over what CONTRIBUTING.md says** — the log is ground truth.

```markdown
# Repo Profile: <owner>/<repo>
Generated: <YYYY-MM-DD>
Refresh: run `repo-ingest` again

## Identity
- Language: <detected language(s)>
- Module / artifact: <module path, maven artifact, crate name, npm package — whatever applies>
- Min language version: <version from go.mod / pom.xml / .python-version / Cargo.toml / .nvmrc — whatever exists>
- Base branch: <actual base branch>

## Commands

### Build
- Primary: `<command>`   # e.g. go build ./... | make build | ./mvnw package
- Check build: `<command>`
- Notes: <Docker required? special env vars?>

### Lint
- Primary: `<command>`   # e.g. golangci-lint run --timeout 5m | make lint
- Auto-fix: `<command or NOT SUPPORTED>`  # e.g. golangci-lint run --fix
- Config file: <.golangci.yml | none>
- Enabled linters: <comma-separated list from config>
- Notes: <Docker required? version pinned?>

### Test
- Primary: `<command>`   # e.g. go test ./... -count=1
- With race detector: `<command or N/A>`
- With coverage: `<command or N/A>`
- Targeted: `<command>`  # e.g. go test ./plugin/foo/... -v -run TestName -count=1
- Notes: <any special requirements>

## PR Requirements

### Sign-off
- Type: DCO | CLA | none
- Mechanism: <Probot/DCO bot | CLA assistant | manual>
- How to add: `git commit -s` | <sign CLA link> | nothing
- Verified from: <CONTRIBUTING.md | git log shows Signed-off-by | LICENSE>

### Commit Format
- Style: `<example from git log>` — e.g. `plugin/foo: fix gosec G115`
- Type prefix required: yes (<list>) | no
- Scope required: yes | no | optional
- Max subject line: <chars>
- Body required: yes | no
- Verified from: git log — <paste 3 real examples>

### PR Title Format
- Format: `<example>` — same as commit | different
- Enforced by bot: yes (<bot name>) | no
- Verified from: <merged PRs list>

### PR Body Required Sections
List every section the template or CONTRIBUTING.md specifies:
- [ ] <section 1>
- [ ] <section 2>
- [ ] <section 3>

### Branch naming
- Convention: <e.g. fix/issue-123 | feature/name | no convention>

## CI Gates (all must pass before merge)

List every GitHub Actions workflow job that runs on PR:
| Job | Workflow file | What it checks |
|-----|--------------|----------------|
| <job name> | <file.yml> | <description> |

Mandatory local pre-checks:
1. `<lint command>` — mirrors CI lint job
2. `<test command>` — mirrors CI test job
3. `<build command>` — mirrors CI build job

## Maintainer Patterns

Derived from last 15 merged PRs:
- Avg review turnaround: <hours/days>
- Preferred PR size: <lines>
- Most common review requests: <patterns seen>
- Known quick-merge patterns: <issue types that get merged fast>
- Maintainer names/handles: <list active reviewers from recent PRs>

## Known Gotchas

Anything surprising or non-obvious from CONTRIBUTING.md or CI config:
- <gotcha 1>
- <gotcha 2>
```

---

## Step 4 — Save the profile

Save the completed profile to:
```
.claude/plans/repo-<owner>-<repo>.md
```

Create `.claude/plans/` if it doesn't exist.

---

## Step 5 — Output summary

Print the actual values derived from the repo — never use placeholder text or examples here:

```
✓ Repo profile saved: .claude/plans/repo-<owner>-<repo>.md

  Language:     <actual language and version>
  Base branch:  <actual base branch>
  Build:        <actual build command>
  Lint:         <actual lint command> (auto-fix: <supported | not supported>)
  Test:         <actual test command>
  Sign-off:     <DCO | CLA | none> — <how to apply>
  Commit fmt:   <actual format from git log — paste a real example>
  PR sections:  <actual required sections from PR template>
  CI jobs:      <actual job names from .github/workflows/>

  Gotchas:
  <list actual non-obvious findings — or "none found" if nothing surprising>

Next step: run fix-loop or /pre-pr — they will read this profile automatically.
```

## References
@references/ci-patterns.md — Known CI patterns for common CNCF repos
