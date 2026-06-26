if status is-interactive

    function __auto_venv_walk
        set -l current_venv $VIRTUAL_ENV
        set -l check_dir $PWD
        set -l __venv_names .venv venv env

        while true
            for vp in $__venv_names
                if test -d "$check_dir/$vp"
                    set -l venv_path "$check_dir/$vp"
                    set -l activate_script "$venv_path/bin/activate.fish"

                    if test -f "$activate_script" && test "$current_venv" != "$venv_path"
                        if test -n "$current_venv"
                            # @fish-lsp-disable-next-line 7001
                            deactivate
                        end

                        # Some activate.fish scripts `cd` into bin/ to resolve VIRTUAL_ENV via `pwd`. 
                        # Sourced here, that `cd` leaks into the live shell, so snapshot and restore $PWD.
                        set -l pre_source_pwd $PWD

                        source "$activate_script"

                        if test "$PWD" != "$pre_source_pwd"
                            builtin cd "$pre_source_pwd"
                        end
                    end

                    return
                end
            end

            set -l parent (dirname "$check_dir")

            if test "$parent" = "$HOME"; or test "$check_dir" = /
                break
            end

            set check_dir $parent
        end

        if test -n "$current_venv"
            # @fish-lsp-disable-next-line 7001
            deactivate
        end
    end

    function __auto_venv --on-variable PWD
        # Guard against re-entrancy: deactivate/source can mutate state that
        # re-fires the PWD handler before this call returns, blowing the stack.
        if set -q __auto_venv_running
            return
        end
        set -g __auto_venv_running 1
        __auto_venv_walk
        set -e __auto_venv_running
    end

    __auto_venv
end
