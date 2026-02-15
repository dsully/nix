if status is-interactive; and command -q leadr
    set -gx LEADR_CONFIG_DIR $XDG_CONFIG_HOME/leadr

    # command leadr --fish | source
end
