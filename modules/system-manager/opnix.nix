{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.opnix;

  opnix = inputs.opnix.packages.${pkgs.stdenv.hostPlatform.system}.default;

  opnixConfig = (pkgs.formats.json {}).generate "opnix-secrets.json" {
    inherit (cfg) secrets;
  };
in {
  options.services.opnix = {
    enable = lib.mkEnableOption "opnix 1Password secret retrieval";

    tokenFile = lib.mkOption {
      type = lib.types.str;
      default = "/etc/opnix-token";
      description = ''
        Path to the 1Password service-account token. Bootstrap once on the host
        with: sudo opnix token set
      '';
    };

    outputDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/opnix";
      description = "Working directory opnix writes to and validates as writable.";
    };

    secrets = lib.mkOption {
      default = [];
      description = "Secrets to fetch from 1Password and write to disk.";
      type = lib.types.listOf (lib.types.submodule {
        options = {
          path = lib.mkOption {
            type = lib.types.str;
            description = "Absolute path the secret value is written to (verbatim).";
          };
          reference = lib.mkOption {
            type = lib.types.str;
            example = "op://Vault/Item/field";
            description = "1Password secret reference.";
          };
          owner = lib.mkOption {
            type = lib.types.str;
            default = "root";
          };
          group = lib.mkOption {
            type = lib.types.str;
            default = "root";
          };
          mode = lib.mkOption {
            type = lib.types.str;
            default = "0400";
          };
        };
      });
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.tmpfiles.rules = [
      "d ${cfg.outputDir} 0700 root root -"
    ];

    systemd.services.opnix-secrets = {
      enable = true;
      wantedBy = ["system-manager.target"];
      description = "Fetch secrets from 1Password via opnix";
      wants = ["network-online.target"];
      after = ["network-online.target" "nss-lookup.target"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${opnix}/bin/opnix secret -token-file ${cfg.tokenFile} -config ${opnixConfig} -output ${cfg.outputDir}";
      };
    };
  };
}
