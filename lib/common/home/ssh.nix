{
  globals,
  lib,
  pkgs,
  ...
}: let
  inherit (pkgs.stdenv) isDarwin;

  onHomeNetwork = let
    result = pkgs.runCommand "home-network-check" {} ''
      if /sbin/ifconfig | grep '10\.0\.0\.255'; then
        echo true > $out
      else
        echo false > $out
      fi
    '';
  in
    import result;
in {
  programs.ssh = {
    enable = true;

    # Global settings
    extraConfig =
      if isDarwin
      then ''
        LogLevel ERROR
        IdentityAgent = "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
        UseKeychain yes
      ''
      else ''
        LogLevel ERROR
        IdentityFile = "${builtins.getEnv "HOME"}/.ssh/id_ed25519"
      '';

    # Global options for all hosts
    addKeysToAgent = "yes";
    compression = true;
    controlMaster = "auto";
    forwardAgent = true;
    serverAliveInterval = 10;

    matchBlocks = lib.mkMerge [
      {
        "github.com" = {
          user = "git";
          hostname = "github.com.";
          identitiesOnly = true;

          extraOptions = {
            ControlMaster = "no";
            ControlPersist = "no";
          };
        };

        "* !github.com !electricrain.com" = {
          # https://carlosbecker.com/posts/pbcopy-pbpaste-open-ssh/
          remoteForwards = lib.mkIf pkgs.stdenv.isDarwin [
            {
              bind.address = "localhost";
              bind.port = 2224;
              host.address = "127.0.0.1";
              host.port = 2224;
            }
            {
              bind.address = "localhost";
              bind.port = 2225;
              host.address = "127.0.0.1";
              host.port = 2225;
            }
            {
              bind.address = "localhost";
              bind.port = 2226;
              host.address = "127.0.0.1";
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

      (lib.mkIf onHomeNetwork {
        "sisyphus" = {
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
          identityFile = "${builtins.getEnv "HOME"}/.ssh/id_rsa";
        };

        "switch" = {
          hostname = "10.0.0.3";
          user = "ubnt";
          identityFile = "${builtins.getEnv "HOME"}/.ssh/id_rsa";
        };

        "server" = {
          setEnv = {
            SSH_CLIENT_OS = "Darwin";
            SSH_CLIENT_HOME = "/Users/dsully";
          };
        };
      })

      (lib.mkIf (onHomeNetwork && globals.host.name != "jarvis") {
        "jarvis" = {
          hostname = "10.0.0.97";
        };
      })

      (lib.mkIf (onHomeNetwork && globals.host.name == "jarvis") {
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
