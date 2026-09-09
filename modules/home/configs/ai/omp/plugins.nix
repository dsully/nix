{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.omp;

  # Declarative base omp plugin list. To add or remove a plugin for every
  # consumer, edit this list; a single host or downstream flake appends its own
  # via `programs.omp.extraPlugins` instead of restating this one. The
  # activation script reinstalls when the generated package.json changes.
  plugins =
    [
      {
        name = "@dietrichgebert/ponytail";
        spec = "https://github.com/DietrichGebert/ponytail";
        version = "4.9.0";
      }
      {
        name = "@qoderai/better-harness";
        spec = "https://github.com/QoderAI/better-harness";
        version = "0.4.0";
      }
      {
        name = "omp-command-palette";
        spec = "https://github.com/danbarua/omp-command-palette";
        version = "0.1.0";
      }
      # {
      #   name = "context-mode";
      #   spec = "^1.0.162";
      #   version = "1.0.162";
      # }
    ]
    ++ cfg.extraPlugins;

  packageJson = pkgs.writeText "omp-plugins-package.json" (
    builtins.toJSON {
      name = "omp-plugins";
      private = true;
      dependencies = builtins.listToAttrs (
        map (p: {
          inherit (p) name;
          value = p.spec;
        })
        plugins
      );
    }
  );

  pluginsLock = pkgs.writeText "omp-plugins-lock.json" (
    builtins.toJSON {
      plugins = builtins.listToAttrs (
        map (p: {
          inherit (p) name;
          value = {
            inherit (p) version;
            enabledFeatures = null;
            enabled = true;
          };
        })
        plugins
      );
      settings = {};
    }
  );
in {
  options.programs.omp.extraPlugins = lib.mkOption {
    type = lib.types.listOf (
      lib.types.submodule {
        options = {
          name = lib.mkOption {
            type = lib.types.str;
            description = "npm package name of the omp plugin.";
          };
          spec = lib.mkOption {
            type = lib.types.str;
            description = "Install spec: a version range, npm dist-tag, or a URL (e.g. a GitHub repo).";
          };
          version = lib.mkOption {
            type = lib.types.str;
            description = "Resolved version recorded in the lock; a change triggers a reinstall.";
          };
        };
      }
    );
    default = [];
    description = "Additional omp plugins appended to the base set.";
    example = lib.literalExpression ''
      [ { name = "@some/package"; spec = "0.1.9"; version = "0.1.9"; } ]
    '';
  };

  config = {
    xdg.configFile."omp/plugins/package.json".source = packageJson;
    xdg.configFile."omp/plugins/omp-plugins.lock.json".source = pluginsLock;

    home.activation.installOmpPlugins = lib.hm.dag.entryAfter ["writeBoundary"] ''
      export PATH="${pkgs.bun}/bin:$PATH"
      PLUGINS_DIR="${config.xdg.configHome}/omp/plugins"

      HASH_FILE="$PLUGINS_DIR/.package-hash"
      CURRENT_HASH=$(readlink "$PLUGINS_DIR/package.json" 2>/dev/null || echo "")

      if [ "$CURRENT_HASH" != "$(cat "$HASH_FILE" 2>/dev/null)" ]; then
        mkdir -p "$PLUGINS_DIR"
        cd "$PLUGINS_DIR" && bun install --no-save 2>&1 || true
        printf '%s' "$CURRENT_HASH" > "$HASH_FILE"
      fi
    '';
  };
}
