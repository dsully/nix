{
  config,
  lib,
  pkgs,
  ...
}: let
  c = config.colors;
in {
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
            end
        end

        ${lib.getExe pkgs.lla} $args
      '';
  };

  xdg.configFile."lla/config.toml".source = (pkgs.formats.toml {}).generate "lla-config" {
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
    exclude_paths = [
      "~/Library/Mobile Documents" # macOS iCloud Drive (Mobile Documents)
      "~/Library/CloudStorage" # macOS cloud storage providers
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
      respect_gitignore = true;

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
          ".git"
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

  xdg.configFile."lla/themes/nord.toml".source = (pkgs.formats.toml {}).generate "lla-theme-nord" {
    name = "nord";

    colors = {
      file = c.white.dim;
      directory = c.blue.base;
      symlink = c.cyan.bright;
      executable = c.white.bright;

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
      folders = {
        node_modules = {
          h = 0;
          s = 0;
          l = 0.15;
        };
        target = c.white.dim;
        dist = c.white.dim;
        ".git" = c.blue.base;
        build = c.white.dim;
        ".cache" = c.white.dim;
        "*-env" = c.white.bright;
        venv = c.white.bright;
        ".env" = c.white.bright;
        "*.d" = c.cyan.bright;
        "*_cache" = c.white.dim;
        "*-cache" = c.white.dim;
      };

      dotfiles = {
        ".gitignore" = c.blue.bright;
        ".env" = c.blue.base;
        ".dockerignore" = c.blue.bright;
        ".editorconfig" = c.blue.bright;
        ".prettierrc" = c.blue.bright;
        ".eslintrc" = c.blue.bright;
        ".babelrc" = c.blue.bright;
      };

      exact_match = {
        Dockerfile = c.blue.bright;
        "docker-compose.yml" = c.blue.bright;
        Makefile = c.red.base;
        "CMakeLists.txt" = c.red.base;
        "README.md" = c.blue.base;
        LICENSE = c.blue.base;
        "package.json" = c.blue.base;
        "Cargo.toml" = c.red.base;
        "go.mod" = c.blue.bright;
        "flake.nix" = c.blue.base;
        "flake.lock" = c.white.dim;
        "shell.nix" = c.blue.base;
        "default.nix" = c.blue.base;
      };

      patterns = {
        "*rc" = c.blue.bright;
        "*.min.*" = c.white.dim;
        "*.test.*" = c.white.bright;
        "*.spec.*" = c.white.bright;
        "*.lock" = c.white.dim;
        "*.config.*" = c.blue.bright;
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

      colors = {
        rust = c.red.base;
        python = c.white.bright;
        javascript = c.yellow.base;
        typescript = c.cyan.bright;
        java = c.red.base;
        csharp = c.white.bright;
        cpp = c.red.base;
        go = c.cyan.bright;
        ruby = c.red.base;
        php = c.white.bright;
        swift = c.red.base;
        kotlin = c.white.bright;
        nix = c.cyan.bright;

        markup = c.magenta.base;
        style = c.white.bright;
        web_config = c.blue.base;

        shell = c.white.bright;
        script = c.blue.base;

        doc = c.white.dim;

        image = c.orange.base;
        video = c.orange.base;
        audio = c.orange.base;

        data = c.blue.base;
        archive = c.red.base;

        rs = c.red.base;
        py = c.white.bright;
        js = c.yellow.base;
        ts = c.cyan.bright;
        jsx = c.yellow.base;
        tsx = c.cyan.bright;
        vue = c.white.bright;
        css = c.white.bright;
        scss = c.white.bright;
        html = c.magenta.base;
        md = c.white.dim;
        json = c.blue.base;
        yaml = c.blue.base;
        toml = c.blue.base;
        sql = c.cyan.bright;
      };
    };
  };
}
