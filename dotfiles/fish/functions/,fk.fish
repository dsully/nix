function ,fk --description 'Kill a process by name'

    if type -q rip-go
        command rip-go
    else
        __fzf_picker_args

        procs --no-header --color always $argv | fzf $PICKER_ARGS --nth=8 | awk '{print $1}' | while read -l pid
            command kill $pid
        end
    end

    commandline --function repaint
end
