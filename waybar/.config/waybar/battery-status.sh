#!/usr/bin/env bash
# Emits waybar custom-module JSON with a class based on charge level:
#   green    >= 85% (or charging)
#   yellow   30-84%
#   red      < 30%
#   critical <= 5% (discharging only; blinks)
BAT="macsmc-battery"
DIR="/sys/class/power_supply/$BAT"

capacity=$(cat "$DIR/capacity" 2>/dev/null) || exit 1
status=$(cat "$DIR/status" 2>/dev/null || echo Unknown)

# Icon arrays: default first, then charging (same order as old config)
read -ra default_icons <<'EOF'
󰂎 󰁺 󰁻 󰁼 󰁽 󰁾 󰁿 󰂀 󰂁 󰂂 󰁹
EOF
read -ra charging_icons <<'EOF'
󰢟 󰢜 󰂆 󰂇 󰂈 󰢝 󰂉 󰢞 󰂊 󰂋 󰂅
EOF

idx=$(( capacity / 10 ))
[ "$idx" -gt 10 ] && idx=10

if [[ "$status" == "Charging" || "$status" == "Full" ]]; then
  icon=${charging_icons[$idx]}
  class="green"
else
  icon=${default_icons[$idx]}
  if   [ "$capacity" -ge 85 ]; then class="green"
  elif [ "$capacity" -le 5 ];  then class="critical"
  elif [ "$capacity" -ge 30 ]; then class="yellow"
  else                              class="red"
  fi
fi

jq -cn --arg text "${capacity}% ${icon}" --arg class "$class" \
  --arg tooltip "$status, ${capacity}%" \
  '{text: $text, class: $class, tooltip: $tooltip}'
