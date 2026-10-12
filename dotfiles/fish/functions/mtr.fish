function mtr --description 'mtr-style traceroute via ttl (needs root for raw sockets)' --wraps ttl
    ttl $argv
end
