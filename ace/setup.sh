#!/usr/bin/env bash
# ace/setup.sh — Automated ACE Platform setup for Linux
# Usage: bash ~/oss-contrib-setup/ace/setup.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ACE_DIR="$HOME/ace-platform"
ACE_EMAIL="azeez@local.dev"
ACE_PASSWORD="changeme123"
ACE_NAME="Azeez"
ACE_URL="http://localhost:8000"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

    if [[ ${#missing[@]} -gt 0 ]]; then
        die "Missing tools: ${missing[*]}. Install them first (see ace/README.md)."
    fi

    # Check Docker daemon is running
    docker info >/dev/null 2>&1 || die "Docker daemon is not running. Start it: sudo systemctl start docker"

    # Check docker compose v2
    docker compose version >/dev/null 2>&1 || die "Docker Compose v2 required."

    success "Prerequisites OK"
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
        || die "Installation verification failed — check pip output above"

    success "ace-platform installed"
}

# ─── Docker services ──────────────────────────────────────────────────────────

start_docker() {
    info "Starting postgres and redis..."
    cd "$ACE_DIR"
    docker compose up -d postgres redis

    info "Waiting for postgres to be healthy..."
    local retries=15
    while [[ $retries -gt 0 ]]; do
        if docker compose exec -T postgres pg_isready -U postgres >/dev/null 2>&1; then
            success "Postgres is ready"
            return 0
        fi
        sleep 2
        retries=$((retries - 1))
    done
    die "Postgres did not become healthy in time. Run: docker compose logs postgres"
}

# ─── Environment config ───────────────────────────────────────────────────────

configure_env() {
    info "Configuring environment..."
    cd "$ACE_DIR"

    if [[ ! -f .env ]]; then
        cp .env.example .env
    fi

    local jwt_secret
    jwt_secret=$(python3 -c "import secrets; print(secrets.token_hex(32))")

    # Write minimum required config (preserves existing values if file already has them)
    python3 - <<PYEOF
import re, os

env_path = ".env"
with open(env_path) as f:
    content = f.read()

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

print("Environment configured")
PYEOF

    # Check for API key
    if grep -q "^ANTHROPIC_API_KEY=sk-ant-" .env 2>/dev/null; then
        success "ANTHROPIC_API_KEY already set"
    elif grep -q "^OPENAI_API_KEY=sk-" .env 2>/dev/null; then
        success "OPENAI_API_KEY already set"
    else
        warn "No LLM API key found in .env"
        echo ""
        echo "ACE needs an API key for playbook evolution (LLM calls)."
        echo "Add one of these to $ACE_DIR/.env:"
        echo "  ANTHROPIC_API_KEY=sk-ant-..."
        echo "  OPENAI_API_KEY=sk-..."
        echo ""
        read -rp "Enter your API key (Anthropic or OpenAI, or press Enter to skip): " api_key
        if [[ -n "$api_key" ]]; then
            echo "ANTHROPIC_API_KEY=$api_key" >> .env
            success "API key saved"
        else
            warn "Skipped — add it manually to $ACE_DIR/.env before using evolution"
        fi
    fi
}

# ─── Database migrations ──────────────────────────────────────────────────────

run_migrations() {
    info "Running database migrations..."
    cd "$ACE_DIR"
    source venv/bin/activate
    alembic upgrade head
    success "Migrations complete"
}

# ─── Start services ───────────────────────────────────────────────────────────

start_services() {
    info "Starting ACE services in background..."
    cd "$ACE_DIR"
    source venv/bin/activate

    # Kill any previous instances
    pkill -f "uvicorn ace_platform" 2>/dev/null || true
    pkill -f "ace_platform.mcp.server" 2>/dev/null || true
    pkill -f "ace_platform.workers" 2>/dev/null || true
    sleep 1

    nohup uvicorn ace_platform.api.main:app \
        --host 0.0.0.0 --port 8000 \
        > /tmp/ace-api.log 2>&1 &
    echo $! > /tmp/ace-api.pid
    info "API server started (PID $!)"

    nohup python -m ace_platform.mcp.server \
        > /tmp/ace-mcp.log 2>&1 &
    echo $! > /tmp/ace-mcp.pid
    info "MCP server started (PID $!)"

    nohup celery -A ace_platform.workers.celery_app worker -l info \
        > /tmp/ace-worker.log 2>&1 &
    echo $! > /tmp/ace-worker.pid
    info "Worker started (PID $!)"

    # Wait for API to be ready
    local retries=20
    while [[ $retries -gt 0 ]]; do
        if curl -sf "$ACE_URL/health" >/dev/null 2>&1; then
            success "API is ready at $ACE_URL"
            return 0
        fi
        sleep 2
        retries=$((retries - 1))
    done
    die "API did not become ready. Check /tmp/ace-api.log"
}

# ─── Create account and API key ───────────────────────────────────────────────

create_account() {
    info "Creating ACE account..."

    # Register (ignore error if already exists)
    curl -sf -X POST "$ACE_URL/auth/register" \
        -H "Content-Type: application/json" \
        -d "{\"email\":\"$ACE_EMAIL\",\"password\":\"$ACE_PASSWORD\",\"name\":\"$ACE_NAME\"}" \
        >/dev/null 2>&1 || true

    # Login
    local login_response
    login_response=$(curl -sf -X POST "$ACE_URL/auth/login" \
        -H "Content-Type: application/json" \
        -d "{\"email\":\"$ACE_EMAIL\",\"password\":\"$ACE_PASSWORD\"}")

    local access_token
    access_token=$(echo "$login_response" \
        | python3 -c "import sys,json; print(json.load(sys.stdin).get('access_token',''))")

    if [[ -z "$access_token" ]]; then
        die "Login failed. Response: $login_response"
    fi

    success "Account created / logged in"

    # Create API key
    info "Creating API key for MCP access..."
    local key_response
    key_response=$(curl -sf -X POST "$ACE_URL/api-keys" \
        -H "Authorization: Bearer $access_token" \
        -H "Content-Type: application/json" \
        -d '{"name":"claude-code","scopes":["playbooks:read","playbooks:write","outcomes:write","evolution:write"]}')

    local api_key
    api_key=$(echo "$key_response" \
        | python3 -c "import sys,json; print(json.load(sys.stdin).get('key',''))")

    if [[ -z "$api_key" ]]; then
        die "Failed to create API key. Response: $key_response"
    fi

    # Save credentials for seed script
    cat > "$HOME/.ace-credentials" <<EOF
ACE_ACCESS_TOKEN=$access_token
ACE_API_KEY=$api_key
EOF
    chmod 600 "$HOME/.ace-credentials"

    success "API key created and saved to ~/.ace-credentials"
    echo ""
    echo -e "${YELLOW}IMPORTANT — Save this API key (shown only once):${NC}"
    echo -e "  ${GREEN}$api_key${NC}"
    echo ""

    # Export for use in this script session
    export ACE_ACCESS_TOKEN="$access_token"
    export ACE_API_KEY="$api_key"
}

# ─── Connect via MCP ──────────────────────────────────────────────────────────

connect_mcp() {
    if ! command -v claude >/dev/null 2>&1; then
        warn "claude CLI not found — skipping MCP connection"
        warn "Connect manually: claude mcp add --transport http ace $ACE_URL/mcp --header \"X-API-Key: \$ACE_API_KEY\""
        return
    fi

    info "Connecting ACE via MCP..."
    # Load API key if set
    local key="${ACE_API_KEY:-}"
    if [[ -z "$key" ]] && [[ -f "$HOME/.ace-credentials" ]]; then
        # shellcheck disable=SC1090
        source "$HOME/.ace-credentials"
        key="${ACE_API_KEY:-}"
    fi

    if [[ -z "$key" ]]; then
        warn "No API key found — connect manually"
        return
    fi

    claude mcp add --transport http ace "$ACE_URL/mcp" \
        --header "X-API-Key: $key" 2>/dev/null || \
    warn "MCP add failed — run the command manually in an active session"

    success "ACE connected via MCP"
}

# ─── Seed playbooks ───────────────────────────────────────────────────────────

seed_playbooks() {
    info "Seeding core playbooks..."

    local token="${ACE_ACCESS_TOKEN:-}"
    if [[ -z "$token" ]] && [[ -f "$HOME/.ace-credentials" ]]; then
        # shellcheck disable=SC1090
        source "$HOME/.ace-credentials"
        token="${ACE_ACCESS_TOKEN:-}"
    fi

    if [[ -z "$token" ]]; then
        warn "No access token — skipping playbook seed"
        warn "Run manually: export ACE_TOKEN=<token> && bash ~/oss-contrib-setup/ace/playbooks/seed.sh"
        return
    fi

    export ACE_TOKEN="$token"
    bash "$SCRIPT_DIR/playbooks/seed.sh"
}

# ─── Write startup script ─────────────────────────────────────────────────────

write_startup_script() {
    cat > "$HOME/ace-platform/start-ace.sh" <<'STARTEOF'
#!/usr/bin/env bash
# start-ace.sh — Start all ACE services
set -euo pipefail
ACE_DIR="$(dirname "$(realpath "$0")")"
cd "$ACE_DIR"

echo "[ACE] Starting infrastructure..."
docker compose up -d postgres redis

echo "[ACE] Waiting for postgres..."
until docker compose exec -T postgres pg_isready -U postgres >/dev/null 2>&1; do
    sleep 1
done

source venv/bin/activate

pkill -f "uvicorn ace_platform" 2>/dev/null || true
pkill -f "ace_platform.mcp.server" 2>/dev/null || true
pkill -f "ace_platform.workers" 2>/dev/null || true
sleep 1

nohup uvicorn ace_platform.api.main:app --host 0.0.0.0 --port 8000 > /tmp/ace-api.log 2>&1 &
echo "[ACE] API server PID: $!"
nohup python -m ace_platform.mcp.server > /tmp/ace-mcp.log 2>&1 &
echo "[ACE] MCP server PID: $!"
nohup celery -A ace_platform.workers.celery_app worker -l info > /tmp/ace-worker.log 2>&1 &
echo "[ACE] Worker PID: $!"

sleep 3
if curl -sf http://localhost:8000/health >/dev/null 2>&1; then
    echo "[ACE] All services running. Logs: /tmp/ace-{api,mcp,worker}.log"
else
    echo "[ACE ERROR] API not responding. Check /tmp/ace-api.log"
    exit 1
fi
STARTEOF
    chmod +x "$HOME/ace-platform/start-ace.sh"
    success "Startup script written to ~/ace-platform/start-ace.sh"
}

# ─── Main ─────────────────────────────────────────────────────────────────────

main() {
    echo ""
    echo -e "${BLUE}╔══════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║          ACE Platform Setup                  ║${NC}"
    echo -e "${BLUE}║     Self-Improving Playbook System           ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════╝${NC}"
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
    echo -e "${GREEN}╔══════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║         Setup Complete!                      ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════╝${NC}"
    echo ""
    echo "ACE is running at: http://localhost:8000"
    echo "MCP connected:     claude mcp list → look for 'ace'"
    echo ""
    echo "Start ACE after reboot: ~/ace-platform/start-ace.sh"
    echo "Logs:"
    echo "  API:    /tmp/ace-api.log"
    echo "  MCP:    /tmp/ace-mcp.log"
    echo "  Worker: /tmp/ace-worker.log"
    echo ""
    echo "Daily commands:"
    echo "  /find-issue       — find issues (uses ACE cncf-issue-finder playbook)"
    echo "  /pre-pr           — quality gate (uses ACE cncf-pr-quality playbook)"
    echo "  /record-outcome   — feed outcomes back (triggers evolution after 5)"
    echo ""
}

main "$@"
