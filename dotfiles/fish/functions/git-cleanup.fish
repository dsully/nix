function git-cleanup --description "Delete local branches whose upstream is gone, with their worktrees"
    set -l main_worktree (git worktree list --porcelain | head -1 | string replace -r '^worktree ' '')

    for branch in (git for-each-ref --format='%(refname:short)' refs/heads)
        set -l upstream_track (git branch --list $branch --format='%(upstream:track)')
        test "$upstream_track" = "[gone]"
        or continue

        set -l worktree_path (git branch --list $branch --format='%(worktreepath)')
        if test -n "$worktree_path"
            if test "$worktree_path" = "$main_worktree"
                echo "Skipping $branch: checked out in main worktree at $worktree_path" >&2
                continue
            end

            # Match branch -D: gone branches are cleanup targets, including linked worktrees.
            git worktree remove --force $worktree_path
            or continue
        end

        git branch -D $branch
    end
end
