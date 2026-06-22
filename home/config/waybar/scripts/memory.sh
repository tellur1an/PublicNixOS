#!/usr/bin/env bash
tot_kb=$(awk '/MemTotal:/ {print $2}' /proc/meminfo)
av_kb=$(awk '/MemAvailable:/ {print $2}' /proc/meminfo)
used_kb=$((tot_kb - av_kb))
pct=$(( 100 * used_kb / tot_kb ))
used_gib=$(awk -v v="$used_kb" 'BEGIN{printf "%.1f", v/1024/1024}')
tot_gib=$(awk -v v="$tot_kb" 'BEGIN{printf "%.1f", v/1024/1024}')
printf '{"text":"","tooltip":"%s%% • %sGiB / %sGiB"}\n' "$pct" "$used_gib" "$tot_gib"
