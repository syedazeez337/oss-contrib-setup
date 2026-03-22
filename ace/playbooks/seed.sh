#!/usr/bin/env bash
# ace/playbooks/seed.sh — Seed the 4 core CNCF playbooks into ACE
# Usage: export ACE_TOKEN=<access_token> && bash seed.sh
set -euo pipefail

ACE_URL="${ACE_URL:-http://localhost:8000}"
TOKEN="${ACE_TOKEN:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -z "$TOKEN" ]]; then
    # Try loading from credentials file
    if [[ -f "$HOME/.ace-credentials" ]]; then
        # shellcheck disable=SC1090
        source "$HOME/.ace-credentials"
        TOKEN="${ACE_ACCESS_TOKEN:-}"
    fi
fi

if [[ -z "$TOKEN" ]]; then
    echo "ERROR: ACE_TOKEN not set. Export your access token first:"
    echo "  export ACE_TOKEN=<your-access-token>"
    exit 1
fi

create_playbook() {
    local name="$1"
    local description="$2"
    local content_file="$3"

    local content
    content=$(cat "$content_file")

    # Escape the content as JSON string
    local payload
    payload=$(python3 -c "
import json, sys
content = open('$content_file').read()
payload = {
    'name': '$name',
    'description': '$description',
    'content': content
}
print(json.dumps(payload))
")

    local response
    response=$(curl -sf -X POST "$ACE_URL/playbooks" \
        -H "Authorization: Bearer $TOKEN" \
        -H "Content-Type: application/json" \
        -d "$payload" 2>&1)

    if echo "$response" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('id',''))" 2>/dev/null | grep -q .; then
        local id
        id=$(echo "$response" | python3 -c "import sys,json; print(json.load(sys.stdin).get('id',''))")
        echo "  ✓ $name (id: $id)"
    else
        echo "  ✗ $name — $response"
    fi
}

echo ""
echo "Seeding ACE playbooks..."
echo ""

create_playbook \
    "cncf-issue-finder" \
    "Strategy for finding high-probability mergeable issues in Go/CNCF projects" \
    "$SCRIPT_DIR/data/cncf-issue-finder.md"

create_playbook \
    "cncf-pr-quality" \
    "How to write PRs that get merged in Cilium, CoreDNS, Strimzi, and similar CNCF projects" \
    "$SCRIPT_DIR/data/cncf-pr-quality.md"

create_playbook \
    "maintainer-response" \
    "How to handle PR review feedback from CNCF maintainers and keep PRs moving toward merge" \
    "$SCRIPT_DIR/data/maintainer-response.md"

create_playbook \
    "pr-triage" \
    "How to quickly assess whether an issue is worth pursuing before spending time on it" \
    "$SCRIPT_DIR/data/pr-triage.md"

echo ""
echo "Verifying..."
count=$(curl -sf "$ACE_URL/playbooks" \
    -H "Authorization: Bearer $TOKEN" \
    | python3 -c "import sys,json; d=json.load(sys.stdin); print(len(d.get('items',d) if isinstance(d,dict) else d))")
echo "  Playbooks in ACE: $count"
echo ""
echo "Seed complete. Evolution triggers automatically after 5 outcomes per playbook."
echo "Record outcomes with: /record-outcome [merged|closed|stalled]"
