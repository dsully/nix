set shell := ["fish", "-c"]

export HOSTNAME := `hostname`
export NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM := "1"
export NIX_CONFIG := "experimental-features = nix-command flakes"

default:
    @just --list

# system:
#     #!/usr/bin/env bash
#     if [ "{{ os() }}" == "linux" ]; then
#         sudo --preserve-env=PATH env nix run 'github:numtide/system-manager' -- switch --flake '.#default'
#     elif [ "{{ os() }}" == "macos" ]; then
#         just _install-nix-darwin
#     else
#         echo "Unsupported OS: {{ os() }}"
#     fi

# Build Darwin or Linux configuration
system:
    #!/usr/bin/env bash
    if [ "{{ os() }}" == "linux" ]; then
        #export TYPE=system-manager

        if ! command -v nh 2>&1 >/dev/null; then
            @nix run nixpkgs#nh -- home switch --update --ask .
        else
            @sudo env "PATH=$PATH" system-manager switch --flake .
        fi
    elif [ "{{ os() }}" == "macos" ]; then
        if ! command -v nh 2>&1 >/dev/null; then
            @nix run nixpkgs#nh -- darwin switch --update --ask .
        else
            @nh darwin switch --update --ask .
        fi
    else
        echo "Unsupported OS: {{ os() }}"
    fi

# Switch Home Manager Configuration
[group('desktop')]
switch:
    @nh home switch --ask .

# Update all the flake inputs
[group('nix')]
up:
    nix flake update

# List all generations of the system profile
[group('nix')]
history:
    nix profile history

# Open a nix shell with the flake
[group('nix')]
repl:
    nix repl -f flake:nixpkgs

# Garbage collect all unused nix store entries

alias clean := gc

[group('nix')]
gc:
    @nh clean all

# Format the nix files in this repo

alias format := fmt

[group('nix')]
fmt:
    @alejandra .
    @deadnix .
    @statix check
