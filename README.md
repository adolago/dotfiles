# dotfiles

Hyprland configuration for desktop and laptop workstations.

## Quick Install

```bash
git clone https://github.com/adolago/dotfiles.git ~/Repositories/dotfiles
cd ~/Repositories/dotfiles
./install.sh
```

The install script auto-detects desktop vs laptop and applies appropriate settings.

## Structure

```
~/Repositories/dotfiles/
├── config/
│   ├── hypr/
│   │   ├── hyprland.conf      # Shared base config
│   │   ├── hosts/
│   │   │   ├── desktop.conf   # HiDPI, NVIDIA, external monitor
│   │   │   └── laptop.conf    # Touchpad, battery, built-in display
│   │   ├── hypridle.conf
│   │   ├── hyprlock.conf
│   │   └── reload-hyprland.sh
│   ├── waybar/
│   ├── mako/
│   └── wofi/
├── packages/
│   ├── core.txt               # Packages for all machines
│   ├── desktop.txt            # Desktop-specific (NVIDIA, gaming)
│   └── laptop.txt             # Laptop-specific (Intel, power mgmt)
├── bin/                       # Waybar scripts
├── install.sh
└── README.md
```

## Package Management

Sync core software across machines using package lists:

```bash
# Install configs + packages
./install.sh --packages

# Only install packages (skip config symlinks)
./install.sh --packages-only

# Show diff between installed packages and lists
./install.sh --diff
```

### Package Lists

- `packages/core.txt` - Essential packages for all machines (Hyprland stack, CLI tools, dev tools)
- `packages/desktop.txt` - Desktop-specific (NVIDIA drivers, gaming, DDC/CI)
- `packages/laptop.txt` - Laptop-specific (Intel drivers, power management)

Edit these files to customize your package set.

## Host-Specific Configuration

The installer creates `~/.config/hypr/host.conf` symlinked to the appropriate host config:

- **Desktop**: 5K monitor at 2x scale, NVIDIA env vars, DDC/CI brightness controls
- **Laptop**: 1080p built-in display, touchpad gestures, brightness keys

To override, edit `~/.config/hypr/host.conf` directly (it's a symlink, so changes persist).

## Post-Install

1. Create wallpaper config:
   ```bash
   echo "preload = /path/to/wallpaper.jpg" > ~/.config/hypr/hyprpaper.conf
   echo "wallpaper = eDP-1,/path/to/wallpaper.jpg" >> ~/.config/hypr/hyprpaper.conf
   ```

2. Create theme directory for hyprlock:
   ```bash
   mkdir -p ~/.config/current-theme
   # Add hyprlock.conf with color variables and background image
   ```

3. Reload: `hyprctl reload`

## Sync Workflow

```bash
# On source machine: push changes
cd ~/Repositories/dotfiles
git add -A && git commit -m "Update" && git push

# On target machine: pull and apply
cd ~/Repositories/dotfiles
git pull
./install.sh            # configs only
./install.sh --packages # configs + packages
```

## Uninstall

```bash
~/Repositories/dotfiles/install.sh --uninstall
```
