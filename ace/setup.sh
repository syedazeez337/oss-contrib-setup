#!/usr/bin/env bash
# ace/setup.sh — ACE platform setup using Docker (no external API key required)
#
# Architecture:
#   Docker:   postgres + redis  (infrastructure)
#   Python:   API server + MCP server + Celery worker  (app layer)
#   MCP:      connects ACE to your AI assistant session
#   Evolution: done in-session via /evolve-playbooks — no external LLM needed
#
# Usage: bash ~/oss-contrib-setup/ace/setup.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ACE_DIR="$HOME/ace-platform"
ACE_EMAIL="azeez@local.dev"
ACE_PASSWORD="changeme123"
ACE_NAME="Azeez"
ACE_URL="http://localhost:8000"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
info()    { echo -e "${BLUE}[ACE]${NC} $*"; }
success() { echo -e "${GREEN}[ACE]${NC} $*"; }
warn()    { echo -e "${YELLOW}[ACE]${NC} $*"; }
die()     { echo -e "${RED}[ACE ERROR]${NC} $*" >&2; exit 1; }

# ─── Prerequisites ────────────────────────────────────────────────────────────

check_prereqs() {
    info "Checking prerequisites..."
    local missing=()
    command -v python3 >/dev/null 2>&1 || missing+=("python3")
    command -v docker  >/dev/null 2>&1 || missing+=("docker")
    command -v git     >/dev/null 2>&1 || missing+=("git")
    command -v curl    >/dev/null 2>&1 || missing+=("curl")

    python3 -c "import sys; assert sys.version_info >= (3,10)" 2>/dev/null \
        || die "Python 3.10+ required. Current: $(python3 --version)"
    docker info >/dev/null 2>&1 \
        || die "Docker daemon not running: sudo systemctl start docker"
    docker compose version >/dev/null 2>&1 \
        || die "Docker Compose v2 required."

    if [[ ${#missing[@]} -gt 0 ]]; then
        die "Missing: ${missing[*]}"
    fi
    success "Prerequisites OK (Docker $(docker --version | awk '{print $3}' | tr -d ','))"
}

# ─── Clone and install ────────────────────────────────────────────────────────

clone_and_install() {
    if [[ -d "$ACE_DIR" ]]; then
        warn "ace-platform already exists at $ACE_DIR — skipping clone"
    else
        info "Cloning ace-platform..."
        git clone https://github.com/DannyMac180/ace-platform.git "$ACE_DIR"
    fi

    info "Creating Python virtual environment..."
    cd "$ACE_DIR"
    python3 -m venv venv
    source venv/bin/activate

    info "Installing dependencies..."
    pip install --quiet --upgrade pip
    pip install --quiet -e ".[dev]"

    python3 -c "import ace_platform" 2>/dev/null \
        || die "Installation failed — check pip output above"
    success "ace-platform installed"
}

# ─── Docker services ──────────────────────────────────────────────────────────

start_docker() {
    info "Starting postgres and redis via Docker..."
    cd "$ACE_DIR"
    docker compose up -d postgres redis

    info "Waiting for postgres to be healthy..."
    local retries=20
    while [[ $retries -gt 0 ]]; do
        if docker compose exec -T postgres pg_isready -U postgres >/dev/null 2>&1; then
            success "Postgres ready"
            return 0
        fi
        sleep 2
        retries=$((retries - 1))
    done
    die "Postgres did not become healthy. Check: docker compose logs postgres"
}

# ─── Environment — no API key required ───────────────────────────────────────

configure_env() {
    info "Configuring environment (no API key required)..."
    cd "$ACE_DIR"

    [[ ! -f .env ]] && cp .env.example .env

    local jwt_secret
    jwt_secret=$(python3 -c "import secrets; print(secrets.token_hex(32))")

    python3 - <<PYEOF
import re

env_path = ".env"
with open(env_path) as f:
    content = f.read()

# Minimum required — no LLM API key needed for storage + MCP operations
defaults = {
    "DATABASE_URL": "postgresql://postgres:postgres@localhost:5432/ace_platform",
    "REDIS_URL": "redis://localhost:6379/0",
    "JWT_SECRET_KEY": "${jwt_secret}",
    "BILLING_ENABLED": "false",
    "ENVIRONMENT": "development",
    "DEBUG": "false",
}

for key, val in defaults.items():
    pattern = rf"^{key}=.*$"
    replacement = f"{key}={val}"
    if re.search(pattern, content, re.MULTILINE):
        content = re.sub(pattern, replacement, content, flags=re.MULTILINE)
    else:
        content += f"\n{replacement}"

with open(env_path, "w") as f:
    f.write(content)
PYEOF

    success "Environment configured"
    info "Note: no LLM API key configured — ACE stores playbooks and outcomes."
    info "      Evolution is handled in-session via /evolve-playbooks (no external calls)."
}

# ─── Migrations ───────────────────────────────────────────────────────────────

run_migrations() {
    info "Running database migrations..."
    cd "$ACE_DIR"
    source venv/bin/activate
    alembic upgrade head
    success "Migrations complete"
}

# ─── Start services ───────────────────────────────────────────────────────────

start_services() {
    info "Starting ACE services..."
    cd "$ACE_DIR"
    source venv/bin/activate

    pkill -f "uvicorn ace_platform" 2>/dev/null || true
    pkill -f "ace_platform.mcp.server" 2>/dev/null || true
    pkill -f "ace_platform.workers"   2>/dev/null || true
    sleep 1

    nohup uvicorn ace_platform.api.main:app \
        --host 0.0.0.0 --port 8000 > /tmp/ace-api.log 2>&1 &
    echo $! > /tmp/ace-api.pid

    nohup python -m ace_platform.mcp.server \
        > /tmp/ace-mcp.log 2>&1 &
    echo $! > /tmp/ace-mcp.pid

    nohup celery -A ace_platform.workers.celery_app worker -l info \
        > /tmp/ace-worker.log 2>&1 &
    echo $! > /tmp/ace-worker.pid

    info "Waiting for API to be ready..."
    local retries=20
    while [[ $retries -gt 0 ]]; do
        if curl -sf "$ACE_URL/health" >/dev/null 2>&1; then
            success "API ready at $ACE_URL"
            return 0
        fi
        sleep 2
        retries=$((retries - 1))
    done
    die "API did not start. Check /tmp/ace-api.log"
}

# ─── Account + API key ────────────────────────────────────────────────────────

create_account() {
    info "Creating account and API key..."

    # Register (idempotent — ignore if already exists)
    curl -sf -X POST "$ACE_URL/auth/register" \
        -H "Content-Type: application/json" \
        -d "{\"email\":\"$ACE_EMAIL\",\"password\":\"$ACE_PASSWORD\",\"name\":\"$ACE_NAME\"}" \
        >/dev/null 2>&1 || true

    # Login
    local login_resp
    login_resp=$(curl -sf -X POST "$ACE_URL/auth/login" \
        -H "Content-Type: application/json" \
        -d "{\"email\":\"$ACE_EMAIL\",\"password\":\"$ACE_PASSWORD\"}")

    local access_token
    access_token=$(echo "$login_resp" | python3 -c \
        "import sys,json; print(json.load(sys.stdin).get('access_token',''))")
    [[ -z "$access_token" ]] && die "Login failed: $login_resp"

    # Create API key
    local key_resp
    key_resp=$(curl -sf -X POST "$ACE_URL/api-keys" \
        -H "Authorization: Bearer $access_token" \
        -H "Content-Type: application/json" \
        -d '{"name":"local","scopes":["playbooks:read","playbooks:write","outcomes:write","evolution:write"]}')

    local api_key
    api_key=$(echo "$key_resp" | python3 -c \
        "import sys,json; print(json.load(sys.stdin).get('key',''))")
    [[ -z "$api_key" ]] && die "API key creation failed: $key_resp"

    # Save to credentials file
    cat > "$HOME/.ace-credentials" <<EOF
ACE_ACCESS_TOKEN=$access_token
ACE_API_KEY=$api_key
EOF
    chmod 600 "$HOME/.ace-credentials"

    export ACE_ACCESS_TOKEN="$access_token"
    export ACE_API_KEY="$api_key"

    success "Account ready"
    echo ""
    echo -e "  ${YELLOW}API key (save this):${NC} ${GREEN}${api_key}${NC}"
    echo ""
}

# ─── Connect MCP ──────────────────────────────────────────────────────────────

connect_mcp() {
    local key="${ACE_API_KEY:-}"
    [[ -z "$key" && -f "$HOME/.ace-credentials" ]] && {
        # shellcheck disable=SC1090
        source "$HOME/.ace-credentials"; key="${ACE_API_KEY:-}"; }

    if command -v claude >/dev/null 2>&1 && [[ -n "$key" ]]; then
        info "Connecting ACE via MCP..."
        claude mcp add --transport http ace "$ACE_URL/mcp" \
            --header "X-API-Key: $key" 2>/dev/null \
            && success "MCP connected — verify with: claude mcp list" \
            || warn "MCP connect failed — run manually:
    claude mcp add --transport http ace $ACE_URL/mcp --header \"X-API-Key: $key\""
    else
        warn "claude CLI not found or no key — connect manually when ready:
    source ~/.ace-credentials
    claude mcp add --transport http ace $ACE_URL/mcp --header \"X-API-Key: \$ACE_API_KEY\""
    fi
}

# ─── Seed playbooks ───────────────────────────────────────────────────────────

seed_playbooks() {
    info "Seeding playbooks into ACE..."
    local token="${ACE_ACCESS_TOKEN:-}"
    [[ -z "$token" && -f "$HOME/.ace-credentials" ]] && {
        # shellcheck disable=SC1090
        source "$HOME/.ace-credentials"; token="${ACE_ACCESS_TOKEN:-}"; }
    [[ -z "$token" ]] && { warn "No token — skip seeding"; return; }

    local playbooks_dir="$SCRIPT_DIR/../global/playbooks"
    for f in "$playbooks_dir"/*.md; do
        local name
        name=$(basename "$f" .md)
        local content
        content=$(cat "$f")
        local payload
        payload=$(python3 -c "
import json
content = open('$f').read()
print(json.dumps({'name': '$name', 'description': 'CNCF contribution playbook: $name', 'content': content}))
")
        local resp
        resp=$(curl -sf -X POST "$ACE_URL/playbooks" \
            -H "Authorization: Bearer $token" \
            -H "Content-Type: application/json" \
            -d "$payload" 2>&1)
        if echo "$resp" | python3 -c "import sys,json; json.load(sys.stdin).get('id')" >/dev/null 2>&1; then
            echo "  ✓ $name"
        else
            echo "  ✗ $name — $resp"
        fi
    done
    success "Playbooks seeded"
}

# ─── Startup script ───────────────────────────────────────────────────────────

write_startup_script() {
    cat > "$ACE_DIR/start-ace.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
ACE_DIR="$(dirname "$(realpath "$0")")"
cd "$ACE_DIR"
echo "[ACE] Starting Docker services..."
docker compose up -d postgres redis
until docker compose exec -T postgres pg_isready -U postgres >/dev/null 2>&1; do sleep 1; done
source venv/bin/activate
pkill -f "uvicorn ace_platform" 2>/dev/null || true
pkill -f "ace_platform.mcp.server" 2>/dev/null || true
pkill -f "ace_platform.workers" 2>/dev/null || true
sleep 1
nohup uvicorn ace_platform.api.main:app --host 0.0.0.0 --port 8000 > /tmp/ace-api.log 2>&1 &
nohup python -m ace_platform.mcp.server > /tmp/ace-mcp.log 2>&1 &
nohup celery -A ace_platform.workers.celery_app worker -l info > /tmp/ace-worker.log 2>&1 &
sleep 3
curl -sf http://localhost:8000/health >/dev/null && echo "[ACE] All services running" || echo "[ACE ERROR] API not responding — check /tmp/ace-api.log"
echo "[ACE] Logs: /tmp/ace-{api,mcp,worker}.log"
EOF
    chmod +x "$ACE_DIR/start-ace.sh"
    success "Startup script: ~/ace-platform/start-ace.sh"
}

# ─── Main ─────────────────────────────────────────────────────────────────────

main() {
    echo ""
    echo -e "${BLUE}╔═══════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║  ACE Platform — local setup (Docker, no API key)     ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════╝${NC}"
    echo ""

    check_prereqs
    clone_and_install
    start_docker
    configure_env
    run_migrations
    start_services
    create_account
    connect_mcp
    seed_playbooks
    write_startup_script

    echo ""
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║  Setup complete                                       ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "  Infrastructure:  Docker (postgres + redis)"
    echo "  API:             http://localhost:8000"
    echo "  MCP:             connected (claude mcp list to verify)"
    echo "  Evolution:       /evolve-playbooks  (in-session, no API key)"
    echo ""
    echo "  Start after reboot:  ~/ace-platform/start-ace.sh"
    echo "  Logs:  /tmp/ace-{api,mcp,worker}.log"
    echo ""
    echo "  Daily:"
    echo "    /find-issue           uses ACE cncf-issue-finder playbook"
    echo "    /pre-pr               uses ACE cncf-pr-quality playbook"
    echo "    /record-outcome       logs to ACE via MCP"
    echo "    /evolve-playbooks     reads outcomes, rewrites playbooks in-session"
    echo ""
}

main "$@"
