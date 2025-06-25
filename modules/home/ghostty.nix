{
  lib,
  pkgs,
  ...
}: {
  programs.ghostty = {
    enable = true;
    package = null;

    settings = {
      # Default config: ghostty +show-config --default --docs
      # vim: ft=ghostty
      font-family = "Monaspace Neon";
      font-size = 16;
      theme = "nord";

      command = "${lib.getExe pkgs.fish}";

      working-directory = "home";

      # Window configuration
      window-inherit-working-directory = false;
      window-inherit-font-size = false;
      window-title-font-family = "Monaspace Neon";
      window-height = 50;
      window-width = 172;
      window-save-state = "always";
      window-new-tab-position = "end";

      # Shell integration
      shell-integration-features = "no-cursor,sudo,title";
      macos-titlebar-proxy-icon = "hidden";

      # Allow for Option-P, etc.
      clipboard-paste-protection = false;

      keybind = [
        # Remove once there is scroll back search.
        "super+alt+shift+j=write_scrollback_file:open"
        "super+shift+j=write_scrollback_file:paste"

        # Distinguish <C-i> from <Tab>
        "ctrl+i=text:\\x1b[105;5u"

        # "cmd+right=text:\\x05"
        # "cmd+left=text:\\x01"
        # "cmd+backspace=text:\\x15"

        # Restore <C-[> as being alias for ESC
        # "ctrl+left_bracket=text:\\x1b"
      ];
    };
  };
}
