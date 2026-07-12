function mtr --description 'mtr-style traceroute via ttl (needs root for raw sockets)' --wraps ttl
    # Resolve to the /nix/store path so the passwordless-sudo rule matches.
    sudo (path resolve (command -v ttl)) $argv
end
