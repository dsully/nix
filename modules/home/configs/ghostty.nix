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

      working-directory = "home";

      # Window configuration
      window-inherit-working-directory = false;
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

      keybind = [
        # Distinguish <C-i> from <Tab>
        "ctrl+i=text:\\x1b[105;5u"

        # Restore <C-[> as being alias for ESC
        # "ctrl+left_bracket=text:\\x1b"
      ];
    };
  };
}
