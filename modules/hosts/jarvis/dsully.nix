{
  config,
  perSystem,
  pkgs,
  ...
}: {
  fishSecrets.XCODE_SIGN_IDENTITY = "op://Services/Xcode Home/credential";

  home = {
    file = {
      ".huggingface".source = config.lib.file.mkOutOfStoreSymlink "${config.xdg.configHome}/huggingface";
    };

    packages = with pkgs;
      [
        zls
      ]
      ++ (with perSystem.self; [
        autorebase
      ]);
  };

  programs = {
    onepassword-secrets.secrets = {
      sshRSAPrivateKey = {
        reference = "op://Services/gateway/private key";
        path = ".ssh/id_rsa";
      };
    };

    pi-coding-agent = {
      settings.packages = [
        "npm:@gotgenes/pi-anthropic-auth"
      ];
    };

    topgrade = {
      settings = {
        git = {
          repos = [
            "${config.home.homeDirectory}/src/*/"
            "${config.home.homeDirectory}/src/neovim/*/"
            "${config.home.homeDirectory}/src/dots/*/*/"
            "${config.home.homeDirectory}/src/nix/*/"
            "${config.home.homeDirectory}/src/rust/*/"
          ];
        };

        misc = {
          only = [
            "brew_formula"
            "brew_cask"
            "git_repos"
          ];
        };
      };
    };
  };
}
