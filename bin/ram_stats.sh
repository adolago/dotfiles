#!/bin/bash
# Consistent RAM stats output for Waybar (matching CPU/GPU formatting)
export LC_ALL=C

read_memory_usage() {
  local total="" available=""
  while IFS=' :' read -r key value _; do
    case "$key" in
      MemTotal) total="$value" ;;
      MemAvailable) available="$value" ;;
    esac
    if [[ -n "$total" && -n "$available" ]]; then
      break
    fi
  done < /proc/meminfo

  if [[ -n "$total" && -n "$available" && "$total" -gt 0 ]]; then
    local used=$((total - available))
    echo $(((used * 100) / total))
  else
    echo ""
  fi
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

memory_percent=$(read_memory_usage)
printf 'RAM:%s' "$(format_percent "$memory_percent")"
