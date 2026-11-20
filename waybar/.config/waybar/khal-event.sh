#!/usr/bin/env bash
# Waybar module: show the next event within the next 24h from khal
# Emits single-line JSON: {"text": ..., "tooltip": ...}

KHAL="$HOME/.local/bin/khal"
agenda=$("$KHAL" list now 1d 2>/dev/null) || exit 1

# First agenda line after the "Day, date" header
first=$(sed -n '2p' <<<"$agenda")
[ -z "$first" ] && { jq -cn --arg t "no events" '{text: "󰃭", tooltip: "No events in the next 24h"}'; exit 0; }

title=${first#* }            # strip leading time range
times=$(awk '{print $1}' <<<"$first")

jq -cn --arg icon "󰃭" --arg title "$title" --arg times "$times" \
  '{text: "\($icon) \($title)", tooltip: "\($times) \($title)"}'
