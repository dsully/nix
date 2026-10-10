function __fzf_grep --description 'Ripgrep and open files with fzf'
    argparse 'q/query=' 't/type=' -- $argv

    __fzf_picker_args

    set -f rg_cmd rg --column --line-number --no-binary --no-heading --sort=path

    if test -n "$_flag_type"
        set -a rg_cmd --type $_flag_type
    end

    # rg exits 2 on an invalid regex; retry the query as a literal string.
    set -f reload "$rg_cmd {q} 2>/dev/null; test \$status -eq 2; and $rg_cmd --fixed-strings {q}; or true"

    set -f fzf_args $PICKER_ARGS
    set -a fzf_args --bind "change:reload:$reload"
    set -a fzf_args --delimiter :
    set -a fzf_args --preview "__fzf_preview_file_content --path {1} --line {2} --column {3}"
    set -a fzf_args --print0
    set -a fzf_args --no-sort
    # rg does the matching; fzf filtering would drop regex matches.
    set -a fzf_args --disabled

    if test -n "$_flag_query"
        set -a fzf_args --query "$_flag_query" --bind "start:reload:$reload"
    else
        # Start empty instead of listing every line; stay open for typing.
        set -a fzf_args --no-exit-0
    end

    set -l selected_files (command fzf $fzf_args </dev/null | string split0)

    for s in $pipestatus
        if test $s -ne 0
            commandline --function repaint
            return $s
        end
    end

    # No files selected
    test (count $selected_files) -eq 0; and return 0

    # Single result: open at the matched line.
    # Multiple results: open files in buffers (nvim can't position per-file).
    if test (count $selected_files) -eq 1
        set -l parts (string split -f 1,2 -- ':' $selected_files[1])
        set -l file $parts[1]
        set -l line $parts[2]

        commandline "nvim +$line "(string escape -- $file)
    else
        set -l files

        for element in $selected_files
            set -a files (string split -f 1 -- ':' $element)
        end

        commandline "nvim "(string escape -- $files | string join " ")
    end
end
