#!/bin/bash
# Dotfiles installation script
# Uses GNU Stow for declarative symlinks + manual links for conditional configs

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config"
BIN_DIR="$HOME/bin"
PACKAGES_DIR="$DOTFILES_DIR/packages"

# Stow packages to deploy (each is a top-level directory mirroring $HOME)
STOW_PACKAGES=(hypr mako starship wezterm wofi yazi rofi scripts gtk qt6ct)

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
    echo "  --packages       Install packages from package lists"
    echo "  --packages-only  Only install packages, skip config symlinks"
    echo "  --uninstall      Remove config symlinks"
    echo "  --diff           Show package differences vs package lists"
    echo "  -h, --help       Show this help"
    echo ""
    echo "Without options, only symlinks configs (no package installation)"
}

# Detect machine type
detect_machine_type() {
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

    if [ -f "$PACKAGES_DIR/core.txt" ]; then
        info "Installing core packages..."
        local core_pkgs
        core_pkgs=$(parse_package_list "$PACKAGES_DIR/core.txt")
        if [ -n "$core_pkgs" ]; then
            # shellcheck disable=SC2086
            sudo pacman -S --needed --noconfirm $core_pkgs || warn "Some core packages failed to install"
        fi
    fi

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

    local installed
    installed=$(pacman -Qqe | sort)

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

# Create symlink (for conditional configs only)
link_config() {
    local src="$1"
    local dest="$2"

    # Back up non-symlink files, remove existing symlinks
    if [ -e "$dest" ] && [ ! -L "$dest" ]; then
        local backup="${dest}.backup.$(date +%Y%m%d_%H%M%S)"
        warn "Backing up existing $dest to $backup"
        mv "$dest" "$backup"
    elif [ -L "$dest" ]; then
        rm "$dest"
    fi

    mkdir -p "$(dirname "$dest")"
    ln -sf "$src" "$dest"
    info "Linked $(basename "$src") -> $dest"
}

# Main installation
main() {
    local machine_type
    machine_type=$(detect_machine_type)

    info "Detected machine type: $machine_type"
    info "Installing dotfiles from $DOTFILES_DIR"

    # Ensure target directories exist (prevents stow from folding them)
    mkdir -p "$CONFIG_DIR/hypr" "$CONFIG_DIR/waybar" "$CONFIG_DIR/mako"
    mkdir -p "$CONFIG_DIR/wofi" "$CONFIG_DIR/wezterm" "$CONFIG_DIR/yazi" "$CONFIG_DIR/rofi"
    mkdir -p "$BIN_DIR"

    # Deploy stow packages
    info "Deploying stow packages: ${STOW_PACKAGES[*]}"
    stow -d "$DOTFILES_DIR" -t "$HOME" --no-folding "${STOW_PACKAGES[@]}"
    info "Stow deployment complete"

    # Conditional configs: host-specific hyprland, waybar, browser flags
    if [ "$machine_type" = "laptop" ]; then
        link_config "$DOTFILES_DIR/hosts/laptop.conf"                  "$CONFIG_DIR/hypr/host.conf"
        link_config "$DOTFILES_DIR/waybar/config-laptop.jsonc"         "$CONFIG_DIR/waybar/config.jsonc"
        link_config "$DOTFILES_DIR/waybar/style-laptop.css"            "$CONFIG_DIR/waybar/style.css"
        link_config "$DOTFILES_DIR/flags/chrome-flags-laptop.conf"     "$CONFIG_DIR/chrome-flags.conf"
        link_config "$DOTFILES_DIR/flags/electron-flags-laptop.conf"   "$CONFIG_DIR/electron-flags.conf"
        info "Using laptop configuration (1x scale)"
    else
        link_config "$DOTFILES_DIR/hosts/desktop.conf"                 "$CONFIG_DIR/hypr/host.conf"
        link_config "$DOTFILES_DIR/waybar/config.jsonc"                "$CONFIG_DIR/waybar/config.jsonc"
        link_config "$DOTFILES_DIR/waybar/style-desktop.css"           "$CONFIG_DIR/waybar/style.css"
        link_config "$DOTFILES_DIR/flags/chrome-flags-desktop.conf"    "$CONFIG_DIR/chrome-flags.conf"
        link_config "$DOTFILES_DIR/flags/electron-flags-desktop.conf"  "$CONFIG_DIR/electron-flags.conf"
        info "Using desktop configuration (2x HiDPI scale)"
    fi
    # Chromium reads the same flags as Chrome
    ln -sf "$CONFIG_DIR/chrome-flags.conf" "$CONFIG_DIR/chromium-flags.conf"

    info ""
    info "Installation complete!"
    info ""
    info "Post-install steps:"
    info "  1. Adjust monitor settings in ~/.config/hypr/host.conf if needed"
    info "  2. Run: hyprctl reload"

    if [ -f "$CONFIG_DIR/hypr/host.conf" ]; then
        info "Current monitor config:"
        grep "^monitor" "$CONFIG_DIR/hypr/host.conf" 2>/dev/null || true
    fi
}

# Uninstall: unstow packages + remove conditional links
uninstall() {
    info "Removing stow symlinks..."
    stow -d "$DOTFILES_DIR" -t "$HOME" -D "${STOW_PACKAGES[@]}" 2>/dev/null || true

    info "Removing conditional links..."
    rm -f "$CONFIG_DIR/hypr/host.conf"
    rm -f "$CONFIG_DIR/waybar/config.jsonc"
    rm -f "$CONFIG_DIR/waybar/style.css"
    rm -f "$CONFIG_DIR/chrome-flags.conf"
    rm -f "$CONFIG_DIR/chromium-flags.conf"
    rm -f "$CONFIG_DIR/electron-flags.conf"

    info "Uninstall complete"
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
            uninstall
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

MACHINE_TYPE=$(detect_machine_type)

if [ "$SHOW_DIFF" = true ]; then
    show_package_diff "$MACHINE_TYPE"
    exit 0
fi

if [ "$INSTALL_PACKAGES" = true ]; then
    install_packages "$MACHINE_TYPE"
fi

if [ "$PACKAGES_ONLY" = false ]; then
    main "$@"
fi
