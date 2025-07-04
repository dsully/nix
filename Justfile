set shell := ["fish", "-c"]

export NIXPKGS_ALLOW_UNFREE := "1"
export NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM := "1"
export NIX_CONFIG := "experimental-features = nix-command flakes"
cache := env("CACHE", "1")
force := env("FORCE", "0")
update := env("UPDATE", "1")

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
    @/usr/bin/sudo --preserve-env=PATH (which nh) clean all

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

# Build a package or all packages
# Usage: just build-packages [package]

# https://github.com/stefanzweifel/git-auto-commit-action
build-packages +packages='all':
    #!/usr/bin/env fish

    set pattern
    set failed

    if test "{{ packages }}" != "all"
        set glob (string join "," {{ packages }})
        set pattern --glob="*{$glob}*"
    end

    function success
        set -l pkg $argv[1]

        echo -n (set_color green) "success!" (set_color normal)

        if test "{{ cache }}" -eq 1
            echo -s (set_color cyan) "Pushing to cachix.." (set_color normal)

            command nix path-info .#$pkg | cachix push --compression-method xz --compression-level 6 dsully > /dev/null 2>&1
        end
    end

    set files (rg -l --color=never --sort path --type nix $pattern "src = " packages/)

    command mkdir -p build-results

    # Build each package and log results
    for file in $files

        # Extract homepage URL from the file
        set -l url (rg 'homepage = "([^"]+)"' $file -o --replace '$1' --no-line-number --color=never)
        set -l pkg (rg 'pname = "([^"]+)"' $file -o --max-count=1 --replace '$1' --no-line-number --color=never)

        if test $pkg = "chromium" -o $pkg = "pyrefly" -a "{{ force }}" -eq 0

            continue
        end

        echo -n "Checking $pkg: "

        set -l building "building..."

        if test "{{ update }}" -eq 1

            # Get the new hash using nurl
            set -l nurl_output (nurl --json $url 2>&1)
            set -l nurl_status $status

            if test $nurl_status -ne 0
                echo -n (set_color yellow) "  " (set_color normal)
                echo "Could not extract homepage URL from $file"
                echo
                continue
            end

            # Extract just the JSON part from nurl output (everything after the last space)
            set -l json_part (echo "$nurl_output" | awk '{print $NF}')

            # Extract the hash and rev from nurl JSON output
            set -l new_hash (echo "$json_part" | jq -r '.args.hash' 2>/dev/null)
            set -l new_rev (echo "$json_part" | jq -r '.args.rev' 2>/dev/null)

            if test -z "$new_hash"; or test -z "$new_rev"
                echo
                echo -n (set_color red) "  " (set_color normal)
                echo "Could not extract hash/rev from nurl output for $file"
                echo "  Debug: nurl output was: $nurl_output"
                echo
                continue
            end

            # Get current hash and rev from file
            set -l current_hash (rg '\bhash = "([^"]+)"' $file -o --replace '$1' --no-line-number --color=never)
            set -l current_rev (rg '\brev = "([^"]+)"' $file -o --replace '$1' --no-line-number --color=never)

            if test -z "$current_rev" -o -z "$new_rev"
                echo -s (set_color red) "current_rev or new_rev was empty!." (set_color normal)
                continue
            end

            if test "$new_hash" = "$current_hash" -a "$new_rev" = "$current_rev" -a "{{ force }}" -eq 0
                echo -s (set_color cyan) "up to date." (set_color normal)
                continue
            end

            if test -n "$current_hash" -a -n "$new_hash"
                sd --fixed-strings "$current_hash" "$new_hash" "$file"
            end

            if test -n "$current_rev" -a -n "$new_rev"
                sd --fixed-strings "$current_rev" "$new_rev" "$file"
            end

            # Clear cargo/vendor hashes
            sd 'cargoHash = "[^"]*"' 'cargoHash = ""' "$file"
            sd "vendorHash = .*" "vendorHash = \"$new_hash\";" "$file"

            echo -n "building for new hash ..."

            nix build .#$pkg --no-link > build-results/$pkg.log 2>&1

            set new_hash (grep "got:" build-results/$pkg.log | awk '{print $2}')

            if string match -qr 'sha256' -- "$new_hash"
                echo
                echo "  Got a new package hash: $new_hash"

                sd "cargoHash = .*" "cargoHash = \"$new_hash\";" "$file"
                sd "vendorHash = .*" "vendorHash = \"$new_hash\";" "$file"

                set building "  Rebuilding..."
            end
        end

        echo -n $building

        if nix build .#$pkg --no-link > build-results/$pkg.log 2>&1
            success $pkg
        else
            echo -n -s (set_color red) " failed" (set_color normal) "! See build-results/$pkg.log for details."
            set failed true
        end

        echo
    end

    if test -z $failed
        command rm -rf build-results
    end

# List all available packages in the repository
list-packages:
    #!/usr/bin/env fish

    echo "Available packages in the repository:"
    echo
    fd --type f --extension nix --base-directory packages packages/| sed 's/\.nix//' | sed 's/\/.*//' | sort -u
