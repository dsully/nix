# herdr-autoname fish hook: rename the current tab on preexec, and settle it
# back to the idle name at each prompt.
# Only active inside a herdr pane (HERDR_TAB_ID is set by herdr).

set -l _herdr_autoname_candidate (path dirname (status filename))/../bin/herdr-autoname

if test -n "$HERDR_TAB_ID" -a -x "$_herdr_autoname_candidate"
    set -g _herdr_autoname_bin (path resolve $_herdr_autoname_candidate)

    function _herdr_autoname_preexec --on-event fish_preexec
        # $argv[1] is the command line as entered. fish expands no aliases here;
        # they are functions, so the typed name is the name to show.
        $_herdr_autoname_bin preexec $argv[1] >/dev/null 2>&1 &
        disown 2>/dev/null
    end

    # fish_prompt, not fish_postexec: this is the zsh precmd equivalent and must
    # also fire when no command ran, such as an empty line or a cancelled edit.
    function _herdr_autoname_prompt --on-event fish_prompt
        $_herdr_autoname_bin precmd fish $PWD >/dev/null 2>&1 &
        disown 2>/dev/null
    end
end
