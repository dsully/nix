function glr -d "git sync: fetch, autorebase and trim branches that have been merged."

    set current (command git branch --show-current)

    echo "Pulling ..."
    command git -c gc.autoDetach=false fetch --all --prune

    # Loop through all remotes and attempt fast-forward
    for r in (command git remote)
        do-ff $current $r
    end

    # Fast-forward the current branch if it has an upstream
    if test -n "$current"
        set upstream (command git branch --list --format "%(upstream:short)" "$current")
        if test -n "$upstream"
            echo "Fast-forward branch '$current' to '$upstream'"
            command git merge --ff-only "$upstream"; or true
        end
    end
end

function do-ff
    set current $argv[1]
    set input_remote $argv[2]
    set -l local remote upstream

    git branch --list --format "%(refname:short):%(upstream:remotename):%(upstream:short)" | while read -l local remote upstream

        if test "$local" = "$current"
            continue
        end

        if test "$remote" != "$input_remote"
            continue
        end

        if test -z "$upstream"
            continue
        end

        if not git show-ref --quiet "$upstream"
            continue
        end

        if not git merge-base --is-ancestor "$local" "$upstream"
            echo "Not possible to fast-forward branch '$local' to '$upstream'"
            continue
        end

        git branch --force "$local" "$upstream"
    end
end
