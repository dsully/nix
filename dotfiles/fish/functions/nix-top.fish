function nix-top --description 'Largest Nix store paths: nix-top [-n N] [-c|--closure] [-g|--group] [ROOT...]'
    argparse h/help 'n/count=!_validate_int --min 1' c/closure g/group -- $argv
    or return

    if set -q _flag_help
        echo 'Usage: nix-top [-n N] [-c|--closure] [-g|--group] [ROOT...]'
        echo '  ROOT...        limit to the closure of these paths (default: whole store)'
        echo '  -n, --count N  rows to show (default 20)'
        echo '  -c, --closure  rank by closure size instead of own NAR size'
        echo '  -g, --group    sum NAR size per package name across versions'
        return 0
    end

    if set -q _flag_closure; and set -q _flag_group
        echo 'nix-top: --closure and --group cannot be combined' >&2
        return 1
    end

    set -l count (set -q _flag_count; and echo $_flag_count; or echo 20)
    set -l scope --all

    test (count $argv) -gt 0; and set scope -r $argv

    set -l info_args --json $scope
    set -l key narSize

    if set -q _flag_closure
        set -a info_args -S
        set key closureSize
    end

    # Lix/older Nix emit a list of objects; newer Nix emits an object keyed by path.
    nix path-info $info_args 2>/dev/null | jq -r \
        --arg key $key --argjson n $count --arg group (set -q _flag_group; and echo 1; or echo '') '
        def human: . as $b | ["B","K","M","G","T"] as $u
            | reduce range(4) as $_ ([$b, 0]; if .[0] >= 1024 then [.[0] / 1024, .[1] + 1] else . end)
            | "\((.[0] * 10 | round) / 10)\($u[.[1]])";
        def pname: sub("^/nix/store/[^-]+-"; "") | sub("[.]drv$"; "") | sub("-[^a-zA-Z].*$"; "");
        (if type == "array" then . else to_entries | map(.value + {path: .key}) end)
        | map(select(.[$key] != null))
        | if $group != "" then
            group_by(.path | pname)
            | map({size: (map(.narSize) | add), label: "\(.[0].path | pname) (\(length) paths)"})
          else
            map({size: .[$key], label: .path})
          end
        | sort_by(-.size) | .[:$n][]
        | "\(.size | human)\t\(.label)"' | column -t -s \t
end
