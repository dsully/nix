{ pkgs, ... }:
let
  tomlFormat = pkgs.formats.toml { };
in
{
  xdg.configFile."tombi/config.toml".source = tomlFormat.generate "tombi-config.toml" {
    format = { };

    lint.rules = {
      dotted-keys-out-of-order = "warn";
      key-empty = "warn";
      tables-out-of-order = "warn";
    };

    lsp = {
      code-action.enabled = true;
      completion.enabled = true;
      diagnostic.enabled = true;
      document-link.enabled = true;
      formatting.enabled = true;
      goto-declaration.enabled = true;
      goto-definition.enabled = true;
      goto-type-definition.enabled = true;
      hover.enabled = true;
    };

    schema = {
      enabled = true;
      strict = true;
      catalog.paths = [
        "tombi://json.schemastore.org/api/json/catalog.json"
        "https://json.schemastore.org/api/json/catalog.json"
      ];
    };

    schemas = [
      {
        root = "tool.uv";
        path = "https://raw.githubusercontent.com/astral-sh/uv/refs/heads/main/uv.schema.json";
        include = [ "pyproject.toml" ];
      }
    ];
  };
}
