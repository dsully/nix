function prune-launchservices -d "Remove LaunchServices handlers whose app is no longer installed."

    argparse n/dry-run -- $argv; or exit 1

    set -l domain com.apple.LaunchServices/com.apple.launchservices.secure
    set -l tmp (mktemp -d); or exit 1

    defaults export $domain $tmp/current.plist; or exit 1
    plutil -convert json -o $tmp/current.json $tmp/current.plist; or exit 1

    set -l defs '
def roles: [.LSHandlerRoleAll, .LSHandlerRoleViewer, .LSHandlerRoleEditor, .LSHandlerRoleShell]
  | map(select(. != null and . != "-"));
def broken: roles | length > 0 and all(IN($ARGS.positional[]));'

    set -l ids (jq -r "$defs .LSHandlers[] | roles[]" $tmp/current.json --args | sort -u)

    set -l missing (osascript -l JavaScript -e '
ObjC.import("AppKit");
function run(ids) {
  const ws = $.NSWorkspace.sharedWorkspace;
  return ids.filter(id => ws.URLForApplicationWithBundleIdentifier(id).isNil()).join("\n");
}' $ids)

    set -l broken (jq -r "$defs .LSHandlers[] | select(broken)
  | \"\(.LSHandlerContentType // .LSHandlerURLScheme // .LSHandlerContentTag) -> \(roles | join(\", \"))\"" \
    $tmp/current.json --args $missing)

    if test (count $broken) -eq 0
        echo "No broken handlers."
        exit 0
    end

    printf '%s\n' $broken
    set -q _flag_dry_run; and exit 0

    set -l backup ~/.local/state/launchservices/secure-(date +%Y%m%dT%H%M%S).plist
    mkdir -p (path dirname $backup); and cp $tmp/current.plist $backup; or exit 1

    jq "$defs .LSHandlers |= map(select(broken | not))" $tmp/current.json --args $missing >$tmp/pruned.json; or exit 1
    plutil -convert xml1 -o $tmp/pruned.plist $tmp/pruned.json; or exit 1
    defaults import $domain $tmp/pruned.plist; or exit 1

    # lsd caches handlers; it restarts on demand and reads the new prefs.
    killall lsd

    echo "Removed "(count $broken)" handlers. Restore with: defaults import $domain $backup"
end
