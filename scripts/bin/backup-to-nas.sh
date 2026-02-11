#!/bin/bash
# Backup important files to NAS
# Usage: backup-to-nas.sh [full|incremental]

set -e

BACKUP_TYPE="${1:-incremental}"
NAS_BACKUP_PATH="$HOME/NAS/Backups/$(hostname)-$(whoami)"
LOG_FILE="$HOME/.local/share/backup.log"

# Create necessary directories
mkdir -p "$NAS_BACKUP_PATH" "$(dirname "$LOG_FILE")"

# Log function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

# Check if NAS is mounted
if [[ ! -d "$NAS_BACKUP_PATH" ]] || ! mountpoint -q "$HOME/NAS/Backups" 2>/dev/null; then
    log "ERROR: NAS backup directory not accessible. Is it mounted?"
    exit 1
fi

log "Starting $BACKUP_TYPE backup to NAS..."

# Define backup sources
BACKUP_SOURCES=(
    "$HOME/Documents"
    "$HOME/Projects"
    "$HOME/.config"
    "$HOME/.ssh"
    "$HOME/.local/share"
)

# Create backup directory with timestamp
BACKUP_DIR="$NAS_BACKUP_PATH/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Perform backup
for source in "${BACKUP_SOURCES[@]}"; do
    if [[ -d "$source" ]]; then
        src_name=$(basename "$source")
        log "Backing up $source..."

        if [[ "$BACKUP_TYPE" == "incremental" ]]; then
            # Use rsync for incremental backups
            rsync -avh --delete --exclude='*.tmp' --exclude='.cache' \
                "$source/" "$BACKUP_DIR/$src_name/" 2>&1 | tee -a "$LOG_FILE"
        else
            # Full backup - create tar.gz
            tar -czf "$BACKUP_DIR/${src_name}.tar.gz" -C "$(dirname "$source")" "$src_name" 2>&1 | tee -a "$LOG_FILE"
        fi
    else
        log "Warning: $source does not exist, skipping"
    fi
done

# Create a latest symlink
ln -sfn "$(basename "$BACKUP_DIR")" "$NAS_BACKUP_PATH/latest"

log "Backup completed successfully to $BACKUP_DIR"
echo "Backup log: $LOG_FILE"
