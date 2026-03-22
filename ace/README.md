# ACE Platform

Local self-improving playbook system. Uses Docker for infrastructure, no external API key needed.

## Architecture

```
Docker (postgres + redis)   ← structured storage
       ↓
ACE API + MCP server        ← HTTP API + MCP tool interface
       ↓
AI session (MCP)            ← reads/writes playbooks, records outcomes
       ↓
/evolve-playbooks           ← in-session analysis + playbook rewrite (no external LLM)
```

Evolution happens inside your current AI session — the AI reads the outcomes log and
rewrites the playbooks directly. No external API calls. No OpenAI. No Anthropic keys.

## Setup

One command:
```bash
bash ~/oss-contrib-setup/ace/setup.sh
```

Requires: Docker (already installed), Python 3.10+, git

What it does:
1. Clones `ace-platform` to `~/ace-platform`
2. Creates Python venv + installs dependencies
3. Starts postgres + redis via Docker Compose
4. Runs database migrations
5. Creates user account + API key
6. Connects ACE to your session via MCP
7. Seeds the 4 core playbooks

## Starting ACE After Reboot

```bash
~/ace-platform/start-ace.sh
```

## MCP Connection

Verify:
```bash
claude mcp list  # should show "ace"
```

Reconnect manually if needed:
```bash
source ~/.ace-credentials
claude mcp add --transport http ace http://localhost:8000/mcp \
  --header "X-API-Key: $ACE_API_KEY"
```

## Daily Usage

| Command | What happens |
|---|---|
| `/find-issue` | Reads `cncf-issue-finder` playbook from ACE via MCP |
| `/pre-pr` | Reads `cncf-pr-quality` playbook from ACE via MCP |
| `/record-outcome merged` | Writes outcome to ACE via MCP |
| `/evolve-playbooks` | Reads all outcomes from ACE, rewrites playbooks in-session, writes back |

## Playbooks

Stored in ACE's database. Seeded from `global/playbooks/*.md`.
Rewritten in-place by `/evolve-playbooks` — no API key needed for this.

Reset a playbook to seed state:
```bash
source ~/.ace-credentials
curl -X PUT http://localhost:8000/playbooks/<name> \
  -H "Authorization: Bearer $ACE_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"content\": \"$(cat ~/oss-contrib-setup/global/playbooks/<name>.md | python3 -c 'import sys,json; print(json.dumps(sys.stdin.read()))')\"}"
```

## Troubleshooting

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

**MCP not connecting:**
```bash
# Re-run from credentials
source ~/.ace-credentials
claude mcp add --transport http ace http://localhost:8000/mcp \
  --header "X-API-Key: $ACE_API_KEY"
```

**Evolution error (LLM not configured):**
This is expected — ignore any ACE-side evolution errors.
Use `/evolve-playbooks` instead, which runs in your current session.
