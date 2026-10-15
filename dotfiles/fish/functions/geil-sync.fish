function geil-sync --description 'Sync geil with the git repos under a path' --argument-names root
    test -n "$root"; or set root $PWD
    set root (path resolve $root)

    set -l known (geil info | string replace -rf '^\s+- "(.*)"$' '$1')
    set -l found (fd -HI --prune -t d '^\.git$' $root | path dirname | sort)

    set -l new
    for repo in $found
        contains -- $repo $known; or set -a new $repo
    end

    set -l gone
    for repo in (string match -- "$root/*" $known) (string match -- $root $known)
        test -d $repo/.git; or set -a gone $repo
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
