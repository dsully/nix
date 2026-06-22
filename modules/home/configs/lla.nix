{
  config,
  lib,
  pkgs,
  ...
}: let
  c = config.colors;
in {
  config = {
    home.packages = with pkgs; [
      lla
    ];

    programs.fish.functions.ls = {
      wraps = "lla";
      description = "Use lla with common ls flag cluster compatibility";
      body =
        # fish
        ''
          set -l args
          set -l paths

          for arg in $argv
              if string match -qr '^-[A-Za-z0-9]+$' -- $arg
                  set -l chars (string split "" -- (string sub --start 2 -- $arg))

                  for char in $chars
                      switch $char
                          case t
                              set -a args --sort=date
                          case S
                              set -a args --sort=size
                          case '*'
                              set -a args -$char
                      end
                  end
              else
                  set -a args $arg

                  if not string match -q -- '-*' $arg
                      set -a paths $arg
                  end
              end
          end

          if test (count $paths) -gt 1
              ${pkgs.coreutils}/bin/ls $argv
          else if test (count $paths) -eq 1; and not test -d $paths[1]
              ${pkgs.coreutils}/bin/ls $argv
          else
              ${lib.getExe pkgs.lla} $args
          end
        '';
    };

    xdg.configFile = {
      "fish/conf.d/lla-completions.fish".text =
        # fish
        ''complete -c lla --force-files -n __fish_use_subcommand'';

      "lla/config.toml".source = (pkgs.formats.toml {}).generate "lla-config" {
        # Default sorting method for file listings
        # Possible values:
        #   - "name": Sort alphabetically by filename (default)
        #   - "size": Sort by file size, largest first
        #   - "date": Sort by modification time, newest first
        default_sort = "name";

        # Default format for displaying files
        # Possible values:
        #   - "default": Quick and clean directory listing
        #   - "long": Detailed file information with metadata
        #   - "tree": Hierarchical directory visualization
        #   - "fuzzy": Interactive fuzzy search
        #   - "grid": Organized grid layout for better readability
        #   - "git": Git-aware view with repository status
        #   - "timeline": Group files by time periods
        #   - "sizemap": Visual representation of file sizes
        #   - "table": Structured data display
        default_format = "grid";

        # Whether to show icons by default
        # When true, file and directory icons will be displayed in all views
        # Default: false
        show_icons = true;

        # Whether to include directory sizes in file listings
        # When true, directory sizes will be calculated recursively
        # This may impact performance for large directories
        # Default: false
        include_dirs = false;

        # Format for displaying file permissions
        # Possible values:
        #   - "symbolic": Traditional Unix-style (e.g., -rw-r--r--)
        #   - "octal": Numeric mode (e.g., d644)
        #   - "binary": Binary representation (e.g., 110100100)
        #   - "compact": Compact representation (e.g., 644)
        #   - "verbose": Verbose representation (e.g., type:file owner:rwx group:r-x others:r-x)
        # Default: "symbolic"
        permission_format = "symbolic";

        # The theme to use for coloring
        # Place custom themes in ~/.config/lla/themes/
        # Default: "default"
        theme = "nord";

        # List of enabled plugins
        # Each plugin provides additional functionality
        # Examples:
        #   - "git_status": Show Git repository information
        #   - "file_hash": Calculate and display file hashes
        #   - "file_tagger": Add and manage file tags
        enabled_plugins = [
        ];

        # Directory where plugins are stored
        # Default: ~/.config/lla/plugins
        plugins_dir = "${config.xdg.configHome}/lla/plugins";

        # Paths to exclude from listings (tilde is supported)
        # Examples:
        #   - "~/Library/Mobile Documents"  # macOS iCloud Drive (Mobile Documents)
        #   - "~/Library/CloudStorage"      # macOS cloud storage providers
        # Default: [] (no exclusions)
        # Mirrors the ignore-globs set in lsd.nix
        exclude_paths = [
          ".git"
          ".mypy_cache"
          ".pytest_cache"
          ".ruff_cache"
          "__breadboard__"
          "__pycache__"
          "__pypackages__"
          "build-results"
        ];

        # Maximum depth for recursive directory traversal
        # Controls how deep lla will go when showing directory contents
        # Set to None for unlimited depth (may impact performance)
        # Default: 3 levels deep
        default_depth = 3;

        # Sorting configuration
        sort = {
          # List directories before files
          # Default: false
          dirs_first = false;

          # Enable case-sensitive sorting
          # Default: false
          case_sensitive = false;

          # Use natural sorting for numbers (e.g., 2.txt before 10.txt)
          # Default: true
          natural = true;
        };

        # Filtering configuration
        filter = {
          # Enable case-sensitive filtering by default
          # Default: false
          case_sensitive = false;

          # Hide dot files and directories by default
          # Default: false
          no_dotfiles = true;

          # Respect .gitignore (and git exclude) rules when listing files
          # Default: false
          respect_gitignore = false;

          # Named filter presets let you reuse complex filter combinations
          # Uncomment and customize the example below or define your own under filter.presets.<name>
          # presets.rust_sources = {
          #   description = "Common Rust sources";
          #   filter = "glob:*.{rs,toml}";
          #   size = "<2M";
          #   modified = "<30d";
          # };
        };

        # Formatter-specific configurations
        formatters = {
          tree = {
            # Maximum number of entries to display in tree view
            # Controls memory usage and performance for large directories
            # Set to 0 to show all entries (may impact performance)
            # Default: 20000 entries
            max_lines = 20000;
          };

          # Grid formatter configuration
          grid = {
            # Whether to ignore terminal width by default
            # When true, grid view will use max_width instead of terminal width
            # Default: false
            ignore_width = false;

            # Maximum width for grid view when ignore_width is true
            # This value is used when terminal width is ignored
            # Default: 200 columns
            max_width = 200;
          };

          # Long formatter configuration
          long = {
            # Hide the group column in long format
            # Default: false
            hide_group = false;

            # Show relative dates (e.g., "2h ago") in long format
            # Default: false
            relative_dates = false;

            # Column order for long view (use built-in keys or field:<custom_field> for plugin data)
            columns = [
              "permissions"
              "size"
              "modified"
              "user"
              "group"
              "name"
            ];
          };

          # Table formatter configuration
          table = {
            # Columns rendered in table view (same keys as long view; include plugin fields via field:<name>)
            columns = [
              "permissions"
              "size"
              "modified"
              "name"
            ];
          };
        };

        # Lister-specific configurations
        listers = {
          recursive = {
            # Maximum number of entries to process in recursive listing
            # Controls memory usage and performance for deep directory structures
            # Set to 0 to process all entries (may impact performance)
            # Default: 20000 entries
            max_entries = 20000;
          };

          # Fuzzy lister configuration
          fuzzy = {
            # Patterns to ignore when listing files in fuzzy mode
            # Can be:
            #  - Simple substring match: "node_modules"
            #  - Glob pattern: "glob:*.min.js"
            #  - Regular expression: "regex:.*\\.pyc$"
            # Default: ["node_modules", "target", ".git", ".idea", ".vscode"]
            ignore_patterns = [
              "glob:*.egg-info"
              ".git"
              ".mypy_cache"
              ".pytest_cache"
              ".ruff_cache"
              "__breadboard__"
              "__pycache__"
              "__pypackages__"
              "build-results"
              ".idea"
              "node_modules"
              "target"
              ".venv"
              "venv"
              ".vscode"
            ];

            # Editor to use for editing files in fuzzy view
            # Overrides the $EDITOR environment variable if set
            # Examples: "nvim", "vim", "nano", "code"
            # Default: "" (falls back to $EDITOR or $VISUAL, then nano)
            editor = "";
          };
        };
      };

      "lla/themes/nord.toml".source = (pkgs.formats.toml {}).generate "lla-theme-nord" {
        name = "nord";

        colors = {
          # Mirror the vivid nord LS_COLORS palette (di / ln / ex / fi)
          file = c.cyan.bright;
          directory = c.blue.bright;
          symlink = c.cyan.bright;
          executable = c.cyan.base;

          size = c.cyan.base;
          date = c.white.base;
          user = c.white.base;
          group = c.white.base;

          permission_dir = c.blue.base;
          permission_read = c.cyan.base;
          permission_write = c.cyan.bright;
          permission_exec = c.white.bright;
          permission_none = c.white.bright;
        };

        special_files = {
          # vivid nord dims caches/build output (unimportant -> gray.base)
          folders = {
            node_modules = c.gray.base;
            target = c.gray.base;
            dist = c.gray.base;
            ".git" = c.gray.base;
            build = c.gray.base;
            ".cache" = c.gray.base;
            "*-env" = c.white.bright;
            venv = c.white.bright;
            ".env" = c.white.bright;
            "*.d" = c.white.bright;
            "*_cache" = c.gray.base;
            "*-cache" = c.gray.base;
          };

          # vivid colors dotfiles/config like regular files (white.bright)
          dotfiles = {
            ".gitignore" = c.white.bright;
            ".env" = c.white.bright;
            ".dockerignore" = c.white.bright;
            ".editorconfig" = c.white.bright;
            ".prettierrc" = c.white.bright;
            ".eslintrc" = c.white.bright;
            ".babelrc" = c.white.bright;
          };

          exact_match = {
            Dockerfile = c.white.bright;
            "docker-compose.yml" = c.white.bright;
            Makefile = c.white.bright;
            "CMakeLists.txt" = c.white.bright;
            "README.md" = c.white.bright;
            LICENSE = c.white.bright;
            "package.json" = c.white.bright;
            "Cargo.toml" = c.white.bright;
            "go.mod" = c.white.bright;
            "flake.nix" = c.white.bright;
            "flake.lock" = c.gray.base;
            "shell.nix" = c.white.bright;
            "default.nix" = c.white.bright;
            "go.sum" = c.gray.base;
            "package-lock.json" = c.gray.base;
            "uv.lock" = c.gray.base;
            "poetry.lock" = c.gray.base;
          };

          # vivid dims generated/lock artifacts; TODO/test markers stay bright
          patterns = {
            "*rc" = c.white.bright;
            "*.min.*" = c.gray.base;
            "*.test.*" = c.white.bright;
            "*.spec.*" = c.white.bright;
            "*.lock" = c.gray.base;
            "*.config.*" = c.white.bright;
          };
        };

        extensions = {
          groups = {
            rust = ["rs" "toml"];
            python = ["py" "pyi" "pyw" "ipynb"];
            javascript = ["js" "mjs" "cjs" "jsx"];
            typescript = ["ts" "tsx" "d.ts"];
            java = ["java" "jar" "class"];
            csharp = ["cs" "csx"];
            cpp = ["cpp" "cc" "cxx" "c++" "hpp" "hxx" "h++"];
            go = ["go"];
            ruby = ["rb" "erb"];
            php = ["php" "phtml"];
            swift = ["swift"];
            kotlin = ["kt" "kts"];
            nix = ["nix"];

            markup = ["html" "htm" "xhtml" "xml" "svg" "vue" "wasm" "ejs"];
            style = ["css" "scss" "sass" "less" "styl"];
            web_config = ["json" "json5" "yaml" "yml" "toml" "ini" "conf" "config"];

            shell = ["sh" "bash" "zsh" "fish" "ps1" "psm1" "psd1"];
            script = ["pl" "pm" "t" "tcl" "lua" "vim" "vimrc" "r"];

            doc = [
              "md"
              "rst"
              "txt"
              "org"
              "wiki"
              "adoc"
              "tex"
              "pdf"
              "epub"
              "doc"
              "docx"
              "rtf"
            ];

            image = ["png" "jpg" "jpeg" "gif" "bmp" "tiff" "webp" "ico" "heic"];
            video = ["mp4" "webm" "mov" "avi" "mkv" "flv" "wmv" "m4v" "3gp"];
            audio = ["mp3" "wav" "ogg" "m4a" "flac" "aac" "wma"];

            data = ["csv" "tsv" "sql" "sqlite" "db" "json" "xml" "yaml" "yml"];
            archive = ["zip" "tar" "gz" "bz2" "xz" "7z" "rar" "iso" "dmg"];
          };

          # vivid nord renders source uniformly (white.bright), media/docs/data
          # green.base, archives green.base. Mirror that here.
          colors = {
            rust = c.white.bright;
            python = c.white.bright;
            javascript = c.white.bright;
            typescript = c.white.bright;
            java = c.white.bright;
            csharp = c.white.bright;
            cpp = c.white.bright;
            go = c.white.bright;
            ruby = c.white.bright;
            php = c.white.bright;
            swift = c.white.bright;
            kotlin = c.white.bright;
            nix = c.white.bright;

            markup = c.white.bright;
            style = c.white.bright;
            web_config = c.white.bright;

            shell = c.white.bright;
            script = c.white.bright;

            doc = c.green.base;

            image = c.green.base;
            video = c.green.base;
            audio = c.green.base;

            data = c.green.base;
            archive = c.green.base;

            rs = c.white.bright;
            py = c.white.bright;
            js = c.white.bright;
            ts = c.white.bright;
            jsx = c.white.bright;
            tsx = c.white.bright;
            vue = c.white.bright;
            css = c.white.bright;
            scss = c.white.bright;
            html = c.white.bright;
            md = c.white.bright;
            json = c.white.bright;
            yaml = c.white.bright;
            toml = c.white.bright;
            sql = c.white.bright;
          };
        };
      };
    };
  };
}
