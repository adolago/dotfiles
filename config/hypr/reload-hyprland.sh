#!/bin/bash
# Reload Hyprland configuration

echo "Reloading Hyprland configuration..."

hyprctl reload

killall waybar 2>/dev/null
sleep 1
"$HOME/.config/hypr/start-waybar.sh" &

killall hyprpaper 2>/dev/null
sleep 1
hyprpaper -c ~/.config/hypr/hyprpaper.conf &

echo "Hyprland reloaded successfully"
