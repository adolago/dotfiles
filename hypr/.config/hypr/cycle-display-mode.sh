#!/bin/bash
# Cycle through ASUS PA27JCV display modes
# 0x26, 0x0d, 0x27, 0x28 are the available modes

STATE_FILE="$HOME/.config/hypr/.display_mode"
MODES=(0x26 0x0d 0x27 0x28)
MODE_NAMES=("Mode 1" "Mode 2" "Mode 3" "Mode 4")

# Get current index
if [ -f "$STATE_FILE" ]; then
    IDX=$(cat "$STATE_FILE")
else
    IDX=0
fi

# Cycle to next
IDX=$(( (IDX + 1) % 4 ))
echo "$IDX" > "$STATE_FILE"

# Set mode
ddcutil setvcp 0xDC ${MODES[$IDX]}
notify-send "Display Mode" "${MODE_NAMES[$IDX]}" -t 1000
