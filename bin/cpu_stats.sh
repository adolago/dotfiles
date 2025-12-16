#!/bin/bash
# Hardware stats for Waybar: CPU/GPU load and temperature
export LC_ALL=C
MODE="${1:-auto}"

cpu_energy_file() {
  local f
  shopt -s nullglob
  for f in \
    /sys/class/powercap/intel-rapl:0/energy_uj \
    /sys/class/powercap/intel-rapl:*/energy_uj \
    /sys/class/powercap/intel-rapl:*/intel-rapl:*:*/energy_uj \
    /sys/class/powercap/*/energy_uj \
    /sys/class/powercap/*/*/energy_uj; do
    if [[ -r "$f" ]]; then
      shopt -u nullglob
      echo "$f"
      return 0
    fi
  done
  shopt -u nullglob
  echo ""
}

read_cpu_power_w() {
  local ef e1 e2 dt
  ef="$(cpu_energy_file)"
  [ -n "$ef" ] || { echo "---"; return; }
  e1="$(cat "$ef" 2>/dev/null)" || { echo "---"; return; }
  dt="$1"
  sleep "$dt"
  e2="$(cat "$ef" 2>/dev/null)" || { echo "---"; return; }
  awk -v e1="$e1" -v e2="$e2" -v dt="$dt" 'BEGIN{w=((e2-e1)/1000000)/dt; if (w<0) w=0; printf "%d", int(w+0.5)}'
}

