#!/usr/bin/env bash
# Waybar custom module: label = tailscale icon, tooltip = peer list

if ! json=$(tailscale status --json 2>/dev/null) ||
  [[ "$(jq -r '.BackendState // empty' <<<"$json")" != "Running" ]]; then
  jq -cn '{text: "󰀩 Off"}'
  exit 0
fi

jq -cn '{text: "󰌘  On"}'
