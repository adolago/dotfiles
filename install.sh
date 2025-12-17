#!/bin/bash
# Dotfiles installation script
# Detects machine type and symlinks appropriate configs

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config"
BIN_DIR="$HOME/bin"
PACKAGES_DIR="$DOTFILES_DIR/packages"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Show usage
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --packages     Install packages from package lists"
    echo "  --packages-only  Only install packages, skip config symlinks"
    echo "  --uninstall    Remove config symlinks"
    echo "  --diff         Show package differences vs package lists"
    echo "  -h, --help     Show this help"
    echo ""
    echo "Without options, only symlinks configs (no package installation)"
}

# Detect machine type
detect_machine_type() {
    # Check for battery - laptops have one
    if [ -d /sys/class/power_supply/BAT0 ] || [ -d /sys/class/power_supply/BAT1 ]; then
        echo "laptop"
    else
        echo "desktop"
    fi
}

# Parse package list file, removing comments and empty lines
parse_package_list() {
    local file="$1"
    if [ -f "$file" ]; then
        # Remove inline comments, full-line comments, and empty lines
        sed 's/#.*//' "$file" | grep -v '^[[:space:]]*$' | awk '{print $1}' | tr '\n' ' '
    fi
}

# Install packages from package lists
install_packages() {
    local machine_type="$1"

    if [ ! -d "$PACKAGES_DIR" ]; then
        warn "No packages directory found at $PACKAGES_DIR"
        return 1
    fi

    info "Installing packages for $machine_type..."

    # Core packages (all machines)
    if [ -f "$PACKAGES_DIR/core.txt" ]; then
        info "Installing core packages..."
        local core_pkgs
        core_pkgs=$(parse_package_list "$PACKAGES_DIR/core.txt")
        if [ -n "$core_pkgs" ]; then
            # shellcheck disable=SC2086
            sudo pacman -S --needed --noconfirm $core_pkgs || warn "Some core packages failed to install"
        fi
    fi

    # Machine-specific packages
    local machine_file="$PACKAGES_DIR/${machine_type}.txt"
    if [ -f "$machine_file" ]; then
        info "Installing $machine_type-specific packages..."
        local machine_pkgs
        machine_pkgs=$(parse_package_list "$machine_file")
        if [ -n "$machine_pkgs" ]; then
            # shellcheck disable=SC2086
            sudo pacman -S --needed --noconfirm $machine_pkgs || warn "Some $machine_type packages failed to install"
        fi
    fi

    info "Package installation complete!"
}

# Show diff between installed packages and package lists
show_package_diff() {
    local machine_type="$1"

    info "Comparing installed packages with package lists..."

    # Get currently installed explicit packages
    local installed
    installed=$(pacman -Qqe | sort)

    # Get packages from lists
    local listed=""
    if [ -f "$PACKAGES_DIR/core.txt" ]; then
        listed="$listed $(parse_package_list "$PACKAGES_DIR/core.txt")"
    fi
    if [ -f "$PACKAGES_DIR/${machine_type}.txt" ]; then
        listed="$listed $(parse_package_list "$PACKAGES_DIR/${machine_type}.txt")"
    fi
    listed=$(echo "$listed" | tr ' ' '\n' | sort -u | grep -v '^$')

    echo ""
    echo "=== Missing (in list but not installed) ==="
    comm -23 <(echo "$listed") <(echo "$installed") || true

    echo ""
    echo "=== Extra (installed but not in list) ==="
    comm -13 <(echo "$listed") <(echo "$installed") || true
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
    mkdir -p "$CONFIG_DIR/wezterm"
    mkdir -p "$CONFIG_DIR/yazi"
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
        link_config "$DOTFILES_DIR/config/flags/chrome-flags-laptop.conf" "$CONFIG_DIR/chrome-flags.conf"
        link_config "$DOTFILES_DIR/config/flags/electron-flags-laptop.conf" "$CONFIG_DIR/electron-flags.conf"
        info "Using laptop configuration (1x scale)"
    else
        link_config "$DOTFILES_DIR/config/hypr/hosts/desktop.conf" "$CONFIG_DIR/hypr/host.conf"
        link_config "$DOTFILES_DIR/config/flags/chrome-flags-desktop.conf" "$CONFIG_DIR/chrome-flags.conf"
        link_config "$DOTFILES_DIR/config/flags/electron-flags-desktop.conf" "$CONFIG_DIR/electron-flags.conf"
        info "Using desktop configuration (2x HiDPI scale)"
    fi
    
    # Link waybar (host-specific style)
    link_config "$DOTFILES_DIR/config/waybar/config.jsonc" "$CONFIG_DIR/waybar/config.jsonc"
    if [ "$machine_type" = "laptop" ]; then
        link_config "$DOTFILES_DIR/config/waybar/style-laptop.css" "$CONFIG_DIR/waybar/style.css"
    else
        link_config "$DOTFILES_DIR/config/waybar/style-desktop.css" "$CONFIG_DIR/waybar/style.css"
    fi
    
    # Link mako
    link_config "$DOTFILES_DIR/config/mako/config" "$CONFIG_DIR/mako/config"
    
    # Link wofi
    link_config "$DOTFILES_DIR/config/wofi/config" "$CONFIG_DIR/wofi/config"
    link_config "$DOTFILES_DIR/config/wofi/style.css" "$CONFIG_DIR/wofi/style.css"

    # Link wezterm
    link_config "$DOTFILES_DIR/config/wezterm/wezterm.lua" "$CONFIG_DIR/wezterm/wezterm.lua"

    # Link vim
    link_config "$DOTFILES_DIR/config/vim/vimrc" "$HOME/.vimrc"

    # Link yazi
    link_config "$DOTFILES_DIR/config/yazi/yazi.toml" "$CONFIG_DIR/yazi/yazi.toml"
    link_config "$DOTFILES_DIR/config/yazi/theme.toml" "$CONFIG_DIR/yazi/theme.toml"

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

# Parse command line arguments
INSTALL_PACKAGES=false
PACKAGES_ONLY=false
SHOW_DIFF=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --packages)
            INSTALL_PACKAGES=true
            shift
            ;;
        --packages-only)
            INSTALL_PACKAGES=true
            PACKAGES_ONLY=true
            shift
            ;;
        --diff)
            SHOW_DIFF=true
            shift
            ;;
        --uninstall)
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
            rm -f "$CONFIG_DIR/wezterm/wezterm.lua"
            rm -f "$HOME/.vimrc"
            rm -f "$CONFIG_DIR/yazi/yazi.toml"
            rm -f "$CONFIG_DIR/yazi/theme.toml"
            rm -f "$BIN_DIR/cpu_stats.sh"
            rm -f "$BIN_DIR/ram_stats.sh"
            info "Uninstall complete"
            exit 0
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            error "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Detect machine type
MACHINE_TYPE=$(detect_machine_type)

# Handle --diff
if [ "$SHOW_DIFF" = true ]; then
    show_package_diff "$MACHINE_TYPE"
    exit 0
fi

# Install packages if requested
if [ "$INSTALL_PACKAGES" = true ]; then
    install_packages "$MACHINE_TYPE"
fi

# Run main config installation unless --packages-only
if [ "$PACKAGES_ONLY" = false ]; then
    main "$@"
fi
