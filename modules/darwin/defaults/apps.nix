{
  system = {
    defaults = {
      CustomUserPreferences = {
        "at.EternalStorms.Yoink" = {
          ess_userWantsToReviewApp = false;
          fnToIgnore = 1;
          isFirstLaunchOf1Dot5 = false;
          shouldHideOnLaunch = true;
          windowCorner = 5;
        };

        "co.podzim.BoltGPT" = {
          SUAutomaticallyUpdate = 1;
          SUEnableAutomaticChecks = 1;
          SUHasLaunchedBefore = 1;
          aiAssistantsEnabled = 0;
          aiAssistantsTriggerMethod = 1;
          appIcon = "AltIcon2";
          autoGenerateTitle = 1;
          codeBlockForceDarkTheme = 0;
          composeShowRecordSpeechButton = 0;
          composeShowVoiceModeButton = 0;
          confirmDeleteChat = 0;
          fontSize = 13;
          hideStatusBarIcon = 1;
          masShareCrashReport = 0;
          masSharePerformanceReport = 0;
          onboardingOpened = 1;
          promptLibraryEnabled = 0;
          promptLibraryTriggerMethod = 1;
          rememberModelSettingsForAllChats = 1;
          replicateServiceHidden = 1;
          showCost = 0;
          showSuggestedPrompt = 0;
          sidebarFontSize = 13;
          systemInstruction = "You are BoltAI, an expert progammer in Python, Lua, Rust, Nix, TypeScript, JavaScript and Swift";
          textSizeAdjustment = 0;
          useLaTeX = 0;
          useMarkdown = 1;
        };

        "com.google.Chrome" = {
          # Use the system-native print preview dialog
          DisablePrintPreview = true;

          # Expand the print dialog by default
          PMPrintingExpandedStateForPrint2 = true;

          # https://support.google.com/chrome/thread/14193532?hl=en
          ExternalProtocolDialogShowAlwaysOpenCheckbox = true;
        };

        "com.google.Chrome.canary" = {
          PMPrintingExpandedStateForPrint2 = true;
          DisablePrintPreview = true;
        };

        "com.mitchellh.ghostty" = {
          SUAutomaticallyUpdate = false;
          SUEnableAutomaticChecks = false;
          SUHasLaunchedBefore = true;
          SUSendProfileInfo = false;
        };

        "com.quip.Desktop" = {
          SUAutomaticallyUpdate = false;
          SUEnableAutomaticChecks = false;
          SUHasLaunchedBefore = true;
          WebAutomaticSpellingCorrectionEnabled = false;
        };

        "com.raycast.macos" = {
          "NSStatusItem Visible raycastIcon" = false;
          hasShownStatusBarHintAfterOnboarding = true;
          onboardingSkipped = true;
          onboarding_completedTaskIdentifiers = [
            "calendar"
            "quicklinks"
            "floatingNotes"
            "startWalkthrough"
            "raycastShortcuts"
            "windowManagement"
            "openActionPanel"
            "snippets"
            "calculator"
            "installFirstExtension"
            "setHotkeyAndAlias"
          ];
          onboarding_setupAlias = true;
          onboarding_setupHotkey = true;
          onboarding_showTasksProgress = true;
          raycastGlobalHotkey = "Command-49";
          raycastPreferredWindowMode = "default";
          raycastShouldFollowSystemAppearance = true;
          showGettingStartedLink = false;
          useHyperKeyIcon = false;
        };

        "net.matthewpalmer.Rocket" = {
          "deactivated-apps" = [
            "Slack"
            "Xcode"
            "Terminal"
            "Quicken"
            "Code"
            "Finder"
            "Raycast"
            "Ghostty"
            "Screens 5"
            "Safari"
            "Google Chrome"
            "ChatGPT"
            "BoltAI"
            "Zed"
          ];
          "hot-key-b8-iaK-thyib-yoV-Kep-It" = ":";
          "launch-at-login" = 1;
        };
      };
    };
  };
}
