function ttl --description 'traceroute via ttl (needs root for raw sockets)' --wraps ttl
    sudo (path resolve (command -v ttl)) $argv
end
