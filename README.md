# oss-contrib-setup

A complete, self-improving AI-assisted development environment for open source Go/CNCF
contribution. Built for engineers who want to maximize merged PRs and build a track record
in cloud-native/Kubernetes engineering.

## What This Is

A layered system combining:
- **AI assistant configuration** — skills, agents, commands, and rules tuned for CNCF Go contribution
- **ACE platform** — a self-improving playbook system that learns from every PR outcome
- **Proven methodology** — TDD, systematic debugging, and preflight gates adapted from production-grade agents

## Architecture

```
oss-contrib-setup/
│
├── global/                     # Installs to ~/.claude/
│   ├── CLAUDE.md               # Global profile: stack, workflow, non-negotiables
│   ├── settings.json           # Permissions: allow go/make/gh/git; deny rm -rf/.env
│   │
│   ├── rules/                  # Path-scoped instruction files (auto-loaded)
│   │   ├── go-conventions.md   # Naming, errors, testing, concurrency, imports
│   │   ├── cncf-contrib.md     # One-issue-one-PR, scope limits, review protocol
│   │   └── security.md         # gosec G114/G115/G301/G304 patterns with examples
│   │
│   ├── skills/                 # Auto-invoked when intent matches description
│   │   ├── cncf-issue-scout/   # Find + score issues; returns top 3 candidates
│   │   ├── pr-preflight/       # 6-gate quality check before any PR opens
│   │   ├── systematic-debugging/  # 4-phase root-cause methodology (iron law)
│   │   ├── tdd-go/             # Red-green-refactor with Go-specific patterns
│   │   └── writing-plans/      # Bite-sized plan files saved to .claude/plans/
│   │
│   ├── agents/                 # Isolated subagent personas
│   │   ├── go-reviewer.md      # Security + correctness + quality review
│   │   └── issue-analyst.md    # Root cause + scope + mergeable score + go/no-go
│   │
│   ├── playbooks/              # Seed files → copied to ~/.claude/playbooks/
│   │   ├── cncf-issue-finder.md
│   │   ├── cncf-pr-quality.md
│   │   ├── maintainer-response.md
│   │   └── pr-triage.md
│   │
│   └── commands/               # Slash commands for daily workflow
│       ├── find-issue.md       # /find-issue [repo]
│       ├── pre-pr.md           # /pre-pr
│       ├── review.md           # /review
│       ├── commit.md           # /commit [push]
│       ├── record-outcome.md   # /record-outcome [merged|closed|stalled]
│       └── evolve-playbooks.md # /evolve-playbooks
│
└── ace/                        # Local playbook system docs + init script
    ├── README.md               # How the local playbook system works
    └── setup.sh                # Standalone init (install.sh handles this automatically)
```

**After install, these live locally and are never tracked in git:**
```
~/.claude/playbooks/    ← copied from global/playbooks/, updated by /evolve-playbooks
~/.claude/outcomes/     ← outcomes.log, append-only, personal state
```

## Quick Start

### 1. Install configuration

```bash
git clone https://github.com/syedazeez337/oss-contrib-setup.git ~/oss-contrib-setup
bash ~/oss-contrib-setup/install.sh
```

This symlinks `skills/`, `agents/`, `commands/`, `rules/` into `~/.claude/` and copies
`CLAUDE.md` and `settings.json`. Future `git pull` updates skills automatically.

No further setup needed. The playbook system is fully local — no Docker, no databases, no API keys.
Playbooks were copied to `~/.claude/playbooks/` and the outcomes log was created at `~/.claude/outcomes/outcomes.log` during install.

### 3. Start working

```
/find-issue                    # find today's issues
/find-issue coredns/coredns    # target a specific repo
```

---

## Daily Workflow

```
1. /find-issue [repo]
   → cncf-issue-scout skill searches repos, scores each issue
   → issue-analyst agent triages the top candidate (root cause, scope, go/no-go)

2. (read the triage report — decide to proceed)

3. writing-plans skill
   → produces .claude/plans/YYYY-MM-DD_<slug>.md
   → exact file paths, function names, verification commands

4. tdd-go skill during implementation
   → write failing test first, then minimal fix, then refactor

5. systematic-debugging skill if blocked
   → root cause before any fix, always

6. /review
   → go-reviewer agent audits the diff
   → security, correctness, test coverage, quality

7. /pre-pr
   → 6 gates: scope, lint, tests, diff size, description, competing PRs

8. /commit [push]
   → conventional commit message generated from diff
   → stages specific files, commits, optionally pushes

9. /record-outcome [merged|closed|stalled]
   → feeds ACE; playbooks evolve after 5 outcomes each
```

---

## Skills Reference

| Skill | Trigger | What it does |
|---|---|---|
| `cncf-issue-scout` | `/find-issue`, "find me issues", "what should I work on" | Searches repos, scores, returns top 3 |
| `pr-preflight` | `/pre-pr`, "check before PR", "preflight" | 6 quality gates |
| `systematic-debugging` | "debug", "why is this failing", "root cause" | 4-phase root cause methodology |
| `tdd-go` | "write tests", "TDD", "test first" | Red-green-refactor cycle |
| `writing-plans` | "plan", "before I start", multi-file tasks | Saves plan to .claude/plans/ |

## Agents Reference

| Agent | Trigger | What it does |
|---|---|---|
| `go-reviewer` | `/review`, "review this", "code review" | Security + correctness + merge verdict |
| `issue-analyst` | Automatically after `/find-issue` | Root cause + scope + mergeable score |

## Commands Reference

| Command | Args | What it does |
|---|---|---|
| `/find-issue` | `[repo]` optional | Scout + score + triage top issue |
| `/pre-pr` | none | Run 6-gate quality check |
| `/review` | none | go-reviewer on current diff |
| `/commit` | `[push]` optional | Conventional commit + optional push |
| `/record-outcome` | `merged\|closed\|stalled` | Append outcome to local log |
| `/evolve-playbooks` | none | Analyse log, rewrite playbooks in-session |

---

## Playbooks

Four markdown files in `~/.claude/playbooks/` — consulted by skills and commands,
rewritten by `/evolve-playbooks` based on real outcomes:

| Playbook | What it tracks |
|---|---|
| `cncf-issue-finder.md` | Which repos, issue types, and filters yield merges |
| `cncf-pr-quality.md` | PR description standards, scope rules, CI requirements |
| `maintainer-response.md` | Response timing, communication patterns |
| `pr-triage.md` | Go/no-go heuristics calibrated to your personal hit rate |

No external services. Evolution happens in-session — the AI reads your outcomes log
and rewrites the files. The longer you use the system, the more calibrated it becomes.

---

## Updating

```bash
cd ~/oss-contrib-setup
git pull
```

Skills, agents, commands, and rules are symlinked — updates are live immediately.
`CLAUDE.md` and `settings.json` are copied at install time so your edits are preserved.

---

## Sources and Credits

- Skill structure and SKILL.md format: [MiniMax-AI/skills](https://github.com/MiniMax-AI/skills)
- Debugging and TDD methodology: [NousResearch/hermes-agent](https://github.com/NousResearch/hermes-agent)
- Plugin/agent/command patterns: official AI assistant plugin documentation
- ACE platform: [DannyMac180/ace-platform](https://github.com/DannyMac180/ace-platform)
- .claude/ folder anatomy: community documentation
