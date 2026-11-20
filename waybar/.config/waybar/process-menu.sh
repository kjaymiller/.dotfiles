#!/usr/bin/env bash
# htop-style process list in rofi.
# Select a process to kill it; ESC closes.

# rofi wrapper: tsmenu-style popup anchored top-right
rofi_tr() {
    rofi "$@" -theme "$HOME/.config/rofi/topmenu.rasi"
}

while true; do
    sel=$(
        {
            printf '\0prompt\x1fProcesses\n'
            ps -eo pid,pcpu,pmem,comm --sort=-pcpu |
                awk 'NR==1 {next} {printf "%-7s %5s%% %5s%%  %s\n", $1, $2, $3, $4}' |
                head -n 30
        } | rofi_tr -dmenu -i -p "top" -no-custom
    ) || exit 0

    # Nothing selected (ESC) -> close
    [ -z "$sel" ] && exit 0

    pid=$(echo "$sel" | awk '{print $1}')

    action=$(printf 'Switch to window\nSend SIGTERM (graceful)\nSend SIGKILL (force)\nBack to list' |
        rofi_tr -dmenu -i -p "PID $pid")
    case "$action" in
        Switch*)
            # find the niri window(s) belonging to this pid and focus the first
            win_id=$(niri msg --json windows |
                jq -r --argjson pid "$pid" '[.[] | select(.pid == $pid)] | first | .id // empty')
            if [ -n "$win_id" ]; then
                niri msg action focus-window --id "$win_id"
                exit 0
            fi
            notify-send "process-menu" "No window found for PID $pid"
            ;;
        Send\ SIGTERM*) kill "$pid" 2>/dev/null ;;
        Send\ SIGKILL*) kill -9 "$pid" 2>/dev/null ;;
        *) continue ;;
    esac
    sleep 0.3
done
