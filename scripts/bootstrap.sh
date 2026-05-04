#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
OS="$(uname -s)"

DEFAULT_REPO_DIR="${HOME}/.config/nix"
REPO_DIR="$DEFAULT_REPO_DIR"
TARGET_HOST=""
SKIP_HOSTNAME=false

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
NIX_EXPERIMENTAL_FEATURES_CONFIG='experimental-features = nix-command flakes'

export XDG_CONFIG_HOME
export XDG_DATA_HOME
export XDG_STATE_HOME
export NIX_CONFIG="${NIX_EXPERIMENTAL_FEATURES_CONFIG}${NIX_CONFIG:+$'\n'"$NIX_CONFIG"}"

export NIX_INSTALLER_EXTRA_CONF="trusted-users = @admin @wheel ${USER}
use-xdg-base-directories = true"
export NIX_INSTALLER_FORCE=true
export NIX_INSTALLER_ENABLE_FLAKES=true
export NIX_INSTALLER_NO_CONFIRM=true
export NIX_PATH="${XDG_STATE_HOME}/nix/defexpr/channels"

log() {
    printf '%s\n' "$*"
}

warn() {
    printf 'warning: %s\n' "$*" >&2
}

die() {
    printf 'error: %s\n' "$*" >&2
    exit 1
}

on_error() {
    local exit_code=$?
    local line_no=$1
    local command=$2
    printf 'error: command failed at line %s: %s\n' "$line_no" "$command" >&2
    exit "$exit_code"
}

trap 'on_error "$LINENO" "$BASH_COMMAND"' ERR

usage() {
    cat << 'EOF'
Usage: bootstrap.sh [options]

Options:
  --host <name>       Target host to validate and activate.
  --repo-dir <path>   Path to the nix repo checkout.
  --skip-hostname     Do not rename the machine during bootstrap.
  --help              Show this help text.
EOF
}

parse_args() {
    while (($# > 0)); do
        case "$1" in
            --host)
                (($# >= 2)) || die "--host requires a value"
                TARGET_HOST="$2"
                shift 2
                ;;
            --repo-dir)
                (($# >= 2)) || die "--repo-dir requires a value"
                REPO_DIR="$2"
                shift 2
                ;;
            --skip-hostname)
                SKIP_HOSTNAME=true
                shift
                ;;
            --help | -h)
                usage
                exit 0
                ;;
            *)
                die "unknown argument: $1"
                ;;
        esac
    done
}

ensure_xdg_dirs() {
    mkdir -p -- "$XDG_CONFIG_HOME" "$XDG_DATA_HOME" "$XDG_STATE_HOME"
}

ensure_repo_dir_parent() {
    mkdir -p -- "$(dirname -- "$REPO_DIR")"
}

supports_host_on_current_os() {
    local host="$1"

    case "$OS" in
        Darwin)
            [[ -f "$SCRIPT_DIR/hosts/${host}/darwin-configuration.nix" ]]
            ;;
        Linux)
            [[ -f "$SCRIPT_DIR/hosts/${host}/system-configuration.nix" ]]
            ;;
        *)
            return 1
            ;;
    esac
}

