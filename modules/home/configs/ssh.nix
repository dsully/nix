{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (config.home) homeDirectory;
  inherit (config.system) hostName;

  remote_forwards = [
    {
      bind.port = 2224;
      host.address = "localhost";
      host.port = 2224;
    }
    {
      bind.port = 2225;
      host.address = "localhost";
      host.port = 2225;
    }
    {
      bind.port = 2226;
      host.address = "localhost";
      host.port = 2226;
    }
  ];
in {
  programs.ssh = {
    enable = true;

    enableDefaultConfig = false;

    settings = lib.mkMerge [
      {
        "*" = {
          AddKeysToAgent = "yes";
          Compression = true;
          ControlMaster = "auto";
          ControlPath = "~/.ssh/sockets/%r@%h-%p";
          ControlPersist = "10m";
          ForwardAgent = lib.mkDefault true;
          ServerAliveInterval = 10;
          IdentityAgent = "SSH_AUTH_SOCK";
          UseKeychain = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin "yes";
          SendEnv = "COLORTERM TERM_PROGRAM TERM_PROGRAM_VERSION";
          SetEnv = {
            SSH_CLIENT_HOME = homeDirectory;
            SSH_CLIENT_MOUNT = "/Volumes";
            SSH_CLIENT_OS = "Darwin";
          };

        };

        "github.com" = {
          User = "git";
          HostName = "github.com.";
          IdentitiesOnly = true;
          ControlMaster = "no";
          ControlPersist = "no";
        };

        "er" = {
          HostName = "172.104.194.233";
          ControlMaster = "no";
          ControlPersist = "no";
        };

        "ca" = {
          HostName = "192.46.222.69";
          ControlMaster = "no";
          ControlPersist = "no";
        };

        "tnt" = {
          HostName = "172.236.14.101";
          ControlMaster = "no";
          ControlPersist = "no";
        };
      }

      (lib.mkIf (hostName != "friday") {
        "sisyphus" = {
          HostName = "10.0.0.135";
          User = "pi";
        };

        "unifi gateway 10.0.0.1" = {
          HostName = "10.0.0.1";
          User = "root";
          IdentityFile = "${homeDirectory}/.ssh/id_rsa";
          LocalForward = [
            {
              bind.port = 27017;
              host.address = "127.0.0.1";
              host.port = 27117;
            }
          ];
        };

        "nvr" = {
          User = "root";
          HostName = "10.0.0.2";
          IdentityFile = "${homeDirectory}/.ssh/id_rsa";
        };

        "switch" = {
          HostName = "10.0.0.3";
          User = "ubnt";
          IdentityFile = "${homeDirectory}/.ssh/id_rsa";
        };
      })

      (lib.mkIf (hostName != "jarvis") {
        "jarvis" = {
          HostName = "10.0.0.97";
        };
      })

      (lib.mkIf (hostName == "jarvis")
        {
          "server" = {
            HostName = "10.0.0.100";
            RemoteForward = remote_forwards;
          };

          "travel" = {
            HostName = "192.168.8.1";
            User = "root";
          };

          "work" = {
            HostName = "10.0.0.95";
          };
        })
    ];
  };
}
