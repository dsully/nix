# modules/system-manager/docker.nix
#
# Declarative Docker management for system-manager hosts. system-manager doesn't
# expose `virtualisation.oci-containers`, so we emit the systemd units by hand,
# mirroring that module's shape: one `docker-<name>` unit per container that runs
# `docker run --rm` in the foreground so systemd owns its lifecycle, logs, and
# restarts.
#
# By default this manages containers on top of an *existing* (e.g. distro-managed)
# daemon via `local.docker.dockerBin`. Set `local.docker.daemon.enable` to have
# Nix own a dockerd + socket instead.
{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.local.docker;

  depUnits = deps: map (d: "docker-${d}.service") deps;

  # Send the foreground container output to a per-name file instead of
  # the journal (and thus /var/log/syslog).
  logConfig = name:
    lib.optionalAttrs (cfg.logDir != null) {
      StandardOutput = "append:${cfg.logDir}/${name}.log";
      StandardError = "append:${cfg.logDir}/${name}.log";
    };

  # The append: target dir must exist before systemd opens the unit's stdout fd,
  # so a separate oneshot creates it and every unit orders after it.
  logDirDeps = lib.optional (cfg.logDir != null) "docker-log-dir.service";

  containerUnit = name: c: let
    ports = lib.concatMap (p: ["-p" p]) c.ports;
    volumes = lib.concatMap (v: ["-v" v]) c.volumes;
    envs = lib.concatLists (lib.mapAttrsToList (k: v: ["-e" "${k}=${v}"]) (cfg.defaultEnvironment // c.environment));
    envFiles = lib.concatMap (f: ["--env-file" f]) c.environmentFiles;

    runArgs = lib.concatStringsSep " " (
      ["run" "--rm" "--name" name]
      ++ c.extraOptions
      ++ ports
      ++ volumes
      ++ envs
      ++ envFiles
      ++ [c.image]
      ++ c.cmd
    );

    deps = depUnits c.dependsOn;
  in {
    "docker-${name}" = {
      enable = true;
      description = "Docker container ${name}";
      requires = ["docker.service"] ++ deps;
      after = ["docker.service" "network-online.target"] ++ logDirDeps ++ deps;
      wants = logDirDeps;
      wantedBy = lib.optional c.autoStart "system-manager.target";

      serviceConfig =
        {
          ExecStartPre =
            ["-${cfg.dockerBin} rm -f ${name}"]
            ++ lib.optional c.pullOnStart "-${cfg.dockerBin} pull ${c.image}";
          ExecStart = "${cfg.dockerBin} ${runArgs}";
          ExecStop = "${cfg.dockerBin} stop ${name}";
          Restart = "always";
          RestartSec = "5s";
          TimeoutStartSec = 0;
        }
        // logConfig name;
    };
  };

  containerModule = _: {
    options = {
      image = lib.mkOption {
        type = lib.types.str;
        description = "Container image reference (e.g. ghcr.io/org/app:latest).";
      };
      ports = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = "Port mappings passed as `-p`.";
      };
      volumes = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = "Bind mounts / volumes passed as `-v`.";
      };
      environment = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = {};
        description = "Environment variables passed as `-e K=V`. Values must be shell-safe; use environmentFiles for secrets or values with spaces.";
      };
      environmentFiles = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = "Env files passed as `--env-file` (e.g. opnix-materialized secrets).";
      };
      cmd = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = "Command / arguments appended after the image.";
      };
      extraOptions = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = "Raw `docker run` flags (e.g. --network host, --privileged, --device, --cap-add, --log-driver none, --init).";
      };
      dependsOn = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = "Other container names this one must start after.";
      };
      pullOnStart = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Run `docker pull` before starting (ignored on failure).";
      };
      autoStart = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Start automatically (wantedBy system-manager.target).";
      };
    };
  };
in {
  options.local.docker = {
    enable = lib.mkEnableOption "declarative Docker container management (on top of an existing daemon)";

    dockerBin = lib.mkOption {
      type = lib.types.str;
      default = "/bin/docker";
      description = "Docker client binary. Defaults to the OS-managed client so it matches the running daemon that owns /var/lib/docker.";
    };

    defaultEnvironment = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = {};
      description = "Environment variables merged into every container; each container's own `environment` wins on conflict.";
    };

    logDir = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = "/var/log/docker";
      description = "Directory for per-container log files (unit output is redirected to <dir>/<name>.log), keeping it out of the journal and /var/log/syslog. Set null to log to the journal instead.";
    };

    containers = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule containerModule);
      default = {};
      description = "Single-container `docker run` units.";
    };

    daemon = {
      enable = lib.mkEnableOption "a Nix-store dockerd + socket (leave off when the OS already manages the daemon)";
      autoStart = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Start dockerd at boot instead of on-demand via docker.socket.";
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      systemd.services = lib.mkMerge (
        lib.mapAttrsToList containerUnit cfg.containers
        ++ lib.optional (cfg.logDir != null) {
          docker-log-dir = {
            enable = true;
            description = "Create Docker log directory ${cfg.logDir}";
            wantedBy = ["system-manager.target"];
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
              ExecStart = "${pkgs.coreutils}/bin/mkdir -p ${cfg.logDir}";
            };
          };
        }
      );

      # copytruncate: the log file is held open by the long-running docker
      # process via systemd's append fd, so rotate in place rather than rename.
      environment.etc = lib.optionalAttrs (cfg.logDir != null) {
        "logrotate.d/docker-containers".text = ''
          ${cfg.logDir}/*.log {
            weekly
            rotate 8
            compress
            delaycompress
            missingok
            notifempty
            copytruncate
          }
        '';
      };
    })

    (lib.mkIf cfg.daemon.enable {
      environment.systemPackages = [pkgs.docker];

      environment.etc."NetworkManager/conf.d/80-unmanaged-docker.conf".text = ''
        # MANAGED BY SYSTEM-MANAGER
        #
        # Docker owns these interfaces. Leaving them unmanaged prevents
        # NetworkManager consumers from chasing short-lived container veth links.
        [keyfile]
        unmanaged-devices=interface-name:docker0;interface-name:br-*;interface-name:veth*
      '';

      systemd.services.docker = {
        enable = true;
        description = "Docker Application Container Engine";
        documentation = ["https://docs.docker.com"];

        requires = ["docker.socket"];
        after = [
          "docker.socket"
          "network-online.target"
        ];
        wantedBy = lib.optional cfg.daemon.autoStart "multi-user.target";

        path = [
          pkgs.docker
          pkgs.iptables
          pkgs.nftables
          pkgs.kmod
          pkgs.containerd
          pkgs.runc
        ];

        serviceConfig = {
          Type = "notify";
          ExecStart = [
            "${pkgs.docker}/bin/dockerd -H fd://"
          ];
          ExecReload = [
            "${pkgs.coreutils}/bin/kill -s HUP $MAINPID"
          ];

          LimitNOFILE = "1048576";
          LimitNPROC = "infinity";
          LimitCORE = "infinity";
          TasksMax = "infinity";
          TimeoutStartSec = 0;
          Restart = "on-failure";
        };
      };

      systemd.sockets.docker = {
        enable = true;
        description = "Docker Socket for the API";
        wantedBy = ["sockets.target"];
        socketConfig = {
          ListenStream = "/run/docker.sock";
          SocketMode = "0660";
          SocketUser = "root";
          SocketGroup = "docker";
          RemoveOnStop = true;
        };
      };
    })
  ];
}