list_supported_hosts() {
    local host_dir
    local host_name
    local supported=()

    shopt -s nullglob
    for host_dir in "$SCRIPT_DIR"/hosts/*; do
        [[ -d $host_dir ]] || continue
        host_name="$(basename -- "$host_dir")"
        if supports_host_on_current_os "$host_name"; then
            supported+=("$host_name")
        fi
    done
    shopt -u nullglob

    ((${#supported[@]} > 0)) || die "no supported hosts found for ${OS}"
    printf '%s\n' "${supported[@]}"
}

host_exists() {
    local host="$1"
    [[ -f "$SCRIPT_DIR/hosts/${host}/options.nix" ]]
}

validate_target_host() {
    [[ -n $TARGET_HOST ]] || die "target host is not set"
    host_exists "$TARGET_HOST" || die "unknown host: ${TARGET_HOST}"
    supports_host_on_current_os "$TARGET_HOST" || die "host ${TARGET_HOST} is not supported on ${OS}"
}

prompt_for_host() {
    local current_host="$1"
    local supported_hosts
    local default_host
    local prompt
    local input

    supported_hosts="$(list_supported_hosts | tr '\n' ' ' | sed 's/ $//')"

    if [[ -n $current_host ]] && supports_host_on_current_os "$current_host"; then
        default_host="$current_host"
    else
        default_host="$(list_supported_hosts | head -n 1)"
    fi

    prompt="Target host [${default_host}] (${supported_hosts}): "
    read -r -p "$prompt" input
    TARGET_HOST="${input:-$default_host}"
}

current_host_name() {
    case "$OS" in
        Darwin)
            scutil --get LocalHostName 2> /dev/null || hostname
            ;;
        Linux)
            hostname
            ;;
        *)
            die "unsupported OS: ${OS}"
            ;;
    esac
}

ensure_hostname() {
    local current_host

    current_host="$(current_host_name)"

    if [[ -z $TARGET_HOST ]]; then
        if [[ $OS == "Darwin" ]]; then
            prompt_for_host "$current_host"
        else
            TARGET_HOST="$current_host"
        fi
    fi

    validate_target_host

    if [[ $OS == "Darwin" ]]; then
        if [[ $SKIP_HOSTNAME == true ]]; then
            [[ $TARGET_HOST == "$current_host" ]] || die "--skip-hostname requires current hostname ${current_host} to match target host ${TARGET_HOST}"
            return
        fi

        if [[ $TARGET_HOST != "$current_host" ]]; then
            log "Updating macOS hostname to ${TARGET_HOST}"
            sudo scutil --set HostName "$TARGET_HOST"
            sudo scutil --set LocalHostName "$TARGET_HOST"
            sudo scutil --set ComputerName "$TARGET_HOST"
        else
            log "Hostname already set to ${TARGET_HOST}"
        fi
        return
    fi

    if [[ $SKIP_HOSTNAME == false ]] && [[ $TARGET_HOST != "$current_host" ]]; then
        die "Linux bootstrap will not rename the host; current hostname is ${current_host}, requested ${TARGET_HOST}"
    fi
}

ensure_git() {
    if command -v git > /dev/null 2>&1; then
        return
    fi

    [[ $OS == "Darwin" ]] || die "git is required but not installed"

    log "Installing Apple Command Line Tools"
    xcode-select --install > /dev/null 2>&1 || true
    read -r -p "Press Enter after Command Line Tools installation completes."

    command -v git > /dev/null 2>&1 || die "git is still unavailable after Command Line Tools installation"
}

ensure_nix() {
    if command -v nix > /dev/null 2>&1; then
        log "Using nix: $(command -v nix)"
        return
    fi

    log "Installing Lix"
    /usr/bin/curl -sSf -L https://install.lix.systems/lix | sh -s -- install

    if [[ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
        # shellcheck disable=SC1091
        source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
    fi

    command -v nix > /dev/null 2>&1 || die "nix is unavailable after installation"
}

ensure_repo() {
    ensure_repo_dir_parent

    if [[ -d "$REPO_DIR/.git" ]]; then
        log "Using existing repo at $REPO_DIR"
        return
    fi

    [[ ! -e $REPO_DIR ]] || die "repo path exists but is not a git checkout: $REPO_DIR"

    log "Cloning nix config to $REPO_DIR"
    git clone git@github.com:dsully/nix.git "$REPO_DIR" || die "failed to clone repo via SSH; ensure GitHub SSH access is configured"
}

ensure_repo_shape() {
    [[ -f "$REPO_DIR/flake.nix" ]] || die "missing flake.nix in repo dir: $REPO_DIR"
    [[ -f "$REPO_DIR/Justfile" ]] || die "missing Justfile in repo dir: $REPO_DIR"
}

run_just() {
    local recipe="$1"
    shift
    nix shell nixpkgs#just --command just --justfile "$REPO_DIR/Justfile" --working-directory "$REPO_DIR" "$recipe" "$@"
}

run_activation() {
    case "$OS" in
        Darwin)
            run_just system
            ;;
        Linux)
            run_just system
            ;;
        *)
            die "unsupported OS: ${OS}"
            ;;
    esac

    run_just switch
}

main() {
    parse_args "$@"
    ensure_xdg_dirs
    ensure_git
    ensure_hostname
    ensure_nix
    ensure_repo
    ensure_repo_shape
    run_activation
    log ""
    log "Bootstrap complete. Restart your terminal to load the new environment."
}

main "$@"
