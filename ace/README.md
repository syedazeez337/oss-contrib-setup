# ACE Platform Setup

ACE is a self-improving AI agent system that stores structured playbooks.
Playbooks evolve automatically based on real PR outcomes — every merged or closed PR
feeds back into the system, making the playbooks smarter over time.

## What ACE Does for This Workflow

| Playbook | Purpose |
|---|---|
| `cncf-issue-finder` | Scores issues for merge probability; improves as your history grows |
| `cncf-pr-quality` | PR writing standards; evolves from reviewer feedback patterns |
| `maintainer-response` | Response timing and communication; learns from your merge velocity |
| `pr-triage` | Go/no-go decision logic; calibrates to your actual hit rate |

## Prerequisites

```bash
python3 --version    # Need 3.10+
docker --version     # Need Docker Engine (not Desktop)
docker compose version  # Need Compose v2
git --version
gh --version         # GitHub CLI
```

Install missing tools:
```bash
# Python (Fedora/RHEL)
sudo dnf install python3 python3-pip python3-venv -y

# Docker Engine (Fedora)
sudo dnf install docker-ce docker-ce-cli containerd.io docker-compose-plugin -y
sudo systemctl enable --now docker
sudo usermod -aG docker $USER  # log out and back in after this

# GitHub CLI (Fedora)
sudo dnf install gh -y
```

---

## Automated Setup

Run the setup script — it handles everything:

```bash
bash ~/oss-contrib-setup/ace/setup.sh
```

The script will:
1. Clone `ace-platform` to `~/ace-platform`
2. Create a Python virtual environment
3. Install dependencies
4. Start Docker services (postgres + redis)
5. Run database migrations
6. Create your user account
7. Create an API key
8. Connect ACE via MCP
9. Seed the 4 core playbooks

---

## Manual Setup (step by step)

If you prefer to run steps individually:

### Step 1 — Clone and Install

```bash
git clone https://github.com/DannyMac180/ace-platform.git ~/ace-platform
cd ~/ace-platform
python3 -m venv venv
source venv/bin/activate
pip install -e ".[dev]"
```

Verify:
```bash
python -c "import ace_platform; print('OK')"
```

### Step 2 — Start Infrastructure

```bash
cd ~/ace-platform
docker compose up -d postgres redis
docker compose ps  # both should show "running"
```

### Step 3 — Configure Environment

```bash
cp .env.example .env
```

Edit `.env` — minimum required:

```env
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/ace_platform
REDIS_URL=redis://localhost:6379/0
ANTHROPIC_API_KEY=sk-ant-...
JWT_SECRET_KEY=<generate below>
BILLING_ENABLED=false
ENVIRONMENT=development
DEBUG=false
```

Generate JWT secret:
```bash
python3 -c "import secrets; print(secrets.token_hex(32))"
```

### Step 4 — Run Migrations

```bash
source venv/bin/activate
alembic upgrade head
```

### Step 5 — Start Services (3 terminals)

**Terminal 1 — API:**
```bash
cd ~/ace-platform && source venv/bin/activate
uvicorn ace_platform.api.main:app --reload --host 0.0.0.0 --port 8000
```

**Terminal 2 — MCP Server:**
```bash
cd ~/ace-platform && source venv/bin/activate
python -m ace_platform.mcp.server
```

**Terminal 3 — Worker:**
```bash
cd ~/ace-platform && source venv/bin/activate
celery -A ace_platform.workers.celery_app worker -l info
```

Verify:
```bash
curl http://localhost:8000/health
```

### Step 6 — Create Account and API Key

```bash
# Register
curl -X POST http://localhost:8000/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email": "azeez@local.dev", "password": "changeme123", "name": "Azeez"}'

# Login — save the access_token
TOKEN=$(curl -s -X POST http://localhost:8000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "azeez@local.dev", "password": "changeme123"}' \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['access_token'])")

echo "Token: $TOKEN"

# Create API key — save the key value (shown only once)
curl -X POST http://localhost:8000/api-keys \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name": "claude-code", "scopes": ["playbooks:read", "playbooks:write", "outcomes:write", "evolution:write"]}'
```

### Step 7 — Connect via MCP

```bash
claude mcp add --transport http ace http://localhost:8000/mcp \
  --header "X-API-Key: <YOUR_API_KEY>"

# Verify
claude mcp list
```

### Step 8 — Seed Playbooks

```bash
export ACE_TOKEN="<your-access-token>"
bash ~/oss-contrib-setup/ace/playbooks/seed.sh
```

---

## Startup Script

To start ACE in one command after initial setup:

```bash
bash ~/ace-platform/start-ace.sh
```

The `setup.sh` creates this script automatically. It starts Docker, all three services,
and prints log file locations.

---

## Troubleshooting

**Postgres fails to start:**
```bash
docker compose logs postgres
sudo ss -tlnp | grep 5432  # check for port conflict
```

**alembic upgrade fails:**
```bash
docker compose ps  # verify postgres is healthy, not just running
sleep 5 && alembic upgrade head
```

**MCP connection refused:**
```bash
curl http://localhost:8000/health  # verify API is up
claude mcp list                    # verify ace is registered
# If missing: re-run the claude mcp add command
```

**Evolution not triggering:**
Evolution triggers automatically after 5+ unprocessed outcomes per playbook.
Manual trigger:
```bash
curl -X POST http://localhost:8000/evolutions \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"playbook_id": "<id>"}'
```

---

## Daily Usage

```
/find-issue           → ACE cncf-issue-finder playbook consulted automatically
/pre-pr               → ACE cncf-pr-quality playbook consulted automatically
/record-outcome merged → feeds playbook evolution
```

After ~2 weeks of daily use, playbooks will have evolved to reflect your personal
patterns — which repos respond fastest, which issue types you land most reliably, etc.
