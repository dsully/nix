# mkUser — declares a user: identity plus module enable flags.
#
# Returns { name, module } so host factories can read the username without
# duplication. `module` adapts to the userModuleTarget specialArg:
#
#   "system": sets modules.users.<name> (and the darwin account's home).
#   "home":   sets modules.users.<name> and the home-manager identity
#             (home.username, home.homeDirectory, home.stateVersion).
#
# Signature: { name, stateVersion? } // moduleEnables -> { name, module }
#
# Fields:
#
#   name:         Username.
#
#   stateVersion: (optional, default "26.05") home-manager state version.
#
#   <anything else>: Passed to `modules.users.<name>`. Typically module enable
#                    flags and their options. Every `enable` value is wrapped in
#                    mkDefault, so a host's `userConfig.<name>` can turn a
#                    module off without mkForce.
#
# Usage:
#
#   # modules/users/dsully.nix
#   { mkUser, ... }:
#   mkUser {
#     name = "dsully";
#     stateVersion = "25.05";
#     git.enable = true;
#   }
{
  name,
  stateVersion ? "26.05",
  ...
} @ args: let
  moduleEnables = builtins.removeAttrs args ["name" "stateVersion"];
in {
  inherit name;
  module = {
    forPlatform,
    lib,
    userModuleTarget,
    ...
  }: let
    defaultEnables = lib.mapAttrs (key: value:
      if key == "enable" && builtins.isBool value
      then lib.mkDefault value
      else if lib.isAttrs value && !lib.isDerivation value
      then defaultEnables value
      else value);

    homeDirectory = forPlatform {
      darwin = "/Users/${name}";
      linux = "/home/${name}";
    };
  in {
    config = lib.mkMerge [
      {modules.users.${name} = defaultEnables moduleEnables;}

      (
        if userModuleTarget == "home"
        then {
          home = {
            username = name;
            inherit homeDirectory stateVersion;
          };
          system.userName = name;
        }
        # system-manager has no account management without userborn, so only
        # darwin gets the account entry.
        else forPlatform {darwin = {users.users.${name}.home = homeDirectory;};}
      )
    ];
  };
}
