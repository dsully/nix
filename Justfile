# nix shell nixpkgs#just nixpkgs#nh
# just switch

export NIX_OPTIONS := "nix-command flakes"
export NIXPKGS_ALLOW_UNFREE := "1"
export NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM := "1"
export NIX_CONFIG := "experimental-features = " + NIX_OPTIONS

#

NH := if `command -v nh 2>/dev/null || true` != "" { "nh" } else { "nix run nixpkgs#nh --" }
SM := if `command -v system-manager 2>/dev/null || true` != "" { "system-manager" } else { "nix run github:numtide/system-manager --" }

# This list
default:
    @just --list

# Install Nix using the Determinate Systems installer
[group('nix')]
install-determinate:
    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

# Install Lix (Nix fork)
[group('nix')]
install-lix:
    curl -sSf -L https://install.lix.systems/lix | sh -s -- install

# https://github.com/maximbaz/dotfiles/blob/cafb7a9f773fc8297b97f64fefe1c97b2efb58f0/justfile#L13
# https://github.com/yonzilch/yonos/blob/5736df79d4f045bc518c99cd4b10fb5cddb264dd/Justfile#L75

# Build Darwin or Linux configuration
[group('desktop')]
[linux]
system +args="":
    @{{ SM }} switch --flake '.#$HOSTNAME' --sudo {{ args }}
    @/bin/rm -f result

[macos]
system +args="":
    @{{ NH }} darwin switch --ask . {{ args }}

# Switch Home Manager Configuration
[group('desktop')]
switch +args="":
    {{ NH }} home switch --ask -b backup . {{ args }}

# Update all the flake inputs
[group('nix')]
up:
    @nix flake update

# List all generations of the system profile
[group('nix')]
history:
    @nix profile history

# Open a nix shell with the flake
[group('nix')]
repl:
    @nix repl -f flake:nixpkgs

# Garbage collect all unused nix store entries

alias clean := gc

[group('nix')]
gc:
    /usr/bin/sudo --preserve-env=PATH $(which nh) clean all --no-gcroots --optimise

# Format the nix files in this repo

alias format := fmt

[group('nix')]
fmt:
    @alejandra .
    @deadnix .
    @statix check

# Fetch a source using nix-init (via nurl)

# Usage: just init-from-url https://github.com/anistark/feluda
[group('nix')]
init-from-url URL:
    #!/usr/bin/env bash
    set -euo pipefail

    # Extract the last path component from the URL
    LAST_COMPONENT=$(echo "{{ URL }}" | sed -E 's|.*/([^/]+)/?$|\1|')

    # Remove any trailing .git if present
    LAST_COMPONENT=${LAST_COMPONENT%.git}

    # Create the output filename
    OUTPUT_FILE=packages/"${LAST_COMPONENT}.nix"

    # Run nix-init with the specified parameters
    nix-init -n 'builtins.getFlake "nixpkgs"' -u "{{ URL }}" "${OUTPUT_FILE}"

    # Add useFetchCargoVendor = true; to the file
    sed -i '/cargoHash = ".*";/a \    useFetchCargoVendor = true;' "${OUTPUT_FILE}"

# https://github.com/stefanzweifel/git-auto-commit-action

[group('git')]
commit:
    @git commit -m "chore: update lockfile and versions"
