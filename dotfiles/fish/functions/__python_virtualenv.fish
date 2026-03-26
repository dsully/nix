function __python_virtualenv --description "Auto activate/deactivate Python virtualenvs"

    set -l venv_path ""

    # Check current directory first (nearest .venv wins), then git root as fallback.
    if test -e "$PWD/.venv/bin/activate.fish"
        set venv_path "$PWD/.venv"
    else if git rev-parse --show-toplevel &>/dev/null
        set -l root (git rev-parse --show-toplevel 2>/dev/null)
        if test -e "$root/.venv/bin/activate.fish"
            set venv_path "$root/.venv"
        end
    end

    if test -n "$venv_path" -a "$VIRTUAL_ENV" != "$venv_path"
        # Deactivate any existing venv before activating the new one.
        if test -n "$VIRTUAL_ENV"; and functions -q deactivate
            deactivate
        end
        source "$venv_path/bin/activate.fish" &>/dev/null
    else if test -z "$venv_path" -a -n "$VIRTUAL_ENV"
        if functions -q deactivate
            deactivate
        end
    end
end
