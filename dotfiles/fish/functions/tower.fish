function tower -d "Open Tower for directory (default: Git root)"
    set -l paths (fallback $argv (git rev-parse --show-toplevel))

    if test (uname) = Linux
        if not set -q SSH_CLIENT_HOME
            echo "SSH_CLIENT_HOME is not set"
            return 1
        end

        set -l remotePath (string join " " -- $paths)

        if string match -q "/home*" $remotePath
            set remotePath "$SSH_CLIENT_HOME/$SSH_CLIENT_MOUNT$remotePath"
        end

        printf "%s" $remotePath | nc -q1 localhost 2226
        return
    end

    command /usr/bin/open -a Tower $paths
end
