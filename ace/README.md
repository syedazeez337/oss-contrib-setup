# ACE Platform

Self-improving playbook system. Two modes — use whichever is available:

| Mode | When | What stores data |
|---|---|---|
| **Local (default)** | Always works, zero setup | `~/.claude/playbooks/` + `~/.claude/outcomes/outcomes.log` |
| **ACE MCP** | Requires paid ace-platform.ai account | postgres + redis via Docker |

The local mode is fully functional. ACE MCP adds structured storage if you have an account.

## Architecture (local mode — default)

```
~/.claude/playbooks/        ← 4 markdown files, seeded at install
~/.claude/outcomes/         ← outcomes.log, append-only
         ↓
/evolve-playbooks           ← in-session analysis + playbook rewrite (no external calls)
```

Evolution happens inside your current AI session — the AI reads the outcomes log and
rewrites the playbooks in-place. No external API calls. No API keys needed.

## Local Setup (done by install.sh)

`install.sh` copies the 4 seed playbooks to `~/.claude/playbooks/` and creates
`~/.claude/outcomes/outcomes.log`. Nothing else needed.

## ACE MCP Setup (optional — requires ace-platform.ai account)

If you have an account at ace-platform.ai:

```bash
bash ~/oss-contrib-setup/ace/setup.sh
```

What it does:
1. Clones `ace-platform` to `~/ace-platform`
2. Creates Python venv + installs dependencies
3. Starts postgres + redis via Docker Compose
4. Runs database migrations
5. Connects ACE to your session via MCP (requires valid account + API key)
6. Seeds the 4 core playbooks into ACE's database

### Reconnect MCP after reboot

```bash
~/ace-platform/start-ace.sh   # start Docker + services
source ~/.ace-credentials
claude mcp add --transport http ace http://localhost:8000/mcp \
  --header "X-API-Key: $ACE_API_KEY"
```

## Daily Usage

Both modes use the same commands — no change in workflow:

| Command | Local mode | ACE MCP mode |
|---|---|---|
| `/find-issue` | reads `~/.claude/playbooks/cncf-issue-finder.md` | reads from ACE DB |
| `/pre-pr` | reads `~/.claude/playbooks/cncf-pr-quality.md` | reads from ACE DB |
| `/record-outcome merged` | appends to `~/.claude/outcomes/outcomes.log` | writes to ACE DB |
| `/evolve-playbooks` | rewrites local files in-session | reads ACE DB, rewrites in-session |

## Troubleshooting (ACE MCP mode)

**Postgres fails to start:**
```bash
docker compose logs postgres -f
sudo ss -tlnp | grep 5432  # check for port conflict
```

**API not responding:**
```bash
cat /tmp/ace-api.log
curl http://localhost:8000/health
```

**MCP not in claude mcp list:**
```bash
source ~/.ace-credentials
claude mcp add --transport http ace http://localhost:8000/mcp \
  --header "X-API-Key: $ACE_API_KEY"
```

**Evolution error from ACE:**
Expected — ignore. Use `/evolve-playbooks` which runs in-session (no ACE call needed).
