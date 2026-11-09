function just --wraps=just
    if not isatty stderr; or set -q PI_CODING_AGENT; or set -q JUST_NO_OSC
        command just $argv
        return
    end

    set -l title just
    set -q argv[1]; and set title "just: $argv"

    printf '\e]2;%s\e\\' $title >&2
    printf '\e]7501;state=working:app=just\e\\' >&2

    command just $argv
    set -l rc $status

    if test $rc -eq 0
        printf '\e]7501;state=done:app=just\e\\' >&2
    else
        set -l msg (printf 'exit %d' $rc | base64)
        printf '\e]7501;state=error:app=just:msg=%s\e\\' $msg >&2
    end

    return $rc
end
