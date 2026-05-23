#!/usr/bin/env bash

# Focus the Ghostty tab whose session runs on the given TTY.
#
# Ghostty's released AppleScript dictionary (<= 1.3.1) can't address a tab by
# TTY, so re-resolve it live: write a unique OSC title marker to the TTY, then
# use Accessibility to find the tab button whose title now contains the marker
# and AX-press it. Brings Ghostty to the front regardless. Only inspects
# window 1. Requires Accessibility + Automation (System Events) permission.
#
# Usage: focus-ghostty-tab.sh /dev/ttysNNN

dev="${1:?usage: focus-ghostty-tab.sh /dev/ttysNNN}"
[ "${dev#/dev/}" = "$dev" ] && dev="/dev/$dev"
[ -w "$dev" ] || {
    osascript -e 'tell application "Ghostty" to activate' 2> /dev/null
    exit 0
}

marker="__CCN_FOCUS_$$_$(date +%s%N)__"
printf '\033]0;%s\007' "$marker" > "$dev" 2> /dev/null
sleep 0.05

osascript -e "
  tell application \"Ghostty\" to activate
  tell application \"System Events\"
    tell process \"Ghostty\"
      try
        tell window 1
          tell tab group \"tab bar\"
            repeat with t in (every radio button)
              if name of t contains \"$marker\" then
                perform action \"AXPress\" of t
                exit repeat
              end if
            end repeat
          end tell
        end tell
      end try
    end tell
  end tell
" 2> /dev/null

# Restore an empty title (Ghostty falls back to shell-managed title).
printf '\033]0;\007' > "$dev" 2> /dev/null || true
