{pkgs, ...}: let
  tomlFormat = pkgs.formats.toml {};

  rumdlConfig = tomlFormat.generate "rumdl.toml" {
    # yaml-language-server: $schema=https://raw.githubusercontent.com/rvben/rumdl/main/rumdl.schema.json

    global = {
      disable = [
        "MD013"
        "MD034"
        "MD043"
      ];
      exclude = ["node_modules" "build" "dist"];

      # https://github.com/rvben/rumdl/blob/main/docs/global-settings.md
      flavor = "standard";

      line_length = 220;
    };

    MD004 = {
      style = "sublist";
    };

    MD025 = {
      front-matter-title = "^\\s*(title|heading)\\s*[:=]";
    };

    MD033 = {
      allowed-elements = [
        "details"
        "summary"
      ];
    };
  };
in {
  xdg.configFile."rumdl/rumdl.toml".text = ''
    # yaml-language-server: $schema=https://raw.githubusercontent.com/rvben/rumdl/main/rumdl.schema.json
    ${builtins.readFile rumdlConfig}
  '';
}