read_cpu_temp() {
  if command -v sensors >/dev/null 2>&1; then
    cpu_temp=$(sensors 2>/dev/null | awk '
      /Package id 0:/ {
        gsub("[+°C]", "", $4);
        print int($4 + 0.5);
        exit;
      }
      /Tctl:/ {
        gsub("[+°C]", "", $2);
        print int($2 + 0.5);
        exit;
      }
    ')
    if [[ -n "$cpu_temp" ]]; then
      echo "$cpu_temp"
      return
    fi
  fi

  for zone in /sys/class/thermal/thermal_zone*/temp; do
    [[ -r "$zone" ]] || continue
    temp_raw=$(<"$zone")
    [[ -n "$temp_raw" ]] || continue
    echo $(((temp_raw + 500) / 1000))
    return
  done

  echo ""
}

read_gpu_metrics() {
  local gpu_temp="" gpu_load=""

  if command -v nvidia-smi >/dev/null 2>&1; then
    IFS=',' read -r gpu_temp gpu_load < <(nvidia-smi --query-gpu=temperature.gpu,utilization.gpu --format=csv,noheader,nounits | head -n1)
    gpu_temp=${gpu_temp// /}
    gpu_load=${gpu_load// /}
  fi

  if [[ -z "$gpu_load" ]]; then
    for busy in /sys/class/drm/card*/device/gpu_busy_percent; do
      [[ -r "$busy" ]] || continue
      gpu_load=$(<"$busy")
      [[ -n "$gpu_load" ]] || continue
      break
    done
  fi

  if [[ -z "$gpu_temp" ]]; then
    if command -v sensors >/dev/null 2>&1; then
      gpu_temp=$(sensors 2>/dev/null | awk '
        /amdgpu-pci-|smu/ {
          next_hwmon=1
        }
        next_hwmon && /edge:/ {
          gsub("[+°C]", "", $2);
          print int($2 + 0.5);
          exit;
        }
      ')
    fi
  fi

  if [[ -z "$gpu_temp" ]]; then
    for hwmon in /sys/class/drm/card*/device/hwmon/hwmon*/temp1_input; do
      [[ -r "$hwmon" ]] || continue
      temp_raw=$(<"$hwmon")
      [[ -n "$temp_raw" ]] || continue
      gpu_temp=$(((temp_raw + 500) / 1000))
      break
    done
  fi

  echo "$gpu_load $gpu_temp"
}

read_gpu_power_w() {
  if command -v nvidia-smi >/dev/null 2>&1 && nvidia-smi -L >/dev/null 2>&1; then
    local v
    v="$(nvidia-smi --query-gpu=power.draw --format=csv,noheader,nounits 2>/dev/null | head -n1 | tr -d ' ')"
    [ -n "$v" ] && [ "$v" != "N/A" ] && awk -v val="$v" 'BEGIN{printf "%d", int(val+0.5)}' || echo "---"
    return
  fi
  local pf pv
  pf="$(ls -1 /sys/class/drm/card*/device/hwmon/hwmon*/power1_average 2>/dev/null | head -n1)"
  [ -n "$pf" ] || { echo "---"; return; }
  pv="$(cat "$pf" 2>/dev/null)" || { echo "---"; return; }
  awk -v uw="$pv" 'BEGIN{printf "%d", int((uw/1000000)+0.5)}'
}

dim_leading_zeros() {
  local s="$1"
  if [[ "$s" =~ ^0+ ]]; then
    local zeros="${BASH_REMATCH[0]}"
    local rest="${s#"$zeros"}"
    local dimmed=""
    local i
    for ((i = 0; i < ${#zeros}; i++)); do
      dimmed+='<span alpha="35%">0</span>'
    done
    printf '%s' "${dimmed}${rest}"
  else
    printf '%s' "$s"
  fi
}

format_percent() {
  local value="$1"
  local text
  if [[ "$value" =~ ^[0-9]+$ ]]; then
    printf -v text "%03d%%" "$value"
  else
    text='---%'
  fi
  dim_leading_zeros "$text"
}

format_temp() {
  local value="$1"
  local text
  if [[ "$value" =~ ^[0-9]+$ ]]; then
    printf -v text "%03d°C" "$value"
  else
    text='---°C'
  fi
  dim_leading_zeros "$text"
}

format_power() {
  local value="$1"
  local text
  if [[ "$value" =~ ^[0-9]+$ ]]; then
    printf -v text "%03dW" "$value"
  else
    text='---W'
  fi
  dim_leading_zeros "$text"
}

# Read initial CPU stats
read -r _ user nice system idle iowait irq softirq steal guest guest_nice < <(grep '^cpu ' /proc/stat)
total=$((user + nice + system + idle + iowait + irq + softirq + steal + guest + guest_nice))
idle_all=$((idle + iowait))

# Read initial CPU energy
ef="$(cpu_energy_file)"
if [ -n "$ef" ]; then
  e1="$(cat "$ef" 2>/dev/null)"
fi

# Single sleep for all measurements
sleep 0.3

# Read final CPU stats and calculate usage
read -r _ user2 nice2 system2 idle2 iowait2 irq2 softirq2 steal2 guest2 guest_nice2 < <(grep '^cpu ' /proc/stat)
total2=$((user2 + nice2 + system2 + idle2 + iowait2 + irq2 + softirq2 + steal2 + guest2 + guest_nice2))
idle_all2=$((idle2 + iowait2))
total_diff=$((total2 - total))
idle_diff=$((idle_all2 - idle_all))
if ((total_diff > 0)); then
  cpu_usage=$(((total_diff - idle_diff) * 100 / total_diff))
else
  cpu_usage=0
fi

# Read CPU power directly
cpu_power=$(read_cpu_power_w 0.3)

cpu_temp=$(read_cpu_temp)
read -r gpu_load gpu_temp < <(read_gpu_metrics)
gpu_power=$(read_gpu_power_w)

cpu_text=$(printf "CPU:%s/%s/%s" \
  "$(format_percent "$cpu_usage")" \
  "$(format_temp "$cpu_temp")" \
  "$(format_power "$cpu_power")")

gpu_text=$(printf "GPU:%s/%s/%s" \
  "$(format_percent "$gpu_load")" \
  "$(format_temp "$gpu_temp")" \
  "$(format_power "$gpu_power")")

has_gpu() {
  # Check for NVIDIA GPU
  if command -v nvidia-smi >/dev/null 2>&1 && nvidia-smi -L >/dev/null 2>&1; then
    return 0
  fi
  # Check for AMD/Intel discrete GPU
  if ls /sys/class/drm/card*/device/gpu_busy_percent >/dev/null 2>&1; then
    return 0
  fi
  return 1
}

case "$MODE" in
  cpu)
    printf "%s" "$cpu_text"
    ;;
  gpu)
    printf "%s" "$gpu_text"
    ;;
  both)
    printf "%s | %s" "$cpu_text" "$gpu_text"
    ;;
  auto|*)
    if has_gpu; then
      printf "%s | %s" "$cpu_text" "$gpu_text"
    else
      printf "%s" "$cpu_text"
    fi
    ;;
esac
