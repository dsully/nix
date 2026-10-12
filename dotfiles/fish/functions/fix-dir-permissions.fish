function fix-dir-permissions --description 'Set directory positions to 755'
    command fd --full-path --type d --exec "chmod 755" $argv
end
