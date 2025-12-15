#!/bin/bash
# Dotfiles installation script
# Detects machine type and symlinks appropriate configs

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config"
BIN_DIR="$HOME/bin"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Detect machine type
detect_machine_type() {
    # Check for battery - laptops have one
    if [ -d /sys/class/power_supply/BAT0 ] || [ -d /sys/class/power_supply/BAT1 ]; then
        echo "laptop"
    else
        echo "desktop"
    fi
}

# Backup existing config if it exists and isn't a symlink
backup_if_exists() {
    local target="$1"
    if [ -e "$target" ] && [ ! -L "$target" ]; then
        local backup="${target}.backup.$(date +%Y%m%d_%H%M%S)"
        warn "Backing up existing $target to $backup"
        mv "$target" "$backup"
    elif [ -L "$target" ]; then
        rm "$target"
    fi
}

# Create symlink
link_config() {
    local src="$1"
    local dest="$2"
    
    backup_if_exists "$dest"
    
    # Create parent directory if needed
    mkdir -p "$(dirname "$dest")"
    
    ln -sf "$src" "$dest"
    info "Linked $src -> $dest"
}

# Main installation
main() {
    local machine_type
    machine_type=$(detect_machine_type)
    
    info "Detected machine type: $machine_type"
    info "Installing dotfiles from $DOTFILES_DIR"
    
    # Create directories
    mkdir -p "$CONFIG_DIR/hypr"
    mkdir -p "$CONFIG_DIR/waybar"
    mkdir -p "$CONFIG_DIR/mako"
    mkdir -p "$CONFIG_DIR/wofi"
    mkdir -p "$BIN_DIR"
    
    # Link hyprland configs
    link_config "$DOTFILES_DIR/config/hypr/hyprland.conf" "$CONFIG_DIR/hypr/hyprland.conf"
    link_config "$DOTFILES_DIR/config/hypr/hypridle.conf" "$CONFIG_DIR/hypr/hypridle.conf"
    link_config "$DOTFILES_DIR/config/hypr/hyprlock.conf" "$CONFIG_DIR/hypr/hyprlock.conf"
    link_config "$DOTFILES_DIR/config/hypr/reload-hyprland.sh" "$CONFIG_DIR/hypr/reload-hyprland.sh"
    chmod +x "$CONFIG_DIR/hypr/reload-hyprland.sh"
    
    # Link host-specific config
    if [ "$machine_type" = "laptop" ]; then
        link_config "$DOTFILES_DIR/config/hypr/hosts/laptop.conf" "$CONFIG_DIR/hypr/host.conf"
        info "Using laptop configuration (built-in display, touchpad, battery)"
    else
        link_config "$DOTFILES_DIR/config/hypr/hosts/desktop.conf" "$CONFIG_DIR/hypr/host.conf"
        info "Using desktop configuration (external monitor, HiDPI)"
    fi
    
    # Link waybar
    link_config "$DOTFILES_DIR/config/waybar/config.jsonc" "$CONFIG_DIR/waybar/config.jsonc"
    link_config "$DOTFILES_DIR/config/waybar/style.css" "$CONFIG_DIR/waybar/style.css"
    
    # Link mako
    link_config "$DOTFILES_DIR/config/mako/config" "$CONFIG_DIR/mako/config"
    
    # Link wofi
    link_config "$DOTFILES_DIR/config/wofi/config" "$CONFIG_DIR/wofi/config"
    link_config "$DOTFILES_DIR/config/wofi/style.css" "$CONFIG_DIR/wofi/style.css"
    
    # Link scripts
    link_config "$DOTFILES_DIR/bin/cpu_stats.sh" "$BIN_DIR/cpu_stats.sh"
    link_config "$DOTFILES_DIR/bin/ram_stats.sh" "$BIN_DIR/ram_stats.sh"
    chmod +x "$BIN_DIR/cpu_stats.sh"
    chmod +x "$BIN_DIR/ram_stats.sh"
    
    info ""
    info "Installation complete!"
    info ""
    info "Post-install steps:"
    info "  1. Create ~/.config/hypr/hyprpaper.conf with your wallpaper"
    info "  2. Create ~/.config/current-theme/ with hyprlock.conf and background"
    info "  3. Adjust monitor settings in ~/.config/hypr/host.conf if needed"
    info "  4. Run: hyprctl reload"
    info ""
    
    # Show current host.conf monitor line for verification
    if [ -f "$CONFIG_DIR/hypr/host.conf" ]; then
        info "Current monitor config:"
        grep "^monitor" "$CONFIG_DIR/hypr/host.conf" 2>/dev/null || true
    fi
}

# Run with --uninstall to remove symlinks
if [ "$1" = "--uninstall" ]; then
    info "Removing symlinks..."
    rm -f "$CONFIG_DIR/hypr/hyprland.conf"
    rm -f "$CONFIG_DIR/hypr/hypridle.conf"
    rm -f "$CONFIG_DIR/hypr/hyprlock.conf"
    rm -f "$CONFIG_DIR/hypr/reload-hyprland.sh"
    rm -f "$CONFIG_DIR/hypr/host.conf"
    rm -f "$CONFIG_DIR/waybar/config.jsonc"
    rm -f "$CONFIG_DIR/waybar/style.css"
    rm -f "$CONFIG_DIR/mako/config"
    rm -f "$CONFIG_DIR/wofi/config"
    rm -f "$CONFIG_DIR/wofi/style.css"
    rm -f "$BIN_DIR/cpu_stats.sh"
    rm -f "$BIN_DIR/ram_stats.sh"
    info "Uninstall complete"
    exit 0
fi

main "$@"
