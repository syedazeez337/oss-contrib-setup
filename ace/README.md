# Playbook System

Fully local, no external services, no API keys.

Playbooks live at `~/.claude/playbooks/` and are plain markdown files.
They evolve over time using the AI already running in your session — no separate LLM calls needed.

## How It Works

```
/record-outcome merged      → appends entry to ~/.claude/outcomes/outcomes.log
/record-outcome closed
/record-outcome stalled

(after 5+ entries)

/evolve-playbooks           → reads the log, analyses patterns,
                              rewrites ~/.claude/playbooks/*.md in-session
```

The 4 playbooks:
| File | Purpose |
|---|---|
| `cncf-issue-finder.md` | Which repos and issue types to target |
| `cncf-pr-quality.md` | PR writing standards and scope rules |
| `maintainer-response.md` | Handling review feedback and timing |
| `pr-triage.md` | Go/no-go decision logic |

## Installation

Playbooks are installed by `install.sh` — they get copied (not symlinked) to
`~/.claude/playbooks/` so `/evolve-playbooks` can update them freely.

The outcomes log at `~/.claude/outcomes/outcomes.log` is append-only and
never tracked in git — it's personal state.

## Resetting Playbooks

To reset a playbook to its seed state:
```bash
cp ~/oss-contrib-setup/global/playbooks/cncf-issue-finder.md ~/.claude/playbooks/
```

To wipe the outcomes log and start fresh:
```bash
> ~/.claude/outcomes/outcomes.log
```

## Evolution Cadence

There is no trigger threshold. Use your judgement:
- Run `/evolve-playbooks` after any batch of outcomes (3–5 is enough to see patterns)
- Run it after a streak of closures — the playbook should adapt
- Run it after a streak of merges — reinforce what worked
