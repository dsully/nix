function tower -d "Open Tower for directory (default: Git root)"
    set -l paths (fallback $argv (git rev-parse --show-toplevel))

    if test (uname) = Linux
        if not set -q SSH_CLIENT_MOUNT
            echo "SSH_CLIENT_MOUNT is not set"
            return 1
        end

        set -l remotePath (string join " " -- $paths)

        if string match -q "/home*" $remotePath
            set remotePath "$SSH_CLIENT_MOUNT$remotePath"
        end

        printf "%s" "-a Tower $remotePath" | nc -q1 localhost 2226
        return
    end

    command /usr/bin/open -a Tower $paths
end
