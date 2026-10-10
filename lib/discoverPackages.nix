# { <name> = <path>; } for every `<dir>/*.nix` file or `<dir>/<name>/` directory.
{lib}: dir:
lib.mapAttrs' (name: _: lib.nameValuePair (lib.removeSuffix ".nix" name) (dir + "/${name}"))
(lib.filterAttrs (name: type: type == "directory" || lib.hasSuffix ".nix" name) (builtins.readDir dir))
