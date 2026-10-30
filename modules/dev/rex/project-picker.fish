# Pick a project (a directory holding .git or .jj) and switch to the Rex session already
# open there, or start one.
set -l excludes \
    node_modules .venv target .elixir_ls _build deps dist assets public vendor .sass-cache \
    wp-content tmp cache .next .vinxi .output .react-router .expo opensrc .context

set -l exclude_args
for dir in $excludes
    set -a exclude_args --exclude $dir
end

function list_projects -V exclude_args
    # .git may be a file (worktrees), so match both types and prune at the marker.
    fd --hidden --no-ignore --prune --max-depth 6 --type d --type f \
        $exclude_args '^\.(git|jj)$' $HOME/dev --exec dirname '{}'
    fd --hidden --no-ignore --prune --max-depth 2 --type d --type f \
        '^\.(git|jj)$' $HOME/.config --exec dirname '{}'
end

# Every session with the pwd of each of its terminals. Neither `rex ls` nor session.view
# carries a cwd, so ask each terminal block. list_blocks answers 409 until the script's
# stream is attached to that session.
set -l sessions_lua '
local TERM = "com.superlogical.terminal"
local out = {}
for _, s in ipairs((rex.call("session.list") or {}).sessions or {}) do
    local entry = { session_id = s.session_id, label = s.label, pwds = {} }
    rex.call("session.attach", { session_id = s.session_id })
    local list = rex.call("session.list_blocks", { session_id = s.session_id }) or {}
    for _, b in ipairs(list.blocks or {}) do
        if b.creator_name == TERM then
            local r = rex.call("block.method", { session_id = s.session_id, block_id = b.block_id, method = "pwd" })
            if r and r.pwd then
                table.insert(entry.pwds, r.pwd)
            end
        end
    end
    rex.call("session.detach", { session_id = s.session_id })
    table.insert(out, entry)
end
return out
'

# dir \t label \t session ID, one row per terminal; pwd is a file://host/ URL.
# If listing fails, still pick from the projects, just without the ● marks.
set -l open_rows (
    rex do --json -e $sessions_lua 2>/dev/null |
        jq -r '.[] | .pwds[]? as $pwd | [($pwd | sub("^file://[^/]*"; "")), .label, .session_id] | @tsv' |
        sort -u
)

set -l selection (
    list_projects | sort -u |
        OPEN=(string join \n -- $open_rows) awk -F'\t' -v home=$HOME '
            BEGIN {
                n = split(ENVIRON["OPEN"], rows, "\n")
                for (i = 1; i <= n; i++) { split(rows[i], f, "\t"); if (f[1] != "") label[f[1]] = f[2] }
            }
            {
                shown = $0; sub("^" home, "~", shown)
                if ($0 in label) print "0\t" $0 "\t● " shown "  [" label[$0] "]"
                else print "1\t" $0 "\t  " shown
            }
        ' |
        sort -t \t -k1,1 -s | cut -f2- |
        fzf --height 100% --no-border --delimiter '\t' --with-nth 2 --prompt 'project> ' --no-sort --layout reverse \
            --header '● = already open' \
            --preview 'ls -A {1} | head -60' --preview-window 'right,40%,border-left'
)
or exit 0

set -l dir (string split -f1 \t -- $selection)

for row in $open_rows
    set -l f (string split \t -- $row)
    if test "$f[1]" = "$dir"
        rex do session.select session_id=$f[3] >/dev/null
        exit
    end
end

# The app stays on its current session after `rex new`, so select the new one.
set -l id (rex new (path basename $dir) --cwd $dir --json | jq -r .session_id)
rex do session.select session_id=$id >/dev/null
