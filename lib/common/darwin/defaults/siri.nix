{
  system = {
    defaults = {
      CustomUserPreferences = {
        "com.apple.Siri" = {
          ConfirmSiriInvokedViaEitherCmdTwice = 0;
          ContinuousSpellCheckingEnabled = 0;
          GrammarCheckingEnabled = 1;
          KeyboardShortcutPreSAE = {
            enabled = 0;
          };
          KeyboardShortcutSAE = {
            enabled = 0;
          };
          StatusMenuVisible = 0;
          VoiceTriggerUserEnabled = 0;
        };

        "com.apple.assistant.support" = {
          # "disable" Enable Ask Siri
          "Assistant Enabled" = false;
        };
      };
    };
  };
}
