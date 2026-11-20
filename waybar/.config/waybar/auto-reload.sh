#!/bin/bash
while inotifywait -e close_write ~/.config/waybar; do
  pkill -x waybar
  sleep 0.3
  NIRI_SOCKET=$(ls /run/user/1000/niri.*.sock 2>/dev/null | head -n1) waybar &
done
