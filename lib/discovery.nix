# Convention-driven directory discovery for flake.nix. packages/ and
# modules/home/ are laid out so the flake never has to list their contents by
# hand: drop a file or directory in, and it appears in the matching output.
{lib}: let
  # { <name without .nix> = <path>; } for every entry of `dir`, minus `exclude`.
  # Non-.nix files (patches, scripts living beside a package) are skipped, and
  # `dirs` controls whether subdirectories count as entries.
  entries = {
    dir,
    exclude ? [],
    dirs ? true,
  }:
    lib.pipe (builtins.readDir dir) [
      (lib.filterAttrs (
        name: type:
          !(builtins.elem name exclude)
          && (
            (type == "regular" && lib.hasSuffix ".nix" name)
            || (dirs && type == "directory")
          )
      ))
      (lib.mapAttrs' (name: _:
        lib.nameValuePair
        (lib.removeSuffix ".nix" name)
        (dir + "/${name}")))
    ];
in rec {
  # Package definitions, passed to callPackage by flake.nix.
  packagePaths = entries {dir = ../packages;};

  # Everything listed in configs/default.nix is already imported by dsully.nix;
  # this attrset exposes the whole set for per-host opt-in.
  homeConfigs = entries {
    dir = ../modules/home/configs;
    exclude = ["default.nix"];
  };

  # Public home modules. colors.nix and dotfiles.nix are imported directly by
  # dsully.nix, so they are internal and stay out. The ai/ config is surfaced
  # here as a module because consumers import it on its own.
  homeModules =
    entries {
      dir = ../modules/home;
      exclude = ["colors.nix" "dotfiles.nix"];
      dirs = false;
    }
    // {
      ai = ../modules/home/configs/ai;
      configs = homeConfigs;
    };
}
