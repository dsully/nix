{
  lib,
  pkgs,
  ...
}: {
  programs.ghostty = {
    enable = true;
    package = null;

    systemd.enable = false;

    settings = {
      # Default config: ghostty +show-config --default --docs
      # vim: ft=ghostty
      font-family = "Monaspace Neon";
      font-size = 16;
      theme = "nord";

      auto-update = "off";
      command = "${lib.getExe pkgs.fish}";
      link-previews = "osc8";
      link-url = true;
      right-click-action = "ignore";
      scrollback-limit = 20000000;

      split-inherit-working-directory = false;
      tab-inherit-working-directory = false;
      window-inherit-working-directory = false;
      working-directory = "home";

      # Window configuration
      window-inherit-font-size = false;
      window-title-font-family = "Monaspace Neon";
      window-height = 50;
      window-width = 172;
      window-save-state = "always";
      window-new-tab-position = "end";
      window-colorspace = "display-p3";

      # https://www.reddit.com/r/Ghostty/comments/1o9nzga/how_can_i_remove_the_paddinggap_along_the_borders/
      # window-padding-color = "extend-always";

      # Shell integration
      shell-integration-features = "no-cursor,sudo,title,ssh-env,ssh-terminfo";
      macos-titlebar-proxy-icon = "hidden";

      # Allow for Option-P, etc.
      clipboard-paste-protection = false;
      clipboard-read = "allow";

      # Vim-mode keybindings for Ghostty.
      #
      # https://gist.github.com/mitchellh/1c5be5c083a2315f22f1cb8f239e9dcd
      keybind = [
        # Entry point
        "alt+v=activate_key_table:vim"

        # Key table definition
        "vim/"

        # Line movement
        "vim/j=scroll_page_lines:1"
        "vim/k=scroll_page_lines:-1"

        # Page movement
        "vim/ctrl+d=scroll_page_down"
        "vim/ctrl+u=scroll_page_up"
        "vim/ctrl+f=scroll_page_down"
        "vim/ctrl+b=scroll_page_up"
        "vim/shift+j=scroll_page_down"
        "vim/shift+k=scroll_page_up"

        # Jump to top/bottom
        "vim/g>g=scroll_to_top"
        "vim/shift+g=scroll_to_bottom"

        # Search (if you want vim-style search entry)
        "vim/slash=start_search"
        "vim/n=navigate_search:next"

        # Copy mode / selection
        # Note we're missing a lot of actions here to make this more full featured.
        "vim/v=copy_to_clipboard"
        "vim/y=copy_to_clipboard"

        # Command Palette
        "vim/shift+semicolon=toggle_command_palette"

        # Exit
        "vim/escape=deactivate_key_table"
        "vim/q=deactivate_key_table"
        "vim/i=deactivate_key_table"

        # Catch unbound keys
        "vim/catch_all=ignore"

        # https://github.com/Franvy/gtab
        # "config-file=${config.xdg.configHome}/gtab/ghostty-shortcut.conf"
      ];
    };
  };
}
