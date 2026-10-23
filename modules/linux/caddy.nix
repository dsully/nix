{
  mkSystemModule,
  config,
  my,
  lib,
  ...
}: let
  cfg = config.modules.system.caddy;

  inherit (my.pkgs) caddy-custom caddy-visualizer;

  caddyConfigDir = "/etc/caddy";
  caddyDataDir = "/var/lib/caddy";
  # Each host's Caddyfile writes its access log here as a literal path. Change
  # this and the per-host Caddyfiles go stale.
  caddyLogDir = "/var/log/caddy";

  # Each host's Caddyfile names these literally: `admin unix/<socket>` and
  # `import <dir>/sites.caddy`. The visualizer reaches Caddy through both.
  adminSocket = "/run/caddy/admin.sock";
  managedDir = "${caddyDataDir}/manager";

  # Cloudflare DNS-01 token for the *.sully.org wildcard cert. Lives on tmpfs
  # so it is re-fetched (never persisted) on every boot. Caddy reads it via the
  # {file.*} placeholder in the Caddyfile.
  cloudflareTokenPath = "/run/secrets/caddy/cloudflare-token";
  linodeTokenPath = "/run/secrets/caddy/linode-token";
in
  mkSystemModule {
    name = "caddy";
    default = false;

    extraOptions = {
      caddyfile = lib.mkOption {
        type = lib.types.path;
        description = ''
          Caddyfile source. The Cloudflare token is available at
          {file.${cloudflareTokenPath}}, and the log directory is ${caddyLogDir}.
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

      visualizer = {
        enable = lib.mkEnableOption ''
          caddy-visualizer. Put ADMIN_INITIAL_PASSWORD in
          /var/lib/caddy-visualizer/bootstrap.env for the first start, then
          remove it
        '';

        listen = lib.mkOption {
          type = lib.types.str;
          description = "Address the plain-HTTP UI binds to.";
        };

        port = lib.mkOption {
          type = lib.types.port;
          default = 3000;
        };
      };
    };

    config = {
      modules.system.opnix = {
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
          source = cfg.caddyfile;
          replaceExisting = true;
        };

        systemPackages = [caddy-custom];
      };

      systemd = {
        tmpfiles.rules =
          [
            "d ${caddyDataDir} 0750 caddy caddy -"
            "d ${caddyLogDir} 0750 caddy caddy -"
          ]
          # Caddy fails to start if the imported file is missing.
          ++ lib.optionals cfg.visualizer.enable [
            "d ${managedDir} 0750 caddy caddy -"
            "f ${managedDir}/sites.caddy 0640 caddy caddy -"
          ];

        services.caddy-visualizer = lib.mkIf cfg.visualizer.enable {
          enable = true;
          wantedBy = ["system-manager.target"];
          description = "Caddy Visualizer";
          documentation = ["https://github.com/dree007/caddy-visualizer"];
          wants = ["network-online.target"];
          after = ["network-online.target" "tailscaled.service" "caddy.service"];
          environment = {
            ADMIN_USERNAME = config.system.userName;
            ALLOW_INSECURE_LAN_HTTP = "true";
            CADDY_ACCESS_LOG_FILE = "${caddyLogDir}/access.log";
            CADDY_ADMIN_URL = "unix://${adminSocket}";
            CADDY_MAIN_CADDYFILE = "${caddyConfigDir}/Caddyfile";
            CADDY_MANAGED_DIR = managedDir;
            DATABASE_PATH = "/var/lib/caddy-visualizer/caddy-visualizer.db";
            HOSTNAME = cfg.visualizer.listen;
            PORT = toString cfg.visualizer.port;
          };
          # Runs as caddy: it already controls Caddy through the admin socket.
          serviceConfig = {
            EnvironmentFile = "-/var/lib/caddy-visualizer/bootstrap.env";
            ExecStart = lib.getExe caddy-visualizer;
            Group = "caddy";
            NoNewPrivileges = true;
            PrivateTmp = true;
            ProtectSystem = "strict";
            ReadWritePaths = managedDir;
            # Binding a tailnet address fails until tailscale0 is up.
            Restart = "always";
            RestartSec = "5s";
            StateDirectory = "caddy-visualizer";
            User = "caddy";
          };
        };

        services.caddy = {
          enable = true;
          wantedBy = ["system-manager.target"];
          description = "Caddy web server";
          documentation = ["https://caddyserver.com/docs/"];
          wants = ["network-online.target" "opnix-secrets.service"];
          after = ["network-online.target" "opnix-secrets.service"];
          reloadTriggers = [config.environment.etc."caddy/Caddyfile".source];
          serviceConfig = {
            AmbientCapabilities = "CAP_NET_BIND_SERVICE";
            ExecReload = "${lib.getExe caddy-custom} reload --config ${caddyConfigDir}/Caddyfile --force";
            ExecStart = "${lib.getExe caddy-custom} run --config ${caddyConfigDir}/Caddyfile --environ";
            ExecStartPre = "${lib.getExe caddy-custom} validate --config ${caddyConfigDir}/Caddyfile";
            Group = "caddy";
            LimitNOFILE = 1048576;
            PrivateTmp = true;
            ProtectSystem = "full";
            ReadWritePaths = "${caddyDataDir} ${caddyLogDir}";
            RuntimeDirectory = "caddy";
            TimeoutStopSec = "5s";
            Type = "notify";
            User = "caddy";
          };
        };
      };
    };
  }
