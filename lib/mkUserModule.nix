# mkUserModule — creates a capability module with a per-user enable option.
#
# Each module declares an enable option under `modules.users.<user>.<name>`.
# The same module file is evaluated twice, selected by the `userModuleTarget`
# specialArg:
#
#   "system": inside nix-darwin / system-manager. `system`, `casks`, and `user`
#             apply once when any user enables the module. `home` is ignored.
#   "home":   inside the standalone home-manager config of user `homeUser`.
#             `home` (and enabled parts) apply at the top level. `system`,
#             `casks`, and `user` are ignored.
#
# In both targets the outer module's `config` is the config of the current
# evaluation: the home-manager config inside `home`, the system config inside
# `system`.
#
# Signature: { name, system?, casks?, home?, user?, extraOptions?, requires?, parts? } -> module
#
# Fields:
#
#   name:         Module name. Creates `modules.users.<user>.<name>.enable` option.
#
#   system:       (optional) System-level config applied once when any user enables
#                 the module. Static attrset, or a function ({ enabledUsers } ->
#                 attrset). Must be cross-platform — darwin-only options need a
#                 forPlatform { darwin = ...; } wrap.
#
#   casks:        (optional) Homebrew casks to install on darwin when any user
#                 enables the module.
#
#   home:         (optional) Home-manager config. Attrset, or a function
#                 ({ cfg, lib, username, userCfg } -> attrset). The function's
#                 top-level attribute names must not depend on cfg/userCfg.
#
#   homeOptions:  (optional) Home-manager option declarations (e.g. `fishSecrets`)
#                 that other modules write to. Declared in the "home" target
#                 whether or not the module is enabled.
#
#   user:         (optional) Per-user account config, merged into
#                 users.users.<username>. Attrset or ({ cfg, username } -> attrset).
#
#   extraOptions: (optional) Custom per-user option declarations (attrset of mkOption defs).
#
#   default:      (optional, default true) Default of the enable option. Use
#                 false for modules only some hosts enable. A user with
#                 defaultEnable = false (see extraHomeUsers in hostLib.nix)
#                 gets false regardless.
#
#   requires:     (optional) Module names to auto-enable (mkDefault) for every
#                 user who enables this module.
#
#   needs:        (optional) Module names that must also be enabled for `home`
#                 to apply. Unlike `requires`, it does not enable them.
#
#   parts:        (optional) Sub-features with their own enable option under
#                 modules.users.<user>.<name>.<partName>. Each part may set
#                 default (bool, default true), system, home, extraOptions. A
#                 part's home function receives { cfg, parentCfg, lib, username, userCfg }.
{
  name,
  system ? {},
  casks ? [],
  home ? {},
  homeOptions ? {},
  user ? {},
  extraOptions ? {},
  default ? true,
  requires ? [],
  needs ? [],
  parts ? {},
}: let
  isUserFn = builtins.isFunction user;
  hasUser = user != {} || isUserFn;
  hasParts = parts != {};
  applyIfFn = value: args:
    if builtins.isFunction value
    then value args
    else value;
in {
  imports = [
    (
      {
        config,
        lib,
        forPlatform,
        userModuleTarget,
        ...
      } @ args: let
        partOptions =
          lib.mapAttrs (
            partName: partDef:
              {
                enable = lib.mkOption {
                  type = lib.types.bool;
                  default = partDef.default or true;
                  description = "Enable ${name} ${partName} sub-feature.";
                };
              }
              // (partDef.extraOptions or {})
          )
          parts;

        systemConfig = let
          enabledUsers = lib.filterAttrs (_: u: u.${name}.enable) config.modules.users;
        in
          lib.mkIf (enabledUsers != {}) (
            lib.mkMerge (
              [(applyIfFn system {inherit enabledUsers;})]
              ++ lib.optional (casks != []) (forPlatform {
                darwin = {homebrew.casks = casks;};
              })
              ++ lib.optionals hasParts (
                lib.mapAttrsToList (
                  partName: partDef: let
                    partUsers = lib.filterAttrs (_: u: u.${name}.${partName}.enable) enabledUsers;
                  in
                    lib.mkIf (partUsers != {}) (applyIfFn (partDef.system or {}) {inherit partUsers;})
                )
                parts
              )
              ++ lib.optional hasUser {
                users.users =
                  lib.mapAttrs (
                    username: userCfg:
                      applyIfFn user {
                        cfg = userCfg.${name};
                        inherit username;
                      }
                  )
                  enabledUsers;
              }
            )
          );

        homeConfig = let
          username = args.homeUser;
          userCfg = config.modules.users.${username};
          cfg = userCfg.${name};
          partHomes =
            lib.mapAttrsToList (
              partName: partDef:
                lib.mkIf cfg.${partName}.enable (applyIfFn (partDef.home or {}) {
                  cfg = cfg.${partName};
                  parentCfg = cfg;
                  inherit lib username userCfg;
                })
            )
            parts;
        in
          lib.mkIf (cfg.enable && lib.all (n: userCfg.${n}.enable) needs) (lib.mkMerge ([(applyIfFn home {inherit cfg lib username userCfg;})] ++ partHomes));
      in {
        options =
          lib.optionalAttrs (userModuleTarget == "home") homeOptions
          // {
            modules.users = lib.mkOption {
              type = lib.types.attrsOf (
                lib.types.submodule (
                  {config, ...}: {
                    options.${name} =
                      {
                        enable = lib.mkOption {
                          type = lib.types.bool;
                          default = default && config.defaultEnable;
                          description = "Enable ${name}.";
                        };
                      }
                      // extraOptions
                      // partOptions;

                    # Resolved inside the submodule so there is no read/write cycle
                    # on the top-level modules.users option.
                    config = lib.mkIf (requires != [] && config.${name}.enable) (
                      lib.genAttrs requires (_: {
                        enable = lib.mkDefault true;
                      })
                    );
                  }
                )
              );
            };
          };

        config =
          if userModuleTarget == "home"
          then homeConfig
          else systemConfig;
      }
    )
  ];
}
