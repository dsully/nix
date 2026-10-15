function geil-sync --description 'Sync geil with the git repos under a path' --argument-names root
    test -n "$root"; or set root $PWD
    set root (path resolve $root)

    set -l known (geil info | string replace -rf '^\s+- "(.*)"$' '$1')
    # -I is needed for fd to report .git dirs; ignored nested repos are dropped below.
    set -l found (fd -HI --prune -t d '^\.git$' $root | path dirname | sort)

    set -l ignored
    for repo in $found
        set -l nested (string match -- "$repo/*" $found)
        set -q nested[1]; and set -a ignored (printf '%s\n' $nested | git -C $repo check-ignore --stdin)
    end

    set -l new
    set -l kept
    for repo in $found
        contains -- $repo $ignored; and continue
        set -a kept $repo
        contains -- $repo $known; or set -a new $repo
    end

    set -l gone
    for repo in (string match -- "$root/*" $known) (string match -- $root $known)
        contains -- $repo $kept; or set -a gone $repo
    end

    if set -q new[1]
        printf 'Adding: %s\n' $new
        geil add $new
    end

    if set -q gone[1]
        printf 'Removing: %s\n' $gone
        geil remove $gone
    end
end
