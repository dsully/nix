export NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM := "1"
export NIX_CONFIG := "experimental-features = nix-command flakes"

default:
    @just --list

############################################################################
#
#  Darwin related commands
#
############################################################################

[group('desktop')]
build:
    @nh darwin build --update .

[group('desktop')]
switch:
    @nh darwin switch --update --ask .

[group('desktop')]
darwin-debug:
    @nh darwin switch --update --ask --verbose .

############################################################################
#
#  nix related commands
#
############################################################################

# Update all the flake inputs
[group('nix')]
up:
    nix flake update

# List all generations of the system profile
[group('nix')]
history:
    nix profile history --profile /nix/var/nix/profiles/system

# Open a nix shell with the flake
[group('nix')]
repl:
    nix repl -f flake:nixpkgs

# remove all generations older than 7 days

# On darwin, you may need to switch to root user to run this command
[group('nix')]
clean:
    sudo nix profile wipe-history --profile /nix/var/nix/profiles/system --older-than 7d

# Garbage collect all unused nix store entries
[group('nix')]
gc:
    @nh clean all

# Format the nix files in this repo
[group('nix')]
fmt:
    @alejandra .
    @deadnix .
    @statix check
