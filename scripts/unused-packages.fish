#!/usr/bin/env -S fish --no-config
# List packages/ entries whose name is never referenced from Nix code outside packages/.
# Exits 1 if any are unused.

cd (status dirname)/..

# shortcut: a text scan, not an eval (Linux configs use IFD, so cross-system eval needs a remote builder); prose mentions count as references.
set files (git ls-files --cached --others --exclude-standard -- '*.nix' ':!packages/')
set unused

for path in packages/*.nix packages/*/default.nix
    set name (string replace -r '^packages/(.*?)(/default)?\.nix$' '$1' $path)

    # Matches my.pkgs.<name>, perSystem.self.<name>, inherit lists and `with my.pkgs; [ <name> ]`,
    # but not "<name>" strings, <name>-suffixed words, or `<name> =` definitions.
    set pattern '(?:(?<=pkgs\.|self\.|upstream\.)|(?<![\w"./-]))\Q'$name'\E(?![\w"-])(?!\s*=)'

    rg -NP --no-filename --color=never $pattern $files | string match -qvr '^\s*#'
    or set -a unused $name
end

if set -q unused[1]
    printf '%s\n' $unused
    exit 1
end

echo "All packages are referenced." >&2
