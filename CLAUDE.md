# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Hyprland dotfiles for dual-machine setup (desktop + laptop) with automatic machine detection and host-specific configuration overrides.

## Commands

```bash
./install.sh                 # Symlink configs only
./install.sh --packages      # Symlink + install packages via pacman
./install.sh --packages-only # Skip configs, install packages only
./install.sh --diff          # Compare installed packages vs package lists
./install.sh --uninstall     # Remove all symlinks
```

## Architecture

### Machine Detection
The install script detects machine type by checking for `/sys/class/power_supply/BAT0|BAT1`. Presence of battery = laptop, absence = desktop.

### Configuration Layering
- `config/hypr/hyprland.conf` - Base config, sources `host.conf`
- `config/hypr/hosts/desktop.conf` → symlinked to `~/.config/hypr/host.conf` (5K HiDPI, NVIDIA)
- `config/hypr/hosts/laptop.conf` → symlinked to `~/.config/hypr/host.conf` (1080p, touchpad)

Host-specific files also exist for:
- Waybar styles: `style-desktop.css` / `style-laptop.css`
- Chrome/Electron flags: `chrome-flags-{desktop,laptop}.conf`

### Package Lists
- `packages/core.txt` - All machines (Hyprland stack, CLI tools, dev tools)
- `packages/desktop.txt` - Desktop-only (NVIDIA, gaming, DDC/CI)
- `packages/laptop.txt` - Laptop-only (Intel drivers, power management)

Format: One package per line, `#` comments supported, inline comments stripped.

### Theme
Selenized Dark color scheme applied across WezTerm, Vim, Mako, Waybar:
- Background: `#1c1c1c`
- Accent: `#41c7b9` (cyan)
- Text: `#adbcbc`

Vim relies on terminal ANSI colors from WezTerm.

## Adding New Configs

1. Add config files under `config/<app>/`
2. Update `install.sh` main() to create the target directory and call `link_config`
3. Update `--uninstall` section to remove the symlink

## Key Constraints

- Arch Linux only (pacman-based)
- Symlink deployment - files are not copied
- External theme sourcing: hyprlock sources colors from `~/.config/current-theme/hyprlock.conf`
