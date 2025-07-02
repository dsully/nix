#!/bin/sh

set -o errexit # abort on nonzero exitstatus
set -o nounset # abort on unbound variable

OS=$(uname -s)

if [ "$OS" = "Darwin" ]; then

    HOSTNAME=$(scutil --get LocalHostName)

    new_hostname=""
    read -r "new_hostname?Update Hostname [$HOSTNAME]: "

    if test "$new_hostname" != ""; then
        sudo scutil --set HostName "$new_hostname"
        sudo scutil --set LocalHostName "$new_hostname"
        sudo scutil --set ComputerName "$new_hostname"
        HOSTNAME=$new_hostname
    fi

    if [ ! -e /Library/Developer/CommandLineTools/usr/bin/git ]; then

        start "Installing Apple Developer CLI Tools. Press any key when the installation has completed."
        xcode-select --install > /dev/null 2>&1
        read -r "" -sn1
    fi
else
    HOSTNAME=$(hostname)
fi

export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"

export NIX_INSTALLER_EXTRA_CONF="trusted-users = @admin @wheel $USER
use-xdg-base-directories = true"

export NIX_INSTALLER_FORCE=true
export NIX_INSTALLER_ENABLE_FLAKES=true
export NIX_INSTALLER_NO_CONFIRM=true
export NIX_PATH="$XDG_STATE_HOME/nix/defexpr/channels"

mkdir -p "$XDG_CONFIG_HOME" "$XDG_DATA_HOME" "$XDG_STATE_HOME"

if ! command -v nix > /dev/null; then
    echo "Installing lix:"

    curl -sSf -L https://install.lix.systems/lix | sh -s -- install

    # shellcheck disable=SC1091
    . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
else
    echo "Using nix: $(which nix)"
fi

if ! nix shell nixpkgs#gh --command gh auth status; then
    echo "Authenticating to GitHub:"
    nix shell nixpkgs#gh --command gh auth login -p ssh
fi

if [ ! -d "$XDG_CONFIG_HOME"/nix ]; then
    echo "Cloning nix config:"
    nix shell nixpkgs#gh --command gh repo clone dsully/nix $XDG_CONFIG_HOME/nix
fi

cd "$XDG_CONFIG_HOME"/nix

nix shell nixpkgs#just --command just -f $XDG_CONFIG_HOME/nix/Justfile system
nix shell nixpkgs#just --command just -f $XDG_CONFIG_HOME/nix/Justfile switch

# Attach to a TTY for input prompting.
stdin='/dev/null'

if [ "$(ps otty= $$)" != '?' ]; then
    stdin='/dev/tty'
fi

# Set the path for everything else.
export PATH="/run/current-system/sw/bin:/opt/homebrew/bin:$HOME/.cargo/bin:$HOME/.local/bin:$PATH"

# Re-run to generate data.toml.
if chezmoi init --apply --exclude encrypted "$@" "$HOME/dotfiles" < "$stdin"; then

    chezmoi apply --force

    echo ""
    echo "Bootstrap complete! Restart your terminal to load your new environment!"
fi
