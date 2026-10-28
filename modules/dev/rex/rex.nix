{
  mkUserModule,
  config,
  forPlatform,
  inputs,
  lib,
  my,
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

  rexProjectPicker = fishScript "rex-project-picker" (with pkgs; [rexCli coreutils fd fzf gawk jq]) ''
    set -l sessions_lua ${./sessions.lua}
    ${builtins.readFile ./project-picker.fish}
  '';

  rexurrect = lib.getExe my.pkgs.rexurrect;

  # The Rex server, launchd and systemd start rexurrect without the shell's XDG_* variables.
  rexurrectEnv = {
    REXURRECT_STATE_DIR = "${config.xdg.stateHome}/rexurrect";
    REXURRECT_CONFIG = "${config.xdg.configHome}/rexurrect/config.toml";
  };

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
          "rex.server.automatic-restart-enabled" = true;
          "rex.server.block-plugin-reload-enabled" = false;
          "rex.server.run-mode" = "bundled";
          "Workspace.appearance" = "dark";
          "Workspace.appIconVisibility" = "dockOnly";
          "Workspace.darkThemeID" = nordThemeId;
          "Workspace.darkUsesExtendedThemePalette" = 1;
          "Workspace.inactivePaneFadeMode" = "none";
          "Workspace.interfaceStyle" = "useTheme";
          "Workspace.lightThemeID" = nordThemeId;
          "Workspace.notificationPosition" = "top-right";
          "Workspace.paneDensity" = "compact";
          "Workspace.showsActivePaneBorder" = 1;
          "Workspace.showsProcessesInActivity" = 1;
          "Workspace.sidebarPosition" = "left";
          "Workspace.tabIconCount" = 4;
          "Workspace.tabIconTintMode" = "off";
          "Workspace.tabsFillAvailableSpace" = 1;
          "Workspace.tabStyle" = "vertical";
          "Workspace.terminalAllowsLigatures" = 0;
          "Workspace.terminalCustomSchemeLinks" = "ask";
          "Workspace.terminalFontName" = "Monaspace Neon";
          "Workspace.terminalFontPointSize" = 16;
          "Workspace.terminalFontSmoothing" = 1;
          "Workspace.terminalPaddingColor" = "background";
          "Workspace.terminalSmoothScrolling" = 1;
          "Workspace.terminalUsesDisplayP3" = 1;
          "Workspace.terminalUseThemePalette" = 0;
          "Workspace.tintsPanesWithProgramBackground" = 0;
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
        packages = [my.pkgs.rexurrect] ++ lib.optional isDarwin rexCli;
      };

      xdg = {
        # Lua type stub for rex.*, on emmylua_ls's library path (nvim/after/lsp/emmylua_ls.lua).
        dataFile."rex/types/rex.lua".source = ./types/rex.lua;

        configFile."rex/init.lua" = lib.mkIf isDarwin {
          source = pkgs.replaceVars ./init.lua {
            inherit rexurrect;
            inherit (rexurrectEnv) REXURRECT_STATE_DIR REXURRECT_CONFIG;
            rexHints = lib.getExe rexHints;
            rexProjectPicker = lib.getExe rexProjectPicker;
          };
        };

        configFile."rexurrect/config.toml".source = (pkgs.formats.toml {}).generate "rexurrect-config.toml" {
          # pi, like Claude Code, draws on the main screen, so its scrollback is its own UI.
          no_scrollback = ["claude" "pi"];
          programs = {
            # SessionLoad (nvim/lua/plugins/session.lua) loads resession's session for the git root or cwd.
            nvim = {
              resume = "nvim -c SessionLoad";
              requires_file = "";
            };
            # dotfiles/pi/extensions/rexurrect.ts reports the session ID.
            pi = {
              state = "id";
              resume = "pi --session {state}";
            };
          };
        };
      };

      launchd.agents.rexurrect-autosave = lib.mkIf isDarwin {
        enable = true;
        config = {
          Label = "io.github.cemcatik.rexurrect.autosave";
          ProgramArguments = [rexurrect "save"];
          EnvironmentVariables = rexurrectEnv // {PATH = "/usr/bin:/bin:/usr/sbin:/sbin";};
          StartInterval = 900;
          ProcessType = "Background";
          StandardOutPath = "/dev/null";
          StandardErrorPath = "/dev/null";
        };
      };

      systemd.user = lib.mkIf (!isDarwin) {
        services.rexurrect-autosave = {
          Unit.Description = "Save Rex sessions with rexurrect";
          Service = {
            Type = "oneshot";
            ExecStart = "${rexurrect} save";
            Environment = lib.mapAttrsToList (name: value: "${name}=${value}") rexurrectEnv;
          };
        };

        timers.rexurrect-autosave = {
          Unit.Description = "Save Rex sessions with rexurrect every 15 minutes";
          Timer = {
            OnActiveSec = "15min";
            OnUnitActiveSec = "15min";
          };
          Install.WantedBy = ["timers.target"];
        };
      };

      programs = {
        ai.skills.local.ids = ["rex"];

        fish.completions.rex = "command -q rex; and rex completion fish | source";

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
