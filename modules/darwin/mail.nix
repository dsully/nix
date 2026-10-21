{mkSystemModule, ...}:
mkSystemModule {
  name = "mail";

  config = {
    system = {
      defaults = {
        CustomUserPreferences = {
          "com.apple.mail" = {
            # Sort conversations in descending order (recent on the top)
            ConversationViewSortDescending = true;

            NSUserKeyEquivalents = {
              Send = "@\\U21a9";
            };
          };
        };
      };
    };
  };
}
