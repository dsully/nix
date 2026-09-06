# herdr-recall fish hook: record the command a pane runs on preexec, and its
# exit status when the command finishes.
# Only active inside a herdr pane (HERDR_PANE_ID is set by herdr).

set -l _herdr_recall_candidate (path dirname (status filename))/../bin/herdr-recall

if test -n "$HERDR_PANE_ID" -a -x "$_herdr_recall_candidate"
    set -g _herdr_recall_bin (path resolve $_herdr_recall_candidate)

    function _herdr_recall_preexec --on-event fish_preexec
        $_herdr_recall_bin preexec $argv[1] >/dev/null 2>&1 &
        disown 2>/dev/null
    end

    # fish_postexec, not fish_prompt: only postexec still carries the command's
    # own exit status. Read $status on the first line, because any command run
    # before it in this function replaces it.
    function _herdr_recall_postexec --on-event fish_postexec
        set -l code $status

        $_herdr_recall_bin precmd $code $PWD >/dev/null 2>&1 &
        disown 2>/dev/null
    end
end
