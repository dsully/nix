{pkgs, ...}: let
  yamlFormat = pkgs.formats.yaml {};
in {
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
  };

  xdg.configFile."fish/secrets.yaml".source = yamlFormat.generate "fish-secrets-yaml" {
    secrets = {
      CACHIX_AUTH_TOKEN = "op://Services/Cachix/token";
      GITHUB_TOKEN = "op://Services/GitHub Home/token";
    };
  };
}
