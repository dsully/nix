function git-put --wraps "git checkout" --description "Force-create/reset a branch, preserving its upstream"
    set -l remote_branch $argv[2]

    if test -z "$remote_branch"
        set remote_branch (git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null)
    end

    set -l target $argv[1]
    test -n "$target"
    or set target master

    git checkout -B $target
    or return

    if test -n "$remote_branch"
        git branch --set-upstream-to $remote_branch
    end
end
