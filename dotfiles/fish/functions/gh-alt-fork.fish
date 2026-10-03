function gh-alt-fork --description "Fork and clone a GitHub repo as the alt account: gh-alt-fork <owner/repo | https://github.com/owner/repo>"

    # Token comes from $GH_ALT_TOKEN, else from `gh auth token --user $GH_ALT_USER`.
    set -l key ~/.ssh/gh-alt
    set -q GH_ALT_KEY; and set key $GH_ALT_KEY

    set -l upstream (string replace -r '^(https://github\.com/|git@github\.com:)' '' -- $argv[1] | string replace -r '(\.git)?/?$' '')
    if test (count $argv) -ne 1; or not string match -qr '^[\w.-]+/[\w.-]+$' -- $upstream
        echo "usage: gh-alt-fork <owner/repo | https://github.com/owner/repo>" >&2
        return 2
    end

    set -l name (string split -f2 / $upstream)
    set -l ssh "ssh -i $key -o IdentitiesOnly=yes"

    if set -q GH_ALT_TOKEN
        set -fx GH_TOKEN $GH_ALT_TOKEN
    else
        set -fx GH_TOKEN (command gh auth token --user $GH_ALT_USER); or return 1
    end

    # `command gh` skips the 1Password gh wrapper, which ignores GH_TOKEN and prompts.
    set -l id (command gh api user --jq '.login, (.name // .login), "\(.id)+\(.login)@users.noreply.github.com"'); or return 1
    set -l login $id[1]

    # The fork --clone step also sets upstream as the gh default repo.
    command gh repo fork $upstream --clone --remote-name origin -- --config core.sshCommand=$ssh; or return 1

    # gh picks the clone protocol from its global config; force SSH so pushes use the alt key.
    git -C $name remote set-url origin git@github.com:$login/$name.git
    git -C $name remote set-url upstream git@github.com:$upstream.git
    git -C $name config user.name $id[2]
    git -C $name config user.email $id[3]
    git -C $name config branch.(git -C $name branch --show-current).rebase true

    git -C $name remote -v
end
