function pi-computer-use --description "Enable pi-computer-use in this repository's .pi/settings.json"
    set -l root (git rev-parse --show-toplevel 2>/dev/null)
    or begin
        echo "pi-computer-use: not in a git repository" >&2
        return 1
    end

    set -l settings $root/.pi/settings.json
    mkdir -p $root/.pi
    test -s $settings; or echo '{}' >$settings

    # autoload=false makes this a delta over the personal entry (extensions = [] in modules/ai/pi/pi.nix),
    # so it reuses the global install instead of installing a copy into .pi/npm.
    set -l entry '{"source":"npm:@injaneity/pi-computer-use","autoload":false,"extensions":["+extensions/computer-use.ts"]}'
    set -l tmp (mktemp)

    if jq --argjson e $entry '.packages = ([(.packages // [])[] | select((.source? // .) != $e.source)] + [$e])' $settings >$tmp
        mv $tmp $settings
        echo "pi-computer-use enabled in $settings; /reload or restart pi."
    else
        rm -f $tmp
        return 1
    end
end
