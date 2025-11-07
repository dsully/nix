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

    extraConfig = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin ''
      SetEnv SSH_CLIENT_HOME="${homeDirectory}" SSH_CLIENT_OS="Darwin"
      UseKeychain yes
    '';

    matchBlocks = lib.mkMerge [
      {
        "*" = {
          addKeysToAgent = "yes";
          compression = true;
          controlMaster = "auto";
          forwardAgent = lib.mkDefault true;
          serverAliveInterval = 10;
        };

        "github.com" = {
          user = "git";
          hostname = "github.com.";
          identitiesOnly = true;

          extraOptions = {
            ControlMaster = "no";
            ControlPersist = "no";
          };
        };

        "er" = {
          hostname = "172.104.194.233";

          extraOptions = {
            ControlMaster = "no";
            ControlPersist = "no";
          };
        };

        "tnt" = {
          hostname = "172.236.14.101";

          extraOptions = {
            ControlMaster = "no";
            ControlPersist = "no";
          };
        };
      }

      (lib.mkIf (hostName != "stelvio") {
        "sisyphus" = {
          hostname = "10.0.0.135";
          user = "pi";
        };

        "unifi gateway 10.0.0.1" = {
          hostname = "10.0.0.1";
          user = "root";
          identityFile = "${homeDirectory}/.ssh/id_rsa";
          localForwards = [
            {
              bind.port = 27017;
              host.address = "127.0.0.1";
              host.port = 27117;
            }
          ];
        };

        "nvr" = {
          user = "root";
          hostname = "10.0.0.2";
          identityFile = "${homeDirectory}/.ssh/id_rsa";
        };

        "switch" = {
          hostname = "10.0.0.3";
          user = "ubnt";
          identityFile = "${homeDirectory}/.ssh/id_rsa";
        };
      })

      (lib.mkIf (hostName != "jarvis") {
        "jarvis" = {
          hostname = "10.0.0.97";
        };
      })

      (lib.mkIf (hostName == "jarvis")
        {
          "server" = {
            hostname = "10.0.0.100";
            remoteForwards = remote_forwards;
          };

          "travel" = {
            hostname = "192.168.8.1";
            user = "root";
          };

          "work" = {
            hostname = "10.0.0.95";
          };
        })
    ];
  };
}
