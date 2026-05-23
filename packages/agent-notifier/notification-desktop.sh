#!/usr/bin/env bash

# Claude Code Notification hook → native macOS banner via ClaudeCodeNotifier.app.
# Clicking the banner refocuses the originating Ghostty terminal (matched by
# TTY). @detect@, @sessiontty@ and @jq@ are replaced with Nix store paths at build;
# the app bundle is launched from ~/Applications, where it's linked + registered.

input=$(cat)

notification_type=$("@jq@" -r '.notification_type // empty' <<< "$input")
message=$("@jq@" -r '.message // empty' <<< "$input")

app="$HOME/Applications/ClaudeCodeNotifier.app"
detect="@detect@"
session_tty_script="@sessiontty@"
focus_script="@focus@"
title="Claude Code"

tab_label=""
if [ "$TERM_PROGRAM" = "ghostty" ] && [ -x "$detect" ]; then
    tab_index=$("$detect" "$$" 2> /dev/null)
    [ "$tab_index" != "" ] && tab_label="#$tab_index"
fi
if [ "$tab_label" = "" ]; then
    tab_label=$(basename "${PWD:-unknown}")
    [ "${#tab_label}" -gt 20 ] && tab_label="${tab_label:0:19}…"
fi

case "$notification_type" in
    permission_prompt)
        subtitle="[$tab_label] Permission required"
        default="Claude needs your permission to continue"
        ;;
    idle_prompt)
        subtitle="[$tab_label] Task complete"
        default="Claude is waiting for your input"
        ;;
    elicitation_dialog)
        subtitle="[$tab_label] Input needed"
        default="Claude has a question for you"
        ;;
    *)
        subtitle="[$tab_label] Attention needed"
        default="Claude Code needs your attention"
        ;;
esac

tty_args=()

session_tty=$("$session_tty_script" "$$" 2> /dev/null)

[ "$session_tty" != "" ] && tty_args=(--tty "$session_tty" --focus-script "$focus_script")

open -n "$app" --args "$title" "$subtitle" "${message:-$default}" "${tty_args[@]}"
