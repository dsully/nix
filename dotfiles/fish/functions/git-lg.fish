function git-lg --wraps "git log" --description "git log as a graph with a compact colored format"
    command git log \
        --graph \
        --format="%C(bold yellow)%h %C(bold blue)%<(18,trunc)%aN %C(bold green)%cd %C(auto)%d %Creset%s" \
        $argv
end
