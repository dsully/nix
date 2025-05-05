{
  system = {
    defaults = {
      CustomUserPreferences = {
        # Disable auto correct and other substitutions in Message.app.
        "com.apple.messageshelper.MessageController" = {
          SOInputLineSettings = {
            automaticQuoteSubstitutionEnabled = false;
            automaticEmojiSubstitutionEnablediMessage = false; # spellchecker:disable-line
            continuousSpellCheckingEnabled = false;
          };
        };
      };
    };
  };
}
