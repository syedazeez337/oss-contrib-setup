#!/usr/bin/env bash
# install.sh — Install oss-contrib-setup into ~/.claude/
#
# What this does:
#   - Symlinks skills/, agents/, commands/, rules/ from this repo into ~/.claude/
#     (symlinks mean: git pull here → instantly updated everywhere)
#   - Copies CLAUDE.md and settings.json (so you can customize without affecting git)
#   - Creates ~/.claude/ if it doesn't exist
#   - Backs up any existing files before overwriting
#
# Usage:
#   bash install.sh           — install everything
#   bash install.sh --dry-run — show what would happen without doing it

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GLOBAL_DIR="$REPO_DIR/global"
CLAUDE_DIR="$HOME/.claude"
BACKUP_DIR="$HOME/.claude-backup-$(date +%Y%m%d-%H%M%S)"
DRY_RUN=false

# ─── Args ─────────────────────────────────────────────────────────────────────

for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=true ;;
        --help)
            echo "Usage: bash install.sh [--dry-run]"
            echo "  --dry-run   Show what would be installed without making changes"
            exit 0 ;;
    esac
done

# ─── Helpers ──────────────────────────────────────────────────────────────────

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

info()    { echo -e "${BLUE}[install]${NC} $*"; }
success() { echo -e "${GREEN}[install]${NC} $*"; }
warn()    { echo -e "${YELLOW}[install]${NC} $*"; }
dryrun()  { echo -e "${YELLOW}[dry-run]${NC} would: $*"; }

run() {
    if $DRY_RUN; then
        dryrun "$*"
    else
        eval "$@"
    fi
}

backup_if_exists() {
    local path="$1"
    if [[ -e "$path" ]] && [[ ! -L "$path" ]]; then
        run "mkdir -p '$BACKUP_DIR'"
        run "cp -r '$path' '$BACKUP_DIR/'"
        info "Backed up: $path → $BACKUP_DIR/"
    fi
}

symlink() {
    local src="$1"
    local dst="$2"
    backup_if_exists "$dst"
    run "ln -sfn '$src' '$dst'"
    if ! $DRY_RUN; then
        success "Symlinked: $dst → $src"
    fi
}

copy_if_missing() {
    local src="$1"
    local dst="$2"
    if [[ -f "$dst" ]]; then
        warn "Already exists (not overwriting): $dst"
        warn "  Compare with: diff $dst $src"
    else
        backup_if_exists "$dst"
        run "cp '$src' '$dst'"
        if ! $DRY_RUN; then
            success "Copied: $dst"
        fi
    fi
}

# ─── Pre-flight ───────────────────────────────────────────────────────────────

preflight() {
    if [[ ! -d "$GLOBAL_DIR" ]]; then
        echo "ERROR: global/ directory not found at $GLOBAL_DIR" >&2
        echo "Run from the repo root: bash install.sh" >&2
        exit 1
    fi

    info "Repo:        $REPO_DIR"
    info "Target:      $CLAUDE_DIR"
    info "Dry run:     $DRY_RUN"
    echo ""

    run "mkdir -p '$CLAUDE_DIR'"
}

# ─── Install ──────────────────────────────────────────────────────────────────

install_config_files() {
    info "Installing config files (copy — customize freely)..."
    copy_if_missing "$GLOBAL_DIR/CLAUDE.md"      "$CLAUDE_DIR/CLAUDE.md"
    copy_if_missing "$GLOBAL_DIR/settings.json"  "$CLAUDE_DIR/settings.json"
}

install_symlinked_dirs() {
    info "Installing skill directories (symlink — auto-updated on git pull)..."

    local dirs=("skills" "agents" "commands" "rules")
    for dir in "${dirs[@]}"; do
        if [[ -d "$GLOBAL_DIR/$dir" ]]; then
            symlink "$GLOBAL_DIR/$dir" "$CLAUDE_DIR/$dir"
        else
            warn "Skipping $dir — not found in $GLOBAL_DIR"
        fi
    done
}

# ─── Post-install ─────────────────────────────────────────────────────────────

post_install() {
    echo ""
    echo -e "${GREEN}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║         Installation Complete!                ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════╝${NC}"
    echo ""
    echo "Installed to: $CLAUDE_DIR"
    echo ""
    echo "What's active:"
    echo "  ~/.claude/CLAUDE.md        — global profile (edit to customise)"
    echo "  ~/.claude/settings.json    — permissions (edit to add project-specific rules)"
    echo "  ~/.claude/rules/           → $REPO_DIR/global/rules/ (symlink)"
    echo "  ~/.claude/skills/          → $REPO_DIR/global/skills/ (symlink)"
    echo "  ~/.claude/agents/          → $REPO_DIR/global/agents/ (symlink)"
    echo "  ~/.claude/commands/        → $REPO_DIR/global/commands/ (symlink)"
    echo ""
    echo "Available slash commands:"
    echo "  /find-issue [repo]         — scout for issues"
    echo "  /pre-pr                    — quality gate before PR"
    echo "  /review                    — go-reviewer agent on current diff"
    echo "  /commit [push]             — conventional commit + optional push"
    echo "  /record-outcome [type]     — feed outcomes to ACE"
    echo ""
    echo "Available agents:"
    echo "  go-reviewer                — code review specialist"
    echo "  issue-analyst              — triage and scope assessment"
    echo ""
    echo "Next step — set up ACE (self-improving playbooks):"
    echo "  bash $REPO_DIR/ace/setup.sh"
    echo ""
    echo "To update (pull latest skills/agents/commands):"
    echo "  cd $REPO_DIR && git pull"
    echo "  (symlinks mean updates are immediate — no re-install needed)"
    echo ""
    if [[ -d "$BACKUP_DIR" ]]; then
        warn "Previous files backed up to: $BACKUP_DIR"
    fi
}

# ─── Main ─────────────────────────────────────────────────────────────────────

main() {
    echo ""
    echo -e "${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║        oss-contrib-setup installer            ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"
    echo ""

    preflight
    install_config_files
    install_symlinked_dirs

    if ! $DRY_RUN; then
        post_install
    else
        echo ""
        echo "Dry run complete — no changes made."
        echo "Remove --dry-run to apply."
    fi
}

main "$@"
