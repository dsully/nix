{
  config,
  lib,
  my,
  pkgs,
  ...
}: let
  yamlFormat = pkgs.formats.yaml {};
  c = config.colors;
  inherit (config.colors) noHash;
in {
  home = {
    activation.opahRefresh =
      lib.hm.dag.entryAfter ["writeBoundary"]
      # bash
      ''
        config_file="${config.xdg.configHome}/fish/secrets.yaml"
        cache_file="${config.xdg.cacheHome}/fish/opah/secrets.fish"

        if [ ! -f "$cache_file" ] || [ "$config_file" -nt "$cache_file" ]; then
          ${lib.getExe pkgs.fish} -c "_opah_load --force" || true
        fi
      '';

    packages = [
      my.pkgs.fish-session
    ];

    sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";

      TREE_SITTER_DIR = "${config.xdg.configHome}/tree-sitter";

      # JavaScript
      BIOME_CONFIG_PATH = "${config.xdg.configHome}/biome.json";
      NODE_REPL_HISTORY = "/dev/null";
      NO_UPDATE_NOTIFIER = "1";
    };
  };

  programs.fish = {
    enable = true;

    # Magic enter functions: https://kau.sh/blog/magic-enter-shell/
    interactiveShellInit =
      # fish
      ''
        function __magic_enter
            set -l cmd (commandline)
            commandline -f repaint

            if test -z "$cmd"
                commandline -r ($argv[1])
                commandline -f suppress-autosuggestion
            end

            commandline -f execute
        end

        set -l magic_bindings \
            'comma,f,e' ',fe' \
            'comma,f,f' ',ff' \
            'comma,f,g' ',fg' \
            'comma,f,i' ',fi' \
            'comma,f,j' ',fj' \
            'comma,f,k' ',fk' \
            'comma,f,p' ',fp' \
            'comma,f,r' ',fr'

        for i in (seq 1 2 (count $magic_bindings))
            set -l key $magic_bindings[$i]
            set -l command $magic_bindings[(math $i + 1)]

            set -l func_name "__magic_enter_"(string replace -a ',' '_' $key)

            eval "function $func_name; __magic_enter '$command'; end"

            bind $key $func_name
        end
      ''
      + lib.optionalString pkgs.stdenv.isDarwin
      # fish
      ''
        ulimit -n unlimited
      '';

    plugins = [
      {
        name = "plugin-git";
        inherit (pkgs.fishPlugins.plugin-git) src;
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

    functions.cat = {
      wraps = "bat";
      description = "Use bat instead of cat";
      body =
        # fish
        ''
          # If no arguments are given, read from stdin.
          if isatty stdin; and not set -q argv[1]
              command cat -
              return
          end

          set -f image_extensions png jpg jpeg gif bmp tiff webp
          set -f markdown_extensions md markdown mkd

          # Escape --version and similar.
          set -f ext (string split "." -- $argv[1])[-1]

          if contains $ext $markdown_extensions; and type -q mdterm
              ${lib.getExe pkgs.mdterm} $argv[1]

          else if contains $ext $markdown_extensions; and type -q glow
              ${lib.getExe pkgs.glow} --pager $argv[1]

          else if contains $ext ipynb; and type -q nbcat
              command nbcat $argv

          else if contains $ext $image_extensions; and type -q viu
              ${lib.getExe pkgs.viu} $argv
          else if type -q bat
              ${lib.getExe pkgs.bat} $argv
          else
              command cat $argv
          end
        '';
    };

    completions.rm =
      builtins.replaceStrings ["complete -c rip"] ["complete -c rm"]
      (builtins.readFile (pkgs.runCommand "rip-completions" {} ''
        ${lib.getExe pkgs.rip2} completions fish > $out
      ''));

    shellAbbrs =
      {
        dc = "cd";
        fgfg = "fg";
        lf = "pytest --lf";
        pt = "pytest";
        mkdir = "mkdir -p";

        vi = "nvim";
        vim = "nvim";
        view = "nvim -R";
      }
      // lib.optionalAttrs pkgs.stdenv.isDarwin {
        ldd = "otool -L";
      }
      // lib.optionalAttrs pkgs.stdenv.isLinux {
        sc = "sudo systemctl";
        uc = "systemctl --user";
        sj = "journalctl --all --follow --unit";
        uj = "journalctl --all --follow --user-unit";
      };

    shellInit =
      # fish
      ''
        set -g HOSTNAME ${config.system.hostName}
        set -g OS ${
          if pkgs.stdenv.isDarwin
          then "Darwin"
          else "Linux"
        }
        set -g fish_greeting ""

        fish_config theme choose Nordish
      '';
  };

  xdg.configFile = {
    "fish/conf.d/pwd.fish".text =
      # fish
      ''
        function __auto_pwd --on-variable PWD
            if test -d "$PWD/.git"
                ${lib.getExe my.pkgs.devmoji-log}
            end
        end
      '';

    "fish/secrets.yaml".source = yamlFormat.generate "fish-secrets-yaml" {
      secrets = {
        CACHIX_AUTH_TOKEN = "op://Services/Cachix/token";
        GEMINI_API_KEY = "op://Services/Google Gemini/token";
        GITHUB_TOKEN = "op://Services/GitHub Home/token";
        OPENAI_API_KEY = "op://Services/OpenAI/token";
      };
    };

    "fish/themes/Nordish.theme".text =
      # fish
      ''
        # Nord Colors / Theme
        #
        # Syntax Highlighting Colors
        fish_color_autosuggestion ${noHash c.blue.base}
        fish_color_cancel -r
        fish_color_command ${noHash c.blue.base}
        fish_color_comment ${noHash c.gray.base}
        fish_color_cwd ${noHash c.green.base}
        fish_color_cwd_root ${noHash c.red.base}
        fish_color_end ${noHash c.cyan.bright}
        fish_color_error ${noHash c.yellow.base}
        fish_color_escape ${noHash c.blue.base}
        fish_color_history_current --bold
        fish_color_host normal
        fish_color_keyword ${noHash c.blue.base}
        fish_color_match --background=${noHash c.blue.bright}
        fish_color_normal normal
        fish_color_operator ${noHash c.blue.bright}
        fish_color_option ${noHash c.blue.base}
        fish_color_param ${noHash c.blue.base}
        fish_color_quote ${noHash c.white.base}
        fish_color_redirection ${noHash c.red.base}
        fish_color_search_match ${noHash c.yellow.base} --background=${noHash c.black.bright}
        fish_color_selection ${noHash c.white.base} --bold --background=${noHash c.black.bright}
        fish_color_user ${noHash c.green.base}
        fish_color_valid_path --underline

        # Completion Pager Colors
        fish_pager_color_completion normal
        fish_pager_color_description ${noHash c.yellow.base}
        fish_pager_color_prefix normal --bold --underline
        fish_pager_color_progress ${noHash c.white.bright} --background=${noHash c.cyan.base}
        fish_pager_color_selected_background --background=${noHash c.black.bright}
      '';
  };
}
