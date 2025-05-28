{
  globals,
  lib,
  pkgs,
  ...
}: {
  programs.ssh = {
    enable = true;

    # Global options for all hosts
    addKeysToAgent = "yes";
    compression = true;
    controlMaster = "auto";
    forwardAgent = true;
    serverAliveInterval = 10;

    matchBlocks = lib.mkMerge [
      {
        "*" = {
          extraOptions = lib.mkMerge [
            (lib.mkIf pkgs.stdenv.isDarwin {
              AddKeysToAgent = "yes";
              UseKeychain = "yes";
            })
          ];
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

        "* !github.* !electricrain.com" = {
          # https://carlosbecker.com/posts/pbcopy-pbpaste-open-ssh/
          remoteForwards = lib.mkIf pkgs.stdenv.isDarwin [
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
        };

        "er" = {
          hostname = "172.104.194.233";

          extraOptions = {
            ControlMaster = "no";
            ControlPersist = "no";
          };
        };
      }

      (lib.mkIf (globals.host.name != "stelvio") {
        "sisyphus" = {
          hostname = "10.0.0.135";
          user = "pi";
        };

        "unifi gateway 10.0.0.1" = {
          hostname = "10.0.0.1";
          user = "root";
          identityFile = "${builtins.getEnv "HOME"}/.ssh/id_rsa";
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
          identityFile = "${builtins.getEnv "HOME"}/.ssh/id_rsa";
        };

        "switch" = {
          hostname = "10.0.0.3";
          user = "ubnt";
          identityFile = "${builtins.getEnv "HOME"}/.ssh/id_rsa";
        };
      })

      (lib.mkIf (globals.host.name != "server") {
        "server" = {
          hostname = "10.0.0.100";
          setEnv = {
            SSH_CLIENT_OS = "Darwin";
            SSH_CLIENT_HOME = "/Users/dsully";
          };
        };
      })

      (lib.mkIf (globals.host.name != "jarvis") {
        "jarvis" = {
          hostname = "10.0.0.97";
        };
      })

      (lib.mkIf (globals.host.name == "jarvis")
        {
          "parents" = {
            hostname = "67.183.128.190";
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
