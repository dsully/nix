# Pick a URL, path, hash or address from the visible text of Rex block $argv[1], newest first.
#   enter   copy to the clipboard
#   tab     type it into the pane
#   ctrl-o  open it
set -l block $argv[1]

# Earlier patterns win where matches overlap, so keep the most specific first.
set -l patterns \
    -e '(https?|ftp|file|ssh|git)://[^[:space:]"\'<>()`]+' \
    -e '[[:alnum:]._%+-]+@[[:alnum:].-]+\.[[:alpha:]]{2,}' \
    -e '\b[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\b' \
    -e '\b[0-9]{1,3}(\.[0-9]{1,3}){3}(:[0-9]+)?\b' \
    -e '(~|\.{1,2})?(/[[:alnum:]._@%+=:,~-]+)+/?' \
    -e '[[:alnum:]._-]+(/[[:alnum:]._-]+)+\.[[:alnum:]]+(:[0-9]+){0,2}' \
    -e '\b[0-9a-f]{7,40}\b' \
    -e '#[0-9a-fA-F]{6}\b'

set -l tokens (
    rex capture -b $block |
        rg --only-matching --no-line-number $patterns |
        string replace -r '[.,;:]+$' '' |
        awk 'length($0) > 3 { lines[NR] = $0 } END { for (i = NR; i > 0; i--) if (i in lines && !seen[lines[i]]++) print lines[i] }'
)

if test (count $tokens) -eq 0
    echo "nothing to pick"
    sleep 1
    exit 0
end

set -l result (
    printf '%s\n' $tokens |
        fzf --height 100% --no-border --prompt 'hint> ' --layout reverse --expect tab,ctrl-o \
            --header 'enter copy · tab type into pane · ctrl-o open'
)
or exit 0

set -l choice $result[2]
test -n "$choice"; or exit 0

switch $result[1]
    case tab
        rex send -b $block $choice >/dev/null
    case ctrl-o
        open (string replace -r '^~' $HOME -- $choice)
    case '*'
        printf '%s' $choice | pbcopy
end
