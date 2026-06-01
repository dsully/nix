function mas --wraps mas --description "Wrap MAS to output Nix style"

    if test "$argv[1]" = list
        set -l query (string lower -- "$argv[2]")

        if test -z "$query"
            echo "masApps = {"
        end

        command mas list | while read -l line
            set -l app_id (string match -r '^\s*(\d+)' -- $line)[2]
            set -l app_name (string match -r '^\s*\d+\s+(.*?)\s+\(' -- $line)[2]

            set -l lower_app_name (string lower -- "$app_name")

            if test -z "$app_id"; or test -z "$app_name"
                continue
            end

            if test -z "$query"; or string match -q "*$query*" -- "$lower_app_name"
                echo "\"$app_name\" = $app_id;"
            end
        end

        if test -z "$query"
            echo "};"
        end

        return
    end

    command mas $argv
end
