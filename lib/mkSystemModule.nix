# mkSystemModule — creates a host-level module with an enable option under
# `modules.system.<name>`.
#
# Unlike mkUserModule (per-user opt-in), this is host-wide infrastructure. In
# the "home" userModuleTarget it contributes nothing, so system modules may
# live in cross-platform module directories.
#
# Signature: { name, default?, config?, extraOptions? } -> module
#
# Fields:
#
#   name:         Module name. Creates `modules.system.<name>.enable` option.
#
#   default:      (optional, default true) Default of the enable option. Use
#                 false for services that only some hosts run.
#
#   config:       (optional) System config applied when enabled. Static
#                 attrset, or a function ({ config, cfg, lib } -> attrset).
#                 `cfg` is `modules.system.<name>`.
#
#   extraOptions: (optional) Custom options under `modules.system.<name>`.
#
# Usage:
#
#   { mkSystemModule, pkgs, ... }:
#   mkSystemModule {
#     name = "caddy";
#     default = false;
#     extraOptions.caddyfile = lib.mkOption { type = lib.types.path; };
#     config = { cfg, ... }: { environment.etc."caddy/Caddyfile".source = cfg.caddyfile; };
#   }
#
#   # Opt in / out per host:
#   modules.system.caddy = { enable = true; caddyfile = ./Caddyfile; };
{
  name,
  default ? true,
  config ? {},
  extraOptions ? {},
}: let
  moduleConfig = config;
in {
  imports = [
    (
      {
        config,
        lib,
        userModuleTarget,
        ...
      }: let
        cfg = config.modules.system.${name};
      in
        lib.optionalAttrs (userModuleTarget != "home") {
          options.modules.system.${name} =
            {
              enable = lib.mkOption {
                type = lib.types.bool;
                inherit default;
                description = "Enable ${name} system module.";
              };
            }
            // extraOptions;

          config = lib.mkIf cfg.enable (
            if builtins.isFunction moduleConfig
            then moduleConfig {inherit config cfg lib;}
            else moduleConfig
          );
        }
    )
  ];
}
