# https://gist.github.com/joechrysler/6073741
function __git_parent_branch --argument-names current_branch_name
    git show-branch -a 2>/dev/null \
        | grep '\*' \
        | grep -v $current_branch_name \
        | head -n1 \
        | grep -o '\[[^]]*\]' \
        | head -1 \
        | tr -d '[]'
end

# Open the Pull Request URL for your current directory's branch, merges by default against the current branch's parent
function git-openpr --description 'Open the Pull Request URL for your current directory'
    set current_branch_name (git rev-parse --abbrev-ref HEAD)
    set parent_branch_name (__git_parent_branch $current_branch_name)

    set url (git remote -v | grep 'origin.*fetch' | awk '{print $2}')
    set url (string replace -r 'ssh://[^@]+@' 'https://' $url)
    set url (string replace -r 'git@github.com:' 'https://github.com/' $url | string replace '.git' '')

    set url $url"/compare/$parent_branch_name...$current_branch_name?expand=1"

    echo "Opening $url ..."

    command open --background $url
end
