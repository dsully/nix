{
  config,
  flake,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.caddy;

  inherit (flake.packages.x86_64-linux) caddy-custom;

  caddyConfigDir = "/etc/caddy";
  caddyDataDir = "/var/lib/caddy";
  caddyLogDir = "/var/log/caddy";

  # Cloudflare DNS-01 token for the *.sully.org wildcard cert. Lives on tmpfs
  # so it is re-fetched (never persisted) on every boot. Caddy reads it via the
  # {file.*} placeholder in the Caddyfile.
  cloudflareTokenPath = "/run/secrets/caddy/cloudflare-token";
  linodeTokenPath = "/run/secrets/caddy/linod-token";
in {
  imports = [./opnix.nix];

  options.services.caddy = {
    enable = lib.mkEnableOption "Caddy with an opnix-managed Cloudflare DNS token";

    caddyfile = lib.mkOption {
      type = lib.types.path;
      description = ''
        Caddyfile source. @logDir@ is substituted with the log directory, and
        the Cloudflare token is available at {file.${cloudflareTokenPath}}.
      '';
    };

    cloudflareReference = lib.mkOption {
      type = lib.types.str;
      default = "op://Services/Cloudflare DNS Token/credential";
      description = "1Password reference for the Cloudflare DNS API token.";
    };

    linodeReference = lib.mkOption {
      type = lib.types.str;
      default = "op://Services/Linode DNS/credential";
      description = "1Password reference for the Linode DNS API token.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.opnix = {
      enable = true;

      secrets = [
        {
          path = cloudflareTokenPath;
          reference = cfg.cloudflareReference;
          owner = "caddy";
          group = "caddy";
          mode = "0400";
        }

        {
          path = linodeTokenPath;
          reference = cfg.linodeReference;
          owner = "caddy";
          group = "caddy";
          mode = "0400";
        }
      ];
    };

    environment = {
      etc."caddy/Caddyfile" = {
        source = pkgs.replaceVars cfg.caddyfile {logDir = caddyLogDir;};
        replaceExisting = true;
      };

      systemPackages = [caddy-custom];
    };

    systemd.tmpfiles.rules = [
      "d ${caddyDataDir} 0750 caddy caddy -"
      "d ${caddyLogDir} 0750 caddy caddy -"
    ];

    systemd.services.caddy = {
      enable = true;
      wantedBy = ["system-manager.target"];
      description = "Caddy web server";
      documentation = ["https://caddyserver.com/docs/"];
      wants = ["network-online.target" "opnix-secrets.service"];
      after = ["network-online.target" "opnix-secrets.service"];
      serviceConfig = {
        AmbientCapabilities = "CAP_NET_BIND_SERVICE";
        ExecReload = "${lib.getExe caddy-custom} reload --config ${caddyConfigDir}/Caddyfile --force";
        ExecStart = "${lib.getExe caddy-custom} run --config ${caddyConfigDir}/Caddyfile --resume --environ";
        ExecStartPre = "${lib.getExe caddy-custom} validate --config ${caddyConfigDir}/Caddyfile";
        Group = "caddy";
        LimitNOFILE = 1048576;
        PrivateTmp = true;
        ProtectSystem = "full";
        ReadWritePaths = "${caddyDataDir} ${caddyLogDir}";
        TimeoutStopSec = "5s";
        Type = "notify";
        User = "caddy";
      };
    };
  };
}
