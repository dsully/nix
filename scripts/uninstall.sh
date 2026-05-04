#!/usr/bin/env bash

set -Eeuo pipefail

OS="$(uname -s)"
[[ $OS == "Darwin" ]] || {
    printf 'error: this script only supports macOS\n' >&2
    exit 1
}

CONFIRM=false

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
Usage: uninstall.sh [options]

Uninstalls nix-darwin, Lix/Nix, and cleans up all related system state.

Options:
  --yes     Skip confirmation prompt.
  --help    Show this help text.
EOF
}

while (($# > 0)); do
    case "$1" in
        --yes | -y)
            CONFIRM=true
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

if [[ $CONFIRM != true ]]; then
    read -r -p "This will completely remove Nix/Lix and nix-darwin from this system. Continue? [y/N] " answer
    [[ $answer =~ ^[Yy] ]] || {
        log "Aborted."
        exit 0
    }
fi

# 1. Run nix-darwin uninstaller
if command -v nix > /dev/null 2>&1; then
    log "Running nix-darwin uninstaller..."
    sudo nix --extra-experimental-features "nix-command flakes" run nix-darwin#darwin-uninstaller || warn "nix-darwin uninstaller failed or not applicable"
else
    log "Skipping nix-darwin uninstaller (nix not found)"
fi

# 2. Run Lix uninstaller
if [[ -x /nix/lix-installer ]]; then
    log "Running Lix uninstaller..."
    /nix/lix-installer uninstall --no-confirm || warn "Lix uninstaller failed"
else
    log "Skipping Lix uninstaller (/nix/lix-installer not found)"
fi

# 3. Stop and remove launchd services
for plist in org.nixos.nix-daemon org.nixos.darwin-store; do
    plist_path="/Library/LaunchDaemons/${plist}.plist"

    if [[ -f $plist_path ]]; then
        log "Unloading ${plist}..."
        sudo launchctl unload "$plist_path" 2> /dev/null || true
        sudo rm -f "$plist_path"
    fi
done

# 4. Restore shell config files
for f in /etc/zshrc /etc/bashrc /etc/bash.bashrc; do
    backup="${f}.backup-before-nix"

    if [[ -f $backup ]]; then

        log "Restoring ${f} from backup"
        sudo mv "$backup" "$f"

    elif [[ -f $f ]]; then

        if grep -q 'nix-daemon\.sh' "$f" 2> /dev/null; then
            log "Removing Nix stanza from ${f}"
            sudo sed -i '' '/# Nix$/,/# End Nix$/d' "$f"
        fi
    fi
done

# 5. Remove nixbld users and group
if dscl . -read /Groups/nixbld > /dev/null 2>&1; then
    log "Removing nixbld group and users..."

    dscl . -list /Users | grep '^_nixbld' | while IFS= read -r u; do
        sudo dscl . -delete "/Users/$u"
    done

    sudo dscl . -delete /Groups/nixbld
fi

# 6. Clean up system and user files
log "Removing Nix state files..."

sudo rm -rf /etc/nix /var/root/.nix-profile /var/root/.nix-defexpr /var/root/.nix-channels

rm -rf "${HOME}/.nix-profile" "${HOME}/.nix-defexpr" "${HOME}/.nix-channels"

# 7. Remove nix line from /etc/synthetic.conf
if [[ -f /etc/synthetic.conf ]]; then

    if grep -q '^nix$' /etc/synthetic.conf; then

        log "Removing nix entry from /etc/synthetic.conf"
        sudo sed -i '' '/^nix$/d' /etc/synthetic.conf

        # Remove the file if it's now empty
        if [[ ! -s /etc/synthetic.conf ]]; then
            sudo rm -f /etc/synthetic.conf
        fi
    fi
fi

# 8. Remove Nix volume entry from fstab
if grep -q '/nix' /etc/fstab 2> /dev/null; then
    log "Removing /nix entry from /etc/fstab"
    sudo sed -i '' '\|/nix|d' /etc/fstab
fi

# 9. Delete the APFS Nix volume
if diskutil info /nix > /dev/null 2>&1; then
    log "Deleting Nix APFS volume..."
    sudo diskutil apfs deleteVolume /nix || warn "Failed to delete Nix volume — check 'diskutil list' for the volume identifier"
fi

log ""
log "Nix has been uninstalled. Restart your machine to complete cleanup."
