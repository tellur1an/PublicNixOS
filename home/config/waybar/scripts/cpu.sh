#!/usr/bin/env bash
# Average CPU usage (delta over 0.5s)
read -r _ u1 n1 s1 i1 w1 q1 sq1 st1 g1 gn1 < /proc/stat
t1=$((u1+n1+s1+i1+w1+q1+sq1+st1))
idle1=$((i1+w1))
sleep 0.5
read -r _ u2 n2 s2 i2 w2 q2 sq2 st2 g2 gn2 < /proc/stat
t2=$((u2+n2+s2+i2+w2+q2+sq2+st2))
idle2=$((i2+w2))
td=$((t2 - t1))
id=$((idle2 - idle1))
if (( td <= 0 )); then usage=0; else usage=$(( (100*(td - id)) / td )); fi

# Temperature: try hwmon/thermal; fallback to `sensors`
temp="?"
for p in /sys/devices/platform/coretemp.*/hwmon/hwmon*/temp*_input /sys/class/thermal/thermal_zone*/temp; do
  [[ -r "$p" ]] || continue
  v=$(cat "$p" 2>/dev/null) || continue
  (( v <= 0 )) && continue
  if (( v > 1000 )); then c=$((v/1000)); else c=$v; fi
  [[ "$temp" = "?" || $c -gt $temp ]] && temp=$c
done
if [[ "$temp" = "?" ]] && command -v sensors >/dev/null 2>&1; then
  temp=$(sensors 2>/dev/null | awk '/Tctl:|Tdie:|Package id 0:|CPU/ {gsub(/[+°C]/,"",$2); print int($2); exit}')
  [[ -z "$temp" ]] && temp="?"
fi

printf '{"text":"󰍛","tooltip":"%s%% avg • %s°C"}\n' "$usage" "$temp"
