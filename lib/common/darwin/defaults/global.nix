{
  system = {
    defaults = {
      NSGlobalDomain = {
        "com.apple.mouse.tapBehavior" = 1;
        "com.apple.trackpad.enableSecondaryClick" = true;
        "com.apple.sound.beep.volume" = 0.5;

        # Enabling full keyboard access for all controls (enable Tab in modal dialogs, menu windows, etc.)
        AppleKeyboardUIMode = 3;

        # Disable press-and-hold for keys in favor of key repeat
        ApplePressAndHoldEnabled = false;

        AppleShowScrollBars = "Always";

        # Make macOS react faster to keystrokes.
        KeyRepeat = 4;
        InitialKeyRepeat = 15;

        NSAutomaticCapitalizationEnabled = false;
        NSAutomaticDashSubstitutionEnabled = false;
        NSAutomaticPeriodSubstitutionEnabled = false;
        NSAutomaticQuoteSubstitutionEnabled = false;
        NSAutomaticSpellingCorrectionEnabled = false;
        NSDocumentSaveNewDocumentsToCloud = false;

        # Expanded save panels.
        NSNavPanelExpandedStateForSaveMode = true;
        NSNavPanelExpandedStateForSaveMode2 = true;

        PMPrintingExpandedStateForPrint = true;
        PMPrintingExpandedStateForPrint2 = true;
      };

      universalaccess = {
        reduceMotion = true;
        reduceTransparency = true;
      };

      CustomUserPreferences = {
        # Completely Disable Dashboard
        "com.apple.dashboard" = {
          dashboard-enabled-state = 1;
          mcx-disabled = 1;
        };

        # Set Help Viewer windows to non-floating mode
        "com.apple.helpviewer" = {
          DevMode = true;
        };

        # Automatically quit printer app once the print jobs complete
        "com.apple.print.PrintingPrefs" = {
          "Quit When Finished" = true;
        };

        "com.apple.Security.Authorization" = {
          # Ignore ARD as the following discussion to fix the sudo with touch ID in the terminal:
          # https://apple.stackexchange.com/questions/411497/pam-tid-so-asks-for-password-instead-of-requesting-for-fingerprint-when-docked
          ignoreArd = true;
        };

        "com.apple.Spotlight" = {
          # Don't display first-time Spotlight messages
          showedFTE = 1;
          showedLearnMore = 1;
        };
      };
    };
  };
}
