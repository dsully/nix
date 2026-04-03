if status is-interactive

    function __auto_venv --on-variable PWD
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
                        source "$activate_script"
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

    __auto_venv
end
