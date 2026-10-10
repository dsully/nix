{
  mkUserModule,
  pkgs,
  ...
}: let
  yamlFormat = pkgs.formats.yaml {};
in
  mkUserModule {
    name = "yamllint";

    home = {
      xdg.configFile."yamllint.yaml".source = yamlFormat.generate "yamllint.yaml" {
        extends = "default";

        rules = {
          comments = {
            min-spaces-from-content = 1;
          };

          line-length = "disable";

          truthy = {
            allowed-values = ["true" "false"];
            check-keys = false;
          };
        };
      };
    };
  }
