function git-rg --wraps rg --description "ripgrep with 2 lines of context, piped through delta"
    #
    # Passthrough for machine-readable / plain output; otherwise pipe through delta.
    if contains -- --color=never $argv; or contains -- -l $argv; or contains -- --list $argv
        command rg $argv
        return $status
    end

    command rg --context=2 --json $argv | delta
end
