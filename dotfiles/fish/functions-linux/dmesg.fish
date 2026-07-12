function dmesg --wraps dmesg

    set -l cmd (command -v dmesg)

    if test $USER != root
        command sudo $cmd $argv
    else
        command $cmd $argv
    end
end
