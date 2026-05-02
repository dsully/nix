{pkgs, ...}: let
  jsonFormat = pkgs.formats.json {};
  tomlFormat = pkgs.formats.toml {};
  yamlFormat = pkgs.formats.yaml {};
in {
  xdg.configFile = {
    "clangd/config.yaml".source = yamlFormat.generate "clangd-config" {
      CompileFlags = {
        Add = ["-xc++" "-Wall"];
        Remove = [];
        Compiler = "clang++";
      };

      Diagnostics = {
        ClangTidy = {
          Add = [
            "bugprone-*"
            "performance-*"
            "portability-*"
            "readability-*"
            "google-*"
            "misc-*"
            "modernize-*"
          ];
          Remove = "modernize-use-trailing-return-type";
          CheckOptions = {
            "readability-identifier-naming.VariableCase" = "CamelCase";
          };
        };
        UnusedIncludes = "Strict";
      };

      Completion.AllScopes = true;
      Hover.ShowAKA = true;

      InlayHints = {
        Designators = true;
        Enabled = true;
        ParameterNames = true;
        DeducedTypes = true;
      };

      Index.StandardLibrary = "Yes";
    };

    "repomix/repomix.config.json".source = jsonFormat.generate "repomix-config" {
      output = {
        filePath = "repomix-output.txt";
        style = "plain";
        removeComments = false;
        removeEmptyLines = false;
        topFilesLength = 5;
        showLineNumbers = false;
        copyToClipboard = false;
      };
      include = [];
      ignore = {
        useGitignore = true;
        useDefaultPatterns = true;
        customPatterns = [];
      };
      security.enableSecurityCheck = true;
    };

    "github-copilot/terms.json".source = jsonFormat.generate "copilot-terms" {
      dsully.version = "2021-10-14";
    };

    "ptpython/config.py".text = builtins.readFile ../../../dotfiles/ptpython/config.py;
  };

  home.file = {
    ".typos.toml".source = tomlFormat.generate "typos-config" {
      default = {
        extend-ignore-re = [
          "\\[[0-9a-f]{7}\\]"
          "(?Rm)^.*(#|--|//)\\s*spellchecker:disable-line$"
          "(?s)(#|--|//|)\\s*spellchecker:off.*?\\n\\s*(#|--|//)\\s*spellchecker:on"
          "\\bTLS_[A-Z0-9_]+(_anon_[A-Z0-9_]+)?\\b"
        ];
        extend-ignore-words-re = [
          "\\A[a-zA-Z]{1,3}\\z"
        ];
        extend-words = {
          AKS = "AKS";
          aks = "aks";
          electricrain = "electricrain";
          iterm = "iterm";
          noice = "noice";
          protols = "protols";
        };
      };

      files.extend-exclude = [
        "*.css"
        "*.lock"
        "*.min.css"
        "*.min.js"
        "*.plist"
        "*lock.json"
        ".git/"
        ".github/"
        ".typos.toml"
        "_typos.toml"
        "go.mod"
        "go.sum"
        "node_modules"
        "pnpm-lock.yaml"
        "typos.toml"
        "vendor/**/*"
      ];

      "type.fish".extend-words = {
        doas = "doas";
      };

      "type.lua".extend-words = {
        enew = "enew";
        vhyrro = "vhyrro";
        "}," = "},";
      };

      "type.rust".extend-words = {
        juxt = "juxt";
        ratatui = "ratatui";
      };

      "type.toml" = {};
      "type.toml.pyproject" = {};
      "type.toml.pyproject.extend-words"."]" = "]";
    };

    ".better-commits.json".source = jsonFormat.generate "better-commits" {
      check_status = true;
      commit_type = {
        enable = true;
        initial_value = "feat";
        max_items = 20;
        infer_type_from_branch = true;
        append_emoji_to_label = false;
        append_emoji_to_commit = false;
        options = [
          {
            value = "feat";
            label = "feat";
            hint = "A new feature";
            emoji = "✨";
            trailer = "Changelog: feature";
          }
          {
            value = "fix";
            label = "fix";
            hint = "A bug fix";
            emoji = "🐛";
            trailer = "Changelog: fix";
          }
          {
            value = "docs";
            label = "docs";
            hint = "Documentation only changes";
            emoji = "📚";
            trailer = "Changelog: documentation";
          }
          {
            value = "refactor";
            label = "refactor";
            hint = "A code change that neither fixes a bug nor adds a feature";
            emoji = "🔨";
            trailer = "Changelog: refactor";
          }
          {
            value = "perf";
            label = "perf";
            hint = "A code change that improves performance";
            emoji = "🚀";
            trailer = "Changelog: performance";
          }
          {
            value = "test";
            label = "test";
            hint = "Adding missing tests or correcting existing tests";
            emoji = "🚨";
            trailer = "Changelog: test";
          }
          {
            value = "build";
            label = "build";
            hint = "Changes that affect the build system or external dependencies";
            emoji = "🚧";
            trailer = "Changelog: build";
          }
          {
            value = "ci";
            label = "ci";
            hint = "Changes to our CI configuration files and scripts";
            emoji = "🤖";
            trailer = "Changelog: ci";
          }
          {
            value = "chore";
            label = "chore";
            hint = "Other changes that do not modify src or test files";
            emoji = "🧹";
            trailer = "Changelog: chore";
          }
          {
            value = "";
            label = "none";
          }
        ];
      };
      commit_scope = {
        enable = true;
        custom_scope = false;
        max_items = 20;
        initial_value = "app";
        options = [
          {
            value = "app";
            label = "app";
          }
          {
            value = "shared";
            label = "shared";
          }
          {
            value = "server";
            label = "server";
          }
          {
            value = "tools";
            label = "tools";
          }
          {
            value = "";
            label = "none";
          }
        ];
      };
      check_ticket = {
        infer_ticket = true;
        confirm_ticket = true;
        add_to_title = true;
        append_hashtag = false;
        prepend_hashtag = "Never";
        surround = "";
        title_position = "start";
      };
      commit_title.max_size = 70;
      commit_body = {
        enable = true;
        required = false;
      };
      commit_footer = {
        enable = true;
        initial_value = [];
        options = ["closes" "trailer" "breaking-change" "deprecated" "custom"];
      };
      breaking_change.add_exclamation_to_title = false;
      confirm_with_editor = false;
      confirm_commit = true;
      print_commit_output = true;
      branch_pre_commands = [];
      branch_post_commands = [];
      worktree_pre_commands = [];
      worktree_post_commands = [];
      branch_user = {
        enable = true;
        required = false;
        separator = "/";
      };
      branch_type = {
        enable = true;
        separator = "/";
      };
      branch_version = {
        enable = false;
        required = false;
        separator = "/";
      };
      branch_ticket = {
        enable = true;
        required = false;
        separator = "-";
      };
      branch_description = {
        max_length = 70;
        separator = "";
      };
      branch_action_default = "branch";
      branch_order = ["user" "version" "type" "ticket" "description"];
      enable_worktrees = true;
      overrides = {};
    };
  };
}
