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

### Deployment: GNU Stow + Conditional Links

The repo uses **GNU Stow** for declarative symlink management. Each top-level directory that maps to `$HOME` is a "stow package":

```
dotfiles/
  hypr/.config/hypr/         # Stow package → ~/.config/hypr/*
  mako/.config/mako/         # Stow package → ~/.config/mako/*
  starship/.config/          # Stow package → ~/.config/starship.toml
  wezterm/.config/wezterm/   # Stow package → ~/.config/wezterm/*
  wofi/.config/wofi/         # Stow package → ~/.config/wofi/*
  yazi/.config/yazi/         # Stow package → ~/.config/yazi/*
  vim/                       # Stow package → ~/.vimrc
  scripts/bin/               # Stow package → ~/bin/*
  hosts/                     # Conditional (not stowed)
  waybar/                    # Conditional (not stowed)
  flags/                     # Conditional (not stowed)
  packages/                  # Package lists (not stowed)
```

**Stow packages** are deployed with: `stow -t $HOME --no-folding <package>`
**Conditional configs** (hosts, waybar, flags) are linked manually by `install.sh` based on machine type.

### Hardware Detection
The installer detects machine type by checking for battery presence at `/sys/class/power_supply/BAT0|BAT1`. Battery = laptop, no battery = desktop.

### Configuration Hierarchy
- **`hypr/.config/hypr/hyprland.conf`**: Base configuration that sources `host.conf`
- **`hosts/desktop.conf`**: Desktop-specific settings (5K HiDPI, NVIDIA) → symlinked to `~/.config/hypr/host.conf`
- **`hosts/laptop.conf`**: Laptop-specific settings (1080p, touchpad) → symlinked to `~/.config/hypr/host.conf`

Host-specific configurations also include:
- **Waybar**: `waybar/config.jsonc` / `config-laptop.jsonc`, `style-desktop.css` / `style-laptop.css`
- **Browser flags**: `flags/chrome-flags-{desktop,laptop}.conf`

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

### Adding New Applications (Stow Package)

1. Create directory: `<app>/.config/<app>/` with config files inside
2. Add the package name to `STOW_PACKAGES` array in `install.sh`
3. Run `./install.sh` to deploy

### Adding Conditional Configs

1. Place variant files at top level (e.g., `flags/`)
2. Add linking logic to the if/else block in `main()` of `install.sh`
3. Add removal to the `uninstall()` function

### System Requirements

- **Platform**: Arch Linux (pacman-based package management)
- **Dependencies**: GNU Stow (`pacman -S stow`)
- **Deployment**: Stow symlinks + manual conditional links
- **Theme Integration**: External theme sourcing with `hyprlock` referencing `~/.config/current-theme/hyprlock.conf`
