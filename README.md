# dotfiles

Hyprland configuration for desktop and laptop workstations.

## Quick Install

```bash
git clone https://github.com/adolago/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install.sh
```

The install script auto-detects desktop vs laptop and applies appropriate settings.

## Structure

```
~/.dotfiles/
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
├── bin/                       # Waybar scripts
├── install.sh
└── README.md
```

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

## Uninstall

```bash
~/.dotfiles/install.sh --uninstall
```

## Dependencies

- hyprland, hyprpaper, hyprlock, hypridle
- waybar
- mako
- wofi
- wezterm (terminal)
- JetBrainsMono Nerd Font
- lm_sensors (for CPU temp)
- brightnessctl (laptop)
- ddcutil (desktop monitor control)
