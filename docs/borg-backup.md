# Borg Backup (wrk-main)

## Overview
- Host: wrk-main
- Repository: /mnt/nas/Backups/wrk-main
- Schedule: daily at 02:00 via systemd timer

## Notes
- The systemd unit/timer files are not tracked in this repo.
- Ensure NAS mounts are available before the timer runs.
- Package requirement: borg (included in core packages).
