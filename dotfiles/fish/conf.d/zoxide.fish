# modules/cli/zoxide.nix runs `zoxide init fish`, which defines __zoxide_z and __zoxide_zi.
if status is-interactive; and command -q zoxide
    alias z=__zoxide_z
    alias zi=__zoxide_zi
end
