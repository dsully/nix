function __python_virtualenv --description "Auto activate/deactivate Python virtualenvs"

    # Defer to direnv when it's managing VIRTUAL_ENV.
    if set -q DIRENV_DIR; and set -q VIRTUAL_ENV
        return 0
    end

    # Walk up directory tree looking for .venv or venv (nearest wins).
    set -l dir $PWD
    set -l venv_path ""

    while test "$dir" != /
        if test -f "$dir/.venv/bin/activate.fish"
            set venv_path "$dir/$candidate"
            break
        end
        test -n "$venv_path"; and break
        set dir (path dirname $dir)
    end

    if test -n "$venv_path"
        # Already active, nothing to do.
        if test "$VIRTUAL_ENV" = "$venv_path"
            return 0
        end

        # Deactivate any previously auto-activated venv before switching.
        if set -q __auto_venv; and functions -q deactivate
            deactivate
        end

        source "$venv_path/bin/activate.fish" &>/dev/null
        set -g __auto_venv $venv_path

    else if set -q __auto_venv
        # We left the venv's directory tree. Deactivate only if we auto-activated.
        if functions -q deactivate
            deactivate
        end
        set -e __auto_venv
    end

    # If VIRTUAL_ENV is set without __auto_venv, user activated manually. Don't touch it.
end
