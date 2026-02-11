#!/bin/bash
# Setup script for organized home directory
# Run this after organizing to configure everything

set -e

echo "Setting up organized home directory..."
echo "===================================="

# Add ~/bin to PATH if not already there
SHELL_RC=""
if [[ -f "$HOME/.bashrc" ]]; then
    SHELL_RC="$HOME/.bashrc"
elif [[ -f "$HOME/.zshrc" ]]; then
    SHELL_RC="$HOME/.zshrc"
fi

if [[ -n "$SHELL_RC" ]]; then
    if ! grep -q 'export PATH="$HOME/bin:$PATH"' "$SHELL_RC"; then
        echo 'export PATH="$HOME/bin:$PATH"' >> "$SHELL_RC"
        echo "Added ~/bin to PATH in $SHELL_RC"
    fi
fi

# Set up environment variables
cat >> "$HOME/.profile" << 'EOF2'

# Organized home directory environment variables
export PROJECTS_HOME="$HOME/Projects"
export DOCUMENTS_HOME="$HOME/Documents"
export CLOUD_HOME="$HOME/Cloud"
export NAS_HOME="$HOME/NAS"
EOF2

echo "Added environment variables to ~/.profile"

# Create NAS configuration if it doesn't exist
if [[ ! -f "$HOME/.config/nas-mounts.conf" ]]; then
    echo "Creating NAS mount configuration template..."
    ~/bin/mount-nas.sh status
fi

# Enable and start waybar CPU power service
echo "Setting up waybar CPU power monitoring..."
systemctl --user daemon-reload
systemctl --user enable waybar-cpu-power.service
systemctl --user start waybar-cpu-power.service

# Test CPU stats
echo "Testing CPU stats..."
~/bin/cpu_stats.sh

echo ""
echo "Setup complete! Next steps:"
echo "========================="
echo "1. Edit ~/.config/nas-mounts.conf with your actual NAS settings"
echo "2. Run: ~/bin/mount-nas.sh mount"
echo "3. Set up cloud storage clients (see ~/HOME_ORGANIZATION.md)"
echo "4. Add backup cron job: crontab -e"
echo "   Example: 0 2 * * * ~/bin/backup-to-nas.sh incremental"
echo ""
echo "Directory structure created:"
ls -la "$HOME"/ | grep -E "(Projects|Media|Documents|Cloud|NAS|Temp|bin)"
