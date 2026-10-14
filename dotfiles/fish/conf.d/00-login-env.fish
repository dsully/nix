# Login shells rebuild env even if a launcher leaked the exported "already sourced" guards.
if status is-login
    set -e __HM_SESS_VARS_SOURCED

    test -f /etc/fish/setEnvironment.fish; and source /etc/fish/setEnvironment.fish
end
