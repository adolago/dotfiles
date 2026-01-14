# CLAUDE.md

Guidelines for Claude Code (claude.ai/code) when working with this Hyprland dotfiles repository.

## Overview

Professional Hyprland configuration for dual-machine environments with intelligent hardware detection and host-specific configuration overrides.

## Essential Commands

```bash
./install.sh                 # Install configuration symlinks only
./install.sh --packages      # Install symlinks and packages via pacman
./install.sh --packages-only # Install packages only, skip configurations
./install.sh --diff          # Compare installed packages against defined lists
./install.sh --uninstall     # Remove all configuration symlinks
```

## Architecture

### Hardware Detection
The installer automatically detects machine type by checking for battery presence at `/sys/class/power_supply/BAT0|BAT1`. Battery detection indicates laptop hardware, absence indicates desktop configuration.

### Configuration Hierarchy
- **`config/hypr/hyprland.conf`**: Base configuration that sources `host.conf`
- **`config/hypr/hosts/desktop.conf`**: Desktop-specific settings (5K HiDPI, NVIDIA) → symlinked to `~/.config/hypr/host.conf`
- **`config/hypr/hosts/laptop.conf`**: Laptop-specific settings (1080p, touchpad) → symlinked to `~/.config/hypr/host.conf`

Host-specific configurations also include:
- **Waybar styling**: `style-desktop.css` / `style-laptop.css`
- **Browser optimization**: `chrome-flags-{desktop,laptop}.conf`

### Package Management
- **`packages/core.txt`**: Universal packages (Hyprland stack, CLI utilities, development tools)
- **`packages/desktop.txt`**: Desktop-specific (NVIDIA drivers, gaming utilities, DDC/CI)
- **`packages/laptop.txt`**: Laptop-specific (Intel graphics, power management, touchpad)

Package format: One package per line with `#` comment support and automatic inline comment stripping.

### Visual Theme

Selenized Dark color scheme consistently applied across all applications:

- **Background**: `#1c1c1c`
- **Accent**: `#41c7b9` (cyan)
- **Text**: `#adbcbc`

Vim leverages terminal ANSI colors from WezTerm configuration.

## Configuration Management

### Adding New Applications

1. **Place configuration files** in `config/<application>/` directory
2. **Update installer**: Modify `install.sh` main() function to create target directory and call `link_config`
3. **Add cleanup**: Update `--uninstall` section to remove application symlinks

### System Requirements

- **Platform**: Arch Linux (pacman-based package management)
- **Deployment**: Symlink-based configuration (files are not copied)
- **Theme Integration**: External theme sourcing with `hyprlock` referencing `~/.config/current-theme/hyprlock.conf`

## Development Guidelines

### Platform Constraints

- **Linux Distribution**: Arch Linux exclusively (pacman package management)
- **Deployment Method**: Symlink-based configuration management
- **Theme Architecture**: External theme sourcing with centralized color management

### Quality Standards

- Maintain compatibility across desktop and laptop hardware configurations
- Ensure all new configurations follow existing symlink patterns
- Test changes on both hardware profiles when applicable
- Document hardware-specific requirements in configuration comments
