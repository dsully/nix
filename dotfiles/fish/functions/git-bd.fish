function git-bd --wraps "git branch" --description "Delete branches along with any attached worktrees"
    argparse f/force -- $argv
    or return 2

    if test (count $argv) -eq 0
        echo "usage: git-bd [-f|--force] <branch>..." >&2
        return 2
    end

    for branch in $argv
        set -l worktree (git branch --list $branch --format='%(worktreepath)')
        if test -n "$worktree"
            if not set -q _flag_force
                read -l -P "Warning: branch '$branch' is attached to worktree '$worktree'. Delete both? [y/N] " reply
                string match -qri '^y(es)?$' -- $reply
                or continue
            end
            git worktree remove --force $worktree
            or return
        end

        git branch -D -- $branch
        or return
    end
end
