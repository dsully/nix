function __launchctl_service_help
    echo "Usage: service [command] [service_name]"
    echo ""
    echo "Commands:"
    echo "  start         Start a service"
    echo "  stop          Stop a service"
    echo "  restart       Restart a service"
    echo "  status        Show service status"
    echo "  enable        Enable a service to start on boot"
    echo "  disable       Disable a service from starting on boot"
    echo "  list          List all services"
    echo "  reload        Reload service configuration"
    echo "  help          Show this help message"
end

function __format_service_status
    set -l pid $argv[1]

    if test -z "$pid"
        echo "inactive (dead)"
    else if test "$pid" = -
        echo "inactive (waiting)"
    else
        echo "active (running) since "(ps -p $pid -o lstart=)
    end
end

function __get_plist_path
    set -l service_name $argv[1]
    set -l paths \
        ~/Library/LaunchAgents \
        /Library/LaunchAgents \
        /Library/LaunchDaemons \
        /System/Library/LaunchAgents \
        /System/Library/LaunchDaemons

    for path in $paths
        if test -f "$path/$service_name.plist"
            echo "$path/$service_name.plist"
            return 0
        end
    end
    return 1
end

# LaunchAgents run in the user's GUI domain; only daemons need the root system domain.
function __launchctl_domain
    switch $argv[1]
        case '*/LaunchDaemons/*'
            echo system
        case '*'
            echo gui/(id -u)
    end
end

function systemctl --description 'Wraps launchctl'

    if test (count $argv) -lt 1
        __launchctl_service_help
        return 1
    end

    set -l blue (set_color blue)
    set -l green (set_color green)
    set -l red (set_color red)
    set -l reset (set_color normal)
    set -l yellow (set_color yellow)

    set -l command $argv[1]
    set -l service_name $argv[2]

    if contains -- $command start stop restart reload status enable disable
        if test -z "$service_name"
            echo "Error: Service name required"
            return 1
        end
    end

    set -l plist_path
    set -l domain
    set -l sudo

    if contains -- $command start stop enable disable
        set plist_path (__get_plist_path $service_name)
        or begin
            echo "Error: Service $service_name not found"
            return 1
        end

        set domain (__launchctl_domain $plist_path)

        if test "$domain" = system
            set sudo sudo
        end
    end

    switch $command
        case start
            $sudo launchctl bootstrap $domain $plist_path
            $sudo launchctl kickstart "$domain/$service_name"
            echo "Started $service_name"

        case stop
            $sudo launchctl bootout "$domain/$service_name"
            echo "Stopped $service_name"

        case restart reload
            systemctl stop $service_name
            sleep 1
            systemctl start $service_name

        case status
            set -l pid (launchctl list | awk -v label=$service_name '$3 == label {print $1}')
            echo "$service_name - "(__format_service_status $pid)

        case enable
            $sudo launchctl enable "$domain/$service_name"
            echo "Enabled $service_name"

        case disable
            $sudo launchctl disable "$domain/$service_name"
            echo "Disabled $service_name"

        case list
            # Get the raw output and skip the header line
            launchctl list | tail -n +2 | while read -l pid exit_code label

                # Skip empty lines or lines without a label
                if test -z "$label"; or string match -qr '^(application\.|com\.apple)' -- "$label"
                    continue
                end

                if test "$pid" != -
                    if string match -qr '^\d+$' -- "$pid"
                        set status_color $green
                        set status_text "active (running)"
                    else
                        set status_color $red
                        set status_text "inactive (dead)"
                    end
                else
                    set status_color $yellow
                    set status_text "inactive (waiting)"
                end

                printf "%-45s %s%s%s %s%s%s\n" \
                    $label \
                    $blue loaded $reset \
                    $status_color $status_text $reset
            end | sort

        case help
            __launchctl_service_help

        case '*'
            echo "Unknown command: $command"
            __launchctl_service_help
            return 1
    end
end

# Enable command completion
complete -c systemctl -f -a "start stop restart status enable disable list reload help"
complete -c systemctl -f -n "__fish_seen_subcommand_from start stop restart status enable disable reload" -a "(launchctl list | awk '{print \$3}')"
