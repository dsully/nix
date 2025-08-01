set shell := ["fish", "-c"]

export NIXPKGS_ALLOW_UNFREE := "1"
export NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM := "1"
export NIX_CONFIG := "experimental-features = nix-command flakes"

# This list
default:
    @just --list

# Build Darwin or Linux configuration
[group('desktop')]
system:
    #!/usr/bin/env bash
    if [ "{{ os() }}" == "linux" ]; then

        /usr/bin/sudo --preserve-env=PATH $(which system-manager) switch --flake .
        /bin/rm -f result

    elif [ "{{ os() }}" == "macos" ]; then

        nh darwin switch --ask .

    else
        echo "Unsupported OS: {{ os() }}"
    fi

# Switch Home Manager Configuration
[group('desktop')]
switch:
    @nh home switch --ask -b backup .

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
    #!/usr/bin/env bash
    if [ "{{ os() }}" == "linux" ]; then
        /usr/bin/sudo --preserve-env=PATH $(which nh) clean all
    else
        nh clean all
    fi

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
