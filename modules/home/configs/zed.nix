{
  lib,
  pkgs,
  ...
}: {
  programs.zed-editor = {
    enable = true;
    package = lib.mkIf pkgs.stdenv.isDarwin (lib.mkDefault null);

    userSettings = {
      telemetry.metrics = false;

      assistant = {
        default_model = {
          provider = "copilot_chat";
          model = "gemini-2.0-flash-001";
        };
        version = "2";
        enabled = true;
        button = true;
        dock = "right";
        enable_experimental_live_diffs = true;
      };

      buffer_font_family = "Monaspace Neon";
      buffer_font_size = 16;
      buffer_font_features = {
        calt = false;
        ss01 = false;
        ss02 = false;
        ss03 = false;
        ss05 = false;
        ss06 = false;
        ss07 = false;
        ss09 = false;
      };

      current_line_highlight = "none";
      cursor_blink = false;
      "experimental.theme_overrides" = {};
      features.edit_prediction_provider = "zed";

      file_types = {
        Dockerfile = ["Dockerfile" "dockerfile.*"];
        JSON = ["json" "jsonc" "*.code-snippets"];
      };

      gutter = {
        code_actions = true;
        line_numbers = false;
      };

      indent_guides.enabled = false;
      language_servers = ["!typescript-language-server" "..."];

      outline_panel = {
        button = false;
        dock = "right";
        indent_size = 10;
      };

      pane_split_direction_horizontal = "down";
      pane_split_direction_vertical = "right";
      project_panel.indent_size = 10;
      relative_line_numbers = false;
      restore_on_startup = "none";

      tab_bar = {
        show_nav_history_buttons = false;
        show = true;
      };

      tabs.file_icons = true;
      toolbar.quick_actions = true;

      terminal = {
        button = false;
        font_family = "Monaspace Neon";
        env = {
          EDITOR = "zed";
          GIT_EDITOR = "zed --wait";
        };
      };

      theme = {
        mode = "dark";
        light = "Nebula Glow";
        dark = "Nord";
      };

      ui_font_family = "Zed Plex Sans";
      ui_font_size = 16;
      use_smartcase_search = true;
      use_system_path_prompts = false;
      vim_mode = true;
      when_closing_with_no_tabs = "close_window";
      context_servers = {};

      slash_commands = {
        docs.enabled = true;
        project.enabled = true;
      };

      git = {
        git_gutter = "tracked_files";
        inline_blame.enabled = false;
      };

      git_panel = {
        button = true;
        dock = "right";
      };
    };

    userKeymaps = [
      {
        bindings = {
          "ctrl-h" = "workspace::ActivatePaneLeft";
          "ctrl-j" = "workspace::ActivatePaneDown";
          "ctrl-k" = "workspace::ActivatePaneUp";
          "ctrl-l" = "workspace::ActivatePaneRight";
          "cmd-l" = "assistant::ToggleFocus";
          "cmd-," = "zed::OpenSettings";
        };
      }
      {
        context = "(vim_mode == normal && !menu) || EmptyPane || SharedScreen";
        bindings = {
          "shift-h" = "pane::ActivatePrevItem";
          "shift-l" = "pane::ActivateNextItem";
        };
      }
      {
        context = "Editor && vim_mode == normal && !menu";
        bindings = {
          "g D" = "editor::GoToDeclaration";
          "g d" = "editor::GoToDefinition";
          "g h" = "editor::MoveToBeginningOfLine";
          "g I" = "editor::GoToImplementation";
          "g l" = "editor::MoveToEndOfLine";
          "g r" = "editor::FindAllReferences";
          "g y" = "editor::GoToTypeDefinition";
          "g r a" = "editor::ToggleCodeActions";
          "cmd-k" = "editor::Hover";
          "space f" = "editor::Format";
          "space c r" = "editor::Rename";
          ", b d" = "workspace::CloseWindow";
        };
      }
      {
        context = "Editor && vim_mode == visual && !menu";
        bindings = {
          "<" = "editor::Outdent";
          ">" = "editor::Indent";
          "g n" = "vim::SelectNext";
          "space c a" = "editor::ToggleCodeActions";
          "shift-j" = "editor::MoveLineDown";
          "shift-k" = "editor::MoveLineUp";
        };
      }
      {
        context = "Editor && vim_mode == insert";
        bindings = {
          "ctrl-k" = "editor::ShowSignatureHelp";
        };
      }
      {
        context = "ContextEditor > Editor && vim_mode == normal && !menu";
        bindings = {
          q = "workspace::ToggleRightDock";
        };
      }
      {
        context = "ProjectPanel && !editing";
        bindings = {
          q = "workspace::ToggleLeftDock";
        };
      }
      {
        context = "ProjectSearchBar";
        bindings = {
          escape = "pane::CloseActiveItem";
        };
      }
    ];

    userTasks = [
      {
        label = "lazygit";
        command = "lazygit";
        env = {};
        use_new_terminal = true;
        allow_concurrent_runs = false;
        reveal = "always";
        hide = "on_success";
        shell = "system";
      }
    ];
  };
}
