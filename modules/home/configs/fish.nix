{pkgs, ...}: let
  yamlFormat = pkgs.formats.yaml {};
in {
  xdg.configFile."fish/secrets.yaml".source = yamlFormat.generate "fish-secrets-yaml" {
    secrets = {
      CACHIX_AUTH_TOKEN = "op://Services/Cachix/token";
      GITHUB_TOKEN = "op://Services/GitHub Home/token";
    };
  };
}
