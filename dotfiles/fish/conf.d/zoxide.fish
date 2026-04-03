# Modified from https://github.com/braun-steven/dotfiles/blob/main/fish/.config/fish/config.fish
if status is-interactive; and command -q zoxide

    # pwd based on the value of _ZO_RESOLVE_SYMLINKS.
    function __zoxide_pwd
        builtin pwd -L
    end

    # A copy of fish's internal cd function. This makes it possible to use
    # `alias cd=z` without causing an infinite loop.
    if ! builtin functions --query __zoxide_cd_internal
        if builtin functions --query cd
            builtin functions --copy cd __zoxide_cd_internal
        else
            alias __zoxide_cd_internal='builtin cd'
        end
    end

    # cd + custom logic based on the value of _ZO_ECHO.
    function __zoxide_cd
        __zoxide_cd_internal $argv
    end

    # Jump to a directory using only keywords.
    function __zoxide_z
        set -l argc (count $argv)
        if test $argc -eq 0
            __zoxide_cd $HOME
        else if test "$argv" = -
            __zoxide_cd -
        else if test $argc -eq 1 -a -d $argv[1]
            __zoxide_cd $argv[1]
        else if set -l result (string replace --regex $__zoxide_z_prefix_regex '' $argv[-1]); and test -n "$result"
            __zoxide_cd $result
        else
            set -l result (command zoxide query --exclude (__zoxide_pwd) -- $argv)
            and __zoxide_cd $result
        end
    end

    # Initialize hook to add new entries to the database.
    function __zoxide_hook --on-variable PWD
        test -z "$fish_private_mode"
        and command zoxide add -- (__zoxide_pwd)
    end

    # Jump to a directory using interactive search.
    function __zoxide_zi
        set -l result (command zoxide query --interactive -- $argv)
        and __zoxide_cd $result
    end

    alias z=__zoxide_z
    alias zi=__zoxide_zi

end
