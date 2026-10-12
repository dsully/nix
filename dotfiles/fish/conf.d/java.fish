if status is-interactive

    if command -q jenv
        fish_add_path --append -g --move $HOME/.jenv/bin $HOME/.jenv/shims

        set -gx JENV_SHELL fish
        set -gx JENV_LOADED 1
        set -e JAVA_HOME
        set -e JDK_HOME
    else
        switch $OS
            case Darwin
                if set -l java_home (/usr/libexec/java_home 2>/dev/null)
                    set -gx JAVA_HOME $java_home
                    fish_add_path --append -g $JAVA_HOME/bin
                end
            case Linux
                if test -e /usr/bin/java
                    set -gx JAVA_HOME (path dirname (path dirname (path resolve /usr/bin/java)))
                end
        end
    end
end
