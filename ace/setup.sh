#!/usr/bin/env bash
# ace/setup.sh — Local playbook system setup (no external services needed)
# This is handled automatically by install.sh — run that instead.
# This script exists for standalone use only.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
CLAUDE_DIR="$HOME/.claude"

GREEN='\033[0;32m'; BLUE='\033[0;34m'; NC='\033[0m'
info()    { echo -e "${BLUE}[setup]${NC} $*"; }
success() { echo -e "${GREEN}[setup]${NC} $*"; }

info "Setting up local playbook system..."

# Create directories
mkdir -p "$CLAUDE_DIR/playbooks"
mkdir -p "$CLAUDE_DIR/outcomes"

# Seed playbooks (skip if already exist)
for f in "$REPO_DIR/global/playbooks/"*.md; do
    dst="$CLAUDE_DIR/playbooks/$(basename "$f")"
    if [[ -f "$dst" ]]; then
        echo "  skipping (exists): $(basename "$f")"
    else
        cp "$f" "$dst"
        success "Seeded: $(basename "$f")"
    fi
done

# Create empty outcomes log if missing
if [[ ! -f "$CLAUDE_DIR/outcomes/outcomes.log" ]]; then
    touch "$CLAUDE_DIR/outcomes/outcomes.log"
    success "Created: ~/.claude/outcomes/outcomes.log"
fi

echo ""
success "Done. Playbooks at ~/.claude/playbooks/"
echo ""
echo "Commands:"
echo "  /record-outcome [merged|closed|stalled]   — log a PR outcome"
echo "  /evolve-playbooks                          — improve playbooks from outcomes"
