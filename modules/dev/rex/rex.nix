{
  mkUserModule,
  config,
  forPlatform,
  inputs,
  lib,
  pkgs,
  ...
}: let
  tokenPath = ".cache/tokens/rex.txt";
  netrcPath = ".cache/tokens/rex.netrc";

  homeDir = config.home.homeDirectory;

  inherit (pkgs.stdenv.hostPlatform) isDarwin;

  # The helper bundle's name changes between builds ("Rex Server.app", "Rex Server.rex").
  rexCli = pkgs.writeShellScriptBin "rex" ''
    for rex in "/Applications/Rex Beta.app/Contents/Helpers/"*/Contents/MacOS/rex; do
      [ -x "$rex" ] && exec "$rex" "$@"
    done
    echo "rex: Rex Beta.app is not installed in /Applications" >&2
    exit 127
  '';

  fishScript = name: runtimeInputs: text:
    pkgs.writeTextFile {
      inherit name;
      destination = "/bin/${name}";
      executable = true;
      text = ''
        #!${lib.getExe pkgs.fish}
        set -p PATH ${lib.makeBinPath runtimeInputs}
        ${text}
      '';
      checkPhase = "${lib.getExe pkgs.fish} --no-execute $target";
      meta.mainProgram = name;
    };

  rexHints = fishScript "rex-hints" [rexCli pkgs.fzf pkgs.gawk pkgs.ripgrep] (builtins.readFile ./hints.fish);

  rexProjectPicker = fishScript "rex-project-picker" (with pkgs; [rexCli coreutils fd fzf gawk jq]) (builtins.readFile ./project-picker.fish);

  nordThemeId = "custom-93EEFE7D-B004-481D-AE29-BE2E029C3E99";

  # Ghostty's built-in Nord slots, filled from the palette nvim uses. Rex stores
  # custom themes as one JSON data blob, which CustomUserPreferences can't express.
  rexThemes = let
    c = config.colors;
    rgb = hex: let
      channel = i: lib.fromHexString (builtins.substring i 2 (c.noHash hex)) / 255.0;
    in {
      red = channel 0;
      green = channel 2;
      blue = channel 4;
      alpha = 1;
      colorSpace = "srgb";
    };
  in
    pkgs.writeText "rex-themes.json" (builtins.toJSON [
      {
        id = nordThemeId;
        name = "Nord";
        appearance = "dark";
        createdAt = 814308125.0;
        source.ghosttyMigration.themeName = "Nord";
        palette = {
          background = rgb c.bg;
          foreground = rgb c.white.dim;
          cursor = rgb c.white.bright;
          cursorText = rgb c.bg;
          selectionBackground = rgb c.white.bright;
          selectionForeground = rgb c.gray.base;
          ansi = map rgb [
            c.black.base
            c.red.base
            c.green.base
            c.yellow.base
            c.blue.base
            c.magenta.base
            c.cyan.bright
            c.white.base
            "#596377"
            c.red.base
            c.green.base
            c.yellow.base
            c.blue.base
            c.magenta.base
            c.cyan.base
            c.white.bright
          ];
          paletteBase = {};
          paletteGenerate = false;
          paletteHarmonious = true;
          paletteOverrides = {};
        };
      }
    ]);

  systemHomeDir =
    if pkgs.stdenv.hostPlatform.isDarwin
    then "/Users/${config.system.userName}"
    else "/home/${config.system.userName}";
