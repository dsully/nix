function rm --wraps rip
    set -l cmd /bin/rm

    if type -q trash
        set cmd trash
    else if type -q rip
        set cmd rip
    end

    if test $cmd = /bin/rm
        /bin/rm $argv
        return
    end

    if contains -- --version $argv
        $cmd --version
        return
    end

    set -l rm_flags
    set -l trash_flags
    set -l trash_paths
    set -l cloud_paths
    set -l in_flags 1

    for arg in $argv
        if test $in_flags -eq 1; and string match -q -- '-*' $arg
            if test $arg = --
                set in_flags 0
                continue
            end
            set -a rm_flags $arg
            string match -qr -- '^-[rf]+$' $arg; or set -a trash_flags $arg
            continue
        end

        # /usr/bin/trash fails on File Provider paths such as Box with NSCocoaErrorDomain 513.
        if string match -q -- (path resolve -- $HOME)"/Library/CloudStorage/*" (path resolve -- $arg)
            set -a cloud_paths $arg
        else
            set -a trash_paths $arg
        end
    end

    set -l code 0

    if set -q cloud_paths[1]
        /bin/rm $rm_flags -- $cloud_paths; or set code $status
    end

    if set -q trash_paths[1]; or not set -q cloud_paths[1]
        $cmd $trash_flags $trash_paths; or set code $status
    end

    return $code
end
