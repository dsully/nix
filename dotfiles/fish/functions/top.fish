function top --wraps=btop

    if command -q btop
        command btop $argv
    else if command -q htop
        command htop $argv
    else
        switch $OS
            case Darwin
                command top -s 2 -ocpu -Otime $argv
            case Linux
                command top $argv
        end
    end
end
