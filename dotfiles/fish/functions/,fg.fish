function ,fg --description 'Ripgrep and open files with fzf'
    __fzf_grep $argv

    commandline --function repaint
end
