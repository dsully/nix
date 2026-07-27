function zmx-select --description 'Fuzzy-find, preview, or create a zmx session'
    if not command -q zmx; or not command -q fzf
        return 1
    end

    # Build a human-friendly listing of active sessions from `zmx list` output,
    # stripping the `key=value` prefixes zmx emits per tab-separated field.
    set -l display
    for line in (zmx list 2>/dev/null)
        set -l fields (string split \t -- $line)
        set -l name (string replace -r '^.*name=' '' -- $fields[1])
        set -l pid (string replace -r '^.*pid=' '' -- $fields[2])
        set -l clients (string replace -r '^.*clients=' '' -- $fields[3])
        set -l dir (string replace -r '^.*start_dir=' '' -- $fields[5])
        set -a display (printf '%-20s  pid:%-8s  clients:%-2s  %s' $name $pid $clients $dir)
    end

    set -l output (begin
        test -n "$display"; and printf '%s\n' $display
    end | fzf \
        --print-query \
        --expect=ctrl-n \
        --height=80% \
        --reverse \
        --prompt="zmx> " \
        --header="Enter: select | Ctrl-N: create new" \
        --preview='zmx history {1}' \
        --preview-window=right:60%:follow | string collect)
    set -l rc $status

    # --print-query --expect always yields: line 1 = query, line 2 = key, line 3 = selection.
    set -l lines (string split \n -- $output)
    set -l query $lines[1]
    set -l key $lines[2]
    set -l selected $lines[3]

    set -l session_name
    if test "$key" = ctrl-n; and test -n "$query"
        set session_name $query
    else if test $rc -eq 0; and test -n "$selected"
        set session_name (string split -f1 ' ' -- (string trim -- $selected))
    else if test -n "$query"
        set session_name $query
    else
        return 130
    end

    zmx attach $session_name
end
