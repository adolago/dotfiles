#!/bin/bash
# Mount NAS drives
# Usage: mount-nas.sh [status|mount|umount]

set -e

ACTION="${1:-status}"
NAS_CONFIG="$HOME/.config/nas-mounts.conf"

# Default mount points if config doesn't exist
if [[ ! -f "$NAS_CONFIG" ]]; then
    cat > "$NAS_CONFIG" << 'CONF'
# NAS Mount Configuration
# Format: <server>:<share> <local_mount> <type> <options>

# Example NFS mounts:
# nas-server:/volume1/media    /mnt/nas/media    nfs    defaults    0 0
# nas-server:/volume1/backups  /mnt/nas/backups  nfs    defaults    0 0

# Example SMB/CIFS mounts:
# //nas-server/shared    /mnt/nas/shared    cifs    credentials=/home/artur/.config/nas-credentials,uid=artur,gid=artur    0 0

# Example for local testing (remove these):
nas-server:/volume1/media    /mnt/nas/media    nfs    defaults    0 0
nas-server:/volume1/backups  /mnt/nas/backups  nfs    defaults    0 0
CONF
    echo "Created template NAS config at $NAS_CONFIG"
    echo "Please edit it with your actual NAS settings"
    exit 1
fi

case "$ACTION" in
    status)
        echo "NAS Mount Status:"
        echo "=================="
        while IFS= read -r line; do
            # Skip comments and empty lines
            [[ "$line" =~ ^#.*$ ]] && continue
            [[ -z "$line" ]] && continue

            # Parse mount line
            server_share=$(echo "$line" | awk '{print $1}')
            mount_point=$(echo "$line" | awk '{print $2}')

            if [[ -n "$mount_point" ]]; then
                if mountpoint -q "$mount_point" 2>/dev/null; then
                    echo "[OK] $server_share -> $mount_point (mounted)"
                else
                    echo "[NO] $server_share -> $mount_point (not mounted)"
                fi
            fi
        done < "$NAS_CONFIG"
        ;;

    mount)
        echo "Mounting NAS shares..."
        while IFS= read -r line; do
            [[ "$line" =~ ^#.*$ ]] && continue
            [[ -z "$line" ]] && continue

            mount_point=$(echo "$line" | awk '{print $2}')
            fs_type=$(echo "$line" | awk '{print $3}')

            if [[ -n "$mount_point" ]]; then
                # Create mount point if it doesn't exist
                sudo mkdir -p "$mount_point"

                if mountpoint -q "$mount_point" 2>/dev/null; then
                    echo "Already mounted: $mount_point"
                else
                    echo "Mounting $mount_point..."
                    # Extract just the mount options part
                    options=$(echo "$line" | sed 's/^[^ ]* [^ ]* [^ ]* //' | awk '{for(i=3;i<NF;i++) printf $i " "; print $NF}')

                    if [[ "$fs_type" == "cifs" ]]; then
                        sudo mount -t cifs "$server_share" "$mount_point" -o "$options"
                    else
                        sudo mount "$mount_point"
                    fi
                fi
            fi
        done < "$NAS_CONFIG"

        # Create symlinks in home directory
        echo "Creating symlinks in ~/NAS/..."
        mkdir -p "$HOME/NAS"
        while IFS= read -r line; do
            [[ "$line" =~ ^#.*$ ]] && continue
            [[ -z "$line" ]] && continue

            server_share=$(echo "$line" | awk '{print $1}')
            mount_point=$(echo "$line" | awk '{print $2}')

            if [[ -n "$mount_point" && -d "$mount_point" ]]; then
                link_name=$(basename "$mount_point")
                ln -sfn "$mount_point" "$HOME/NAS/$link_name" 2>/dev/null || true
            fi
        done < "$NAS_CONFIG"
        ;;

    umount)
        echo "Unmounting NAS shares..."
        while IFS= read -r line; do
            [[ "$line" =~ ^#.*$ ]] && continue
            [[ -z "$line" ]] && continue

            mount_point=$(echo "$line" | awk '{print $2}')

            if [[ -n "$mount_point" ]] && mountpoint -q "$mount_point" 2>/dev/null; then
                echo "Unmounting $mount_point..."
                sudo umount "$mount_point"
            fi
        done < "$NAS_CONFIG"
        ;;

    *)
        echo "Usage: $0 {status|mount|umount}"
        exit 1
        ;;
esac
