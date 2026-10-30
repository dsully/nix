{
  config,
  inputs,
  lib,
  mkUserModule,
  pkgs,
  ...
}:
mkUserModule {
  name = "homebrew";

  home = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
    home = {
      # nix-darwin's brew bundle runs under sudo without XDG_CONFIG_HOME, so it reads ~/.homebrew/trust.json.
      activation.homebrewTrust = inputs.home-manager.lib.hm.dag.entryAfter ["writeBoundary"] ''
        trust="${config.xdg.configHome}/homebrew/trust.json"
        legacy="${config.home.homeDirectory}/.homebrew/trust.json"
        merge='reduce .[] as $f ({}; reduce ($f|keys[]) as $k (.; .[$k] = ((.[$k] // []) + $f[$k] | unique)))'

        run mkdir -p "$(dirname "$trust")" "$(dirname "$legacy")"

        if [ -f "$legacy" ] && [ ! -L "$legacy" ]; then
          if [ -f "$trust" ]; then
            run sh -c '${lib.getExe pkgs.jq} -s "$3" "$1" "$2" > "$1.tmp" && cat "$1.tmp" > "$1" && rm "$1.tmp"' _ "$trust" "$legacy" "$merge"
            run mv "$legacy" "$legacy.bak"
          else
            run mv "$legacy" "$trust"
          fi
        fi

        run ln -sfn "$trust" "$legacy"
      '';

      sessionVariables = {
        HOMEBREW_NO_ANALYTICS = "1";
        HOMEBREW_NO_ASK = "1";
        HOMEBREW_NO_COMPAT = "1";
        HOMEBREW_NO_ENV_HINTS = "1";
        HOMEBREW_NO_INSTALL_CLEANUP = "1";
      };
    };
  };
}
