function cdr --description "chdir to the root of a git repo."
    set -l repo (command git rev-parse --git-dir --is-inside-git-dir --is-bare-repository --is-inside-work-tree --short HEAD 2> /dev/null)
    test -n "$repo"; or return

    set -l cd_up_path (command git rev-parse --show-cdup)

    if test -n "$cd_up_path"
        cd $cd_up_path

        echo -e ""
        echo -e "      \e[1m\e[38;5;112m\^V//"
        echo -e "      \e[38;5;184m|\e[37m· ·\e[38;5;184m|      \e[94mI AM GROOT !"
        echo -e "    \e[38;5;112m- \e[38;5;184m\ - /"
        echo -e "     \_| |_/\e[38;5;112m¯"
        echo -e "       \e[38;5;184m\ \\"
        echo -e "     \e[38;5;124m__\e[38;5;184m/\e[38;5;124m_\e[38;5;184m/\e[38;5;124m__"
        echo -e "    |_______|"
        echo -e "     \     /"
        echo -e "      \___/\e[39m\e[00m"
        echo -e ""
    end
end