in
  mkUserModule {
    name = "rex";
    default = false;

    system = lib.mkMerge [
      # Nix fetches the pre-release rex flake input with HTTP basic auth from this netrc.
      {system.nixSettings.netrc-file = "${systemHomeDir}/${netrcPath}";}

      # Rebuilds overwrite these keys if they are changed in Rex's Settings.
      (forPlatform {
        darwin.system.defaults.CustomUserPreferences."com.superlogical.rex" = {
          "rex.agents.names-sessions" = 1;
          "rex.client.remoteControl" = true;
          "rex.developer-mode-enabled" = 1;
          "rex.server.automatic-restart-enabled" = true;
          "rex.server.block-plugin-reload-enabled" = false;
          "rex.server.run-mode" = "bundled";
          "Workspace.animationStyle" = "natural";
          "Workspace.appearance" = "dark";
          "Workspace.appIconVisibility" = "dockOnly";
          "Workspace.darkThemeID" = nordThemeId;
          "Workspace.darkUsesExtendedThemePalette" = 1;
          "Workspace.experiments.usesNewQuickSwitcher" = 1;
          "Workspace.inactivePaneFadeMode" = "none";
          "Workspace.interfaceStyle" = "useTheme";
          "Workspace.lightThemeID" = nordThemeId;
          "Workspace.notificationPosition" = "top-right";
          "Workspace.paneDensity" = "compact";
          "Workspace.prefersGeneratedTitles" = 0;
          "Workspace.showsActivePaneBorder" = 1;
          "Workspace.showsPaneHeaders" = 1;
          "Workspace.showsProcessesInActivity" = 1;
          "Workspace.sidebarCollapsed" = 0;
          "Workspace.sidebarPosition" = "left";
          "Workspace.sidebarShowsActivity" = 0;
          "Workspace.sidebarSwipe" = "off";
          "Workspace.sidebarTextPointSize" = 15;
          "Workspace.tabIconCount" = 3;
          "Workspace.tabIconTintMode" = "off";
          "Workspace.tabsFillAvailableSpace" = 1;
          "Workspace.tabStyle" = "vertical";
          "Workspace.terminalAllowsLigatures" = 0;
          "Workspace.terminalCustomSchemeLinks" = "ask";
          "Workspace.terminalFontName" = "Monaspace Neon";
          "Workspace.terminalFontPointSize" = 16;
          "Workspace.terminalFontSmoothing" = 1;
          "Workspace.terminalPaddingColor" = "background";
          "Workspace.terminalPaddingY" = 10;
          "Workspace.terminalSmoothScrolling" = 1;
          "Workspace.terminalUsesDisplayP3" = 1;
          "Workspace.terminalUseThemePalette" = 0;
          "Workspace.tintsPanesWithProgramBackground" = 0;
          "Workspace.usesPaneGlass" = 1;
          "Workspace.usesStandardInactiveWindowPaneStyles" = false;
        };
      })
    ];

    home = {
      home = {
        activation = {
          rexNetrc =
            inputs.home-manager.lib.hm.dag.entryAfter ["writeBoundary" "onepassword-secrets"]
            # bash
            ''
              if [ -f "${homeDir}/${tokenPath}" ]; then
                (umask 077; printf 'machine pkgs.superlogical.com login rex password %s\n' "$(cat "${homeDir}/${tokenPath}")" > "${homeDir}/${netrcPath}")
              fi
            '';

          rexTerminfo = lib.mkIf isDarwin (inputs.home-manager.lib.hm.dag.entryAfter ["writeBoundary"] ''
            run ${lib.getExe rexCli} terminfo setup --entry-only --autostart=false >/dev/null || true
          '');

          # Replaces every custom theme made in Rex's Settings.
          rexThemes = lib.mkIf isDarwin (inputs.home-manager.lib.hm.dag.entryAfter ["writeBoundary"] ''
            run /usr/bin/defaults write com.superlogical.rex Workspace.customThemes \
              -data "$(${pkgs.unixtools.xxd}/bin/xxd -p ${rexThemes} | tr -d '\n')"
          '');

          # Rex does not watch init.lua.
          rexConfigReload = lib.mkIf isDarwin (inputs.home-manager.lib.hm.dag.entryAfter ["linkGeneration"] ''
            run ${lib.getExe rexCli} config reload --autostart=false >/dev/null 2>&1 || true
          '');
        };

        # On Linux, the rex flake's programs.rex installs the CLI, terminfo and ssh fallback.
        packages = lib.optionals isDarwin [rexCli rexHints rexProjectPicker];
      };

      xdg = {
        # Lua type stub for rex.*, on emmylua_ls's library path (nvim/after/lsp/emmylua_ls.lua).
        dataFile."rex/types/rex.lua".source = ./types/rex.lua;

        configFile.rex = lib.mkIf isDarwin {
          source = config.lib.file.mkOutOfStoreSymlink "${config.dotfiles.dir}/rex";
        };
      };

      programs = {
        ai.skills.local.ids = ["rex"];

        fish.completions.rex = "command -q rex; and rex completion fish | source";

        fish.functions.rex-ssh = {
          description = "Run rex against HOST's server over an ssh socket forward";
          body =
            # fish
            ''
              argparse d/down -- $argv; or return
              if not set -q argv[1]
                  echo "usage: rex-ssh HOST [REX ARGS...] | rex-ssh --down HOST" >&2
                  return 2
              end
              set -l host $argv[1]
              set -l label (string split -f1 . -- $host)
              set label (string upper -- (string sub -l 1 -- $label))(string sub -s 2 -- $label)
              # Reuse the port of the host added in the app's Remote Hosts; else a stable per-host port.
              set -l port (rex hosts --json | ${lib.getExe pkgs.jq} -r --arg l $label '.hosts[] | select(.host.label | ascii_downcase == ($l | ascii_downcase)) | .host.endpoints[] | capture("^http://127[.]0[.]0[.]1:(?<p>[0-9]+)$").p' | head -1)
              test -n "$port"; or set port (math 47000 + (string split -f1 ' ' -- (echo -n $host | cksum)) % 1000)
              set -l url http://127.0.0.1:$port
              if set -q _flag_down
                  pkill -f -- "-L 127.0.0.1:$port:"
                  return 0
              end
              if not rex -S $url whoami &>/dev/null
                  set -l endpoint (ssh $host rex whoami --json --autostart=false | ${lib.getExe pkgs.jq} -r .endpoint)
                  string match -q 'unix://*' -- $endpoint
                  or begin
                      echo "rex-ssh: no Rex server socket on $host" >&2
                      return 1
                  end
                  # -S none: an existing ControlMaster connection refuses the forward.
                  ssh -f -N -S none -o ExitOnForwardFailure=yes \
                      -L "127.0.0.1:$port:"(string replace unix:// "" -- $endpoint | string unescape --style=url) $host
                  or return
                  echo "rex-ssh: $host at $url (app: Add Remote Host \"$label\" with this URL if missing)" >&2
              end
              set -q argv[2]; or set -a argv ls
              rex -S $url $argv[2..]
            '';
        };

        mcp.servers.superlogical = {
          type = "http";
          url = "https://www.superlogical.com/rex/community-mcp";
          enabled = false;
        };

        # Rex's own guard, inlined: ssh keeps only the first SetEnv, so it must carry Host *'s too.
        ssh.settings."0-rex-terminfo" = {
          header = ''Match exec "[ x$TERM = xxterm-rex ] && ! grep -qxF -- %h '${homeDir}/.config/rex/terminfo-hosts' 2>/dev/null"'';
          SetEnv = {TERM = "xterm-256color";} // config.programs.ssh.settings."*".data.SetEnv;
        };

        onepassword-secrets.secrets.rexPackageToken = {
          reference = "op://Services/Rex/credential";
          path = tokenPath;
        };
      };
    };
  }
