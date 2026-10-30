{mkSystemModule, ...}:
mkSystemModule {
  name = "spotlight";

  config = {config, ...}: {
    system = {
      # Exclude Electron app data and build caches to cut mds_stores CPU. Runs as root, so paths are absolute.
      activationScripts.postActivation.text = ''
        USER_HOME="/Users/${config.system.primaryUser}"
        SPOTLIGHT_EXCLUSIONS=(
          "$USER_HOME/Library/Application Support/1Password"
          "$USER_HOME/Library/Application Support/Discord"
          "$USER_HOME/Library/Application Support/Eagle"
          "$USER_HOME/Library/Application Support/Fastmail"
          "$USER_HOME/Library/Application Support/Google/Chrome"
          "$USER_HOME/Library/Application Support/Granola"
          "$USER_HOME/Library/Application Support/LM Studio"
          "$USER_HOME/Library/Application Support/Marco"
          "$USER_HOME/Library/Application Support/Raindrop.io"
          "$USER_HOME/Library/Application Support/Signal"
          "$USER_HOME/Library/Application Support/Slack"
          "$USER_HOME/Library/Caches"
          "$USER_HOME/.cargo"
          "$USER_HOME/.rustup"
          "$USER_HOME/.npm"
          "$USER_HOME/.pnpm"
        )

        for dir in "''${SPOTLIGHT_EXCLUSIONS[@]}"; do
          if [ -d "$dir" ]; then
            touch "$dir/.metadata_never_index"
          fi
        done
      '';

      defaults = {
        CustomUserPreferences = {
          "com.apple.Spotlight" = {
            "NSStatusItem Visible Item-0" = false;

            # Don't display first-time Spotlight messages
            showedFTE = 1;
            showedLearnMore = 1;
          };
        };
      };
    };
  };
}
