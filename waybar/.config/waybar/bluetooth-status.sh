#!/usr/bin/env bash
# Waybar custom module: bluetooth icon; tooltip lists paired devices
# (connected ones normal, rest dimmed)

if ! show=$(bluetoothctl show 2>/dev/null) ||
  grep -q "No default controller" <<<"$show"; then
  jq -cn '{text: "󰂲"}'
  exit 0
fi

if [[ "$(awk -F': ' '/^Powered:/ {print $2}' <<<"$show")" != "yes" ]]; then
  jq -cn --arg tip "Bluetooth is off"$'\n'"Click to open bt-menu" \
    '{text: "󰂲 Off", tooltip: $tip}'
  exit 0
fi

conn_macs=$(bluetoothctl devices Connected 2>/dev/null | awk '{print $2}')

tip=""
n=0
while IFS=' ' read -r mac name; do
  [[ -n "$mac" ]] || continue
  if grep -qxF "$mac" <<<"$conn_macs"; then
    tip+="󰂯 $name"$'\n'
    n=$((n + 1))
  else
    tip+="<span foreground=\"#6c7086\">󰂲 $name</span>"$'\n'
  fi
done < <(bluetoothctl devices Paired 2>/dev/null | sed 's/^Device //')

tip=${tip%$'\n'}
[[ -n "$tip" ]] || tip="No paired devices"$'\n'"Click to open bt-menu"

if ((n > 0)); then
  text="󰂯 $n"
else
  text="󰂲"
fi

jq -cn --arg text "$text" --arg tip "$tip" '{text: $text, tooltip: $tip}'
