if status is-interactive
    set -l __fish_session_open_bind ctrl-s

    if not set -q __fish_session_name;
        bind -M insert $__fish_session_open_bind fish-session
        bind -M default $__fish_session_open_bind fish-session
    end

    # Inside managed fish-session shells, keep Ctrl-D as delete-char so it
    # does not close the whole session shell when the commandline is empty.
    if set -q __fish_session_name
        bind -M insert \cd delete-char
        bind -M default \cd delete-char
    end
end
