# Re-apply home-manager session variables in running shells when activation bumps the
# universal __hm_sess_vars_gen (the new hm-session-vars.fish path). __hm_sess_vars_file
# records what this shell applied; it is exported so children inherit it.

if not set -q __HM_SESS_VARS_SOURCED; and set -q __hm_sess_vars_gen
    # config.fish is about to source the current generation.
    set -gx __hm_sess_vars_file $__hm_sess_vars_gen
end

status is-interactive; or return

function __hm_sess_vars_reload --on-variable __hm_sess_vars_gen
    set -l new $__hm_sess_vars_gen
    test -f "$new"; or return
    test "$new" = "$__hm_sess_vars_file"; and return

    # Lines like `set -gx PATH 'a:b'(...)"$PATH"` prepend to themselves; the rest are literals.
    set -l old $__hm_sess_vars_file

    if test -f "$old"

        set -l keep (string match -rg '^set -gx (\S+) ' <$new)

        for line in (string match -r '^set -gx \S+ .*' <$old)

            set -l name (string match -rg '^set -gx (\S+) ' -- $line)

            if string match -q -- "*\"\$$name\"*" $line
                set -q $name; or continue
                set -l entries (string join : -- $$name | string split :)

                for p in (string match -rg "^set -gx \S+ '([^']*)'" -- $line | string split -n :)
                    set -l i (contains -i -- $p $entries); and set -e entries[$i]
                end

                set -gx $name (string join : -- $entries)

            else if not contains -- $name $keep
                set -eg $name
            end
        end
    end

    set -e __HM_SESS_VARS_SOURCED
    source $new

    for name in (string match -rg '^set -gx (\S+) .*"\$\1"' <$new)
        set -l seen

        for e in (string join : -- $$name | string split :)
            contains -- $e $seen; or set -a seen $e
        end

        test -n "$name"; and set -gx $name (string join : -- $seen)
    end

    set -gx __hm_sess_vars_file $new
end
