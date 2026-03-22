#!/usr/bin/env bash
# uninstall.sh — Remove oss-contrib-setup from ~/.claude/
set -euo pipefail

CLAUDE_DIR="$HOME/.claude"
BACKUP_DIR="$HOME/.claude-uninstall-backup-$(date +%Y%m%d-%H%M%S)"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
warn()    { echo -e "${YELLOW}[uninstall]${NC} $*"; }
success() { echo -e "${GREEN}[uninstall]${NC} $*"; }

echo ""
echo "This will remove symlinks and copied files installed by install.sh"
echo "from $CLAUDE_DIR"
echo ""
read -rp "Continue? (yes/no): " confirm
[[ "$confirm" == "yes" ]] || { echo "Aborted."; exit 0; }

mkdir -p "$BACKUP_DIR"

# Remove symlinks
for dir in skills agents commands rules; do
    if [[ -L "$CLAUDE_DIR/$dir" ]]; then
        rm "$CLAUDE_DIR/$dir"
        success "Removed symlink: $CLAUDE_DIR/$dir"
    fi
done

# Backup and remove copied files
for file in CLAUDE.md settings.json; do
    if [[ -f "$CLAUDE_DIR/$file" ]]; then
        cp "$CLAUDE_DIR/$file" "$BACKUP_DIR/$file"
        rm "$CLAUDE_DIR/$file"
        success "Removed: $CLAUDE_DIR/$file (backed up to $BACKUP_DIR)"
    fi
done

echo ""
success "Uninstall complete. Backup saved to $BACKUP_DIR"
