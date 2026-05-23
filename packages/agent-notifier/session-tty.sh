#!/usr/bin/env bash
# Print the controlling TTY (e.g. /dev/ttys016) for the given PID, walking up
# the process tree until one is attached to a TTY. Used to tag OpenCode
# notifications so a click can refocus the originating Ghostty terminal.

pid="${1:-$PPID}"

for _ in 1 2 3 4 5 6 7 8; do
    [ "$pid" = "" ] || [ "$pid" = "0" ] || [ "$pid" = "1" ] && break

    t=$(ps -o tty= -p "$pid" 2> /dev/null | tr -d ' ')

    if [ "$t" != "" ] && [ "$t" != "??" ]; then
        printf '/dev/%s\n' "$t"
        exit 0
    fi

    pid=$(ps -o ppid= -p "$pid" 2> /dev/null | tr -d ' ')
done

exit 0
