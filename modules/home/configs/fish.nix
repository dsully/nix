{
  config,
  lib,
  pkgs,
  ...
}: let
  yamlFormat = pkgs.formats.yaml {};
in {
  home = {
    sessionPath = [
      "${config.home.homeDirectory}/.local/go/bin"
      "${config.home.homeDirectory}/.luarocks/bin"
    ];

    sessionVariables = {
      # Go
      GOPATH = "${config.home.homeDirectory}/.local/go";
      GO111MODULE = "on";

      # JavaScript
      NODE_REPL_HISTORY = "/dev/null";
      NO_UPDATE_NOTIFIER = "1";
      BIOME_CONFIG_PATH = "${config.xdg.configHome}/biome.json";
    };
  };

  programs.fish = {
    enable = true;

    plugins = [
      {
        name = "git";
        src = pkgs.fetchFromGitHub {
          owner = "jhillyerd";
          repo = "plugin-git";
          rev = "d6950214b6b2392d3dbb2cb670f2a5f240090038";
          hash = "sha256-0uEKw+7EXkf5u3p3hfthSfQO/2rr3wl35ela7P2vB0Q=";
        };
      }
      {
        name = "opah";
        src = pkgs.fetchFromGitHub {
          owner = "tbcrawford";
          repo = "opah.fish";
          rev = "fe12435c8ed1b39f4d667aec142a35bb5fbd4df7";
          hash = "sha256-SLtg5HA/ZSBhzbCEqmsMvvLrjk6FE1YbsDGeRVBuwag=";
        };
      }
    ];

    shellAbbrs = lib.mkIf pkgs.stdenv.isLinux {
      sc = "sudo systemctl";
      uc = "systemctl --user";
      sj = "journalctl --all --follow --unit";
      uj = "journalctl --all --follow --user-unit";
    };
  };

  programs.fzf = {
    enable = true;
    enableFishIntegration = true;
  };

  xdg.configFile."fish/secrets.yaml".source = yamlFormat.generate "fish-secrets-yaml" {
    secrets = {
      CACHIX_AUTH_TOKEN = "op://Services/Cachix/token";
      GITHUB_TOKEN = "op://Services/GitHub Home/token";
      OPENAI_API_KEY = "op://Services/OpenAI/token";
    };
  };
}
