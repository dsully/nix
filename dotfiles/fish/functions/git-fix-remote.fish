function git-fix-remote --description "Repair the current branch's upstream / rewrite its remote https URL to ssh"
    set -l branch (git name-rev --name-only HEAD)
    set -l remote_name (git config branch.$branch.remote)

    # Remote set to a full URL rather than a name, e.g. after "gh pr checkout".
    if string match -qr 'git@github\.com:(?<owner>.*)/(?<repo>.*)\.git' -- $remote_name
        set -l new_remote_name "$owner-$repo"

        git remote add $new_remote_name $remote_name 2>/dev/null

        set remote_name $new_remote_name

        git fetch $remote_name
        or return
        git branch --set-upstream-to=$remote_name/$branch
        return
    end

    set -l url (git remote get-url $remote_name)

    if string match -qr 'https://github\.com/(?<repo>.*)' -- $url
        set -l new_url "git@github.com:$repo"
        echo "Changing URL of remote '$remote_name':"
        printf '\tfrom:\t%s\n' $url
        printf '\tto:\t%s\n' $new_url
        git remote set-url $remote_name $new_url
    else
        echo "URL of remote '$remote_name' is already set to:"
        printf '\t%s\n' $url
    end
end
