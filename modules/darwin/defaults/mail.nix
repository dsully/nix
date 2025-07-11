{
  system = {
    defaults = {
      CustomUserPreferences = {
        "com.apple.mail" = {
          # Copy email addresses as `foo@example.com` instead of `Foo Bar <foo@example.com>` in Mail.app
          AddressesIncludeNameOnPasteboard = false;

          # Sort conversations in descending order (recent on the top)
          ConversationViewSortDescending = true;

          # Disable send and reply animations in Mail.app
          DisableReplyAnimations = true;
          DisableSendAnimations = true;

          NSUserKeyEquivalents = {
            Send = "@\\U21a9";
          };
        };
      };
    };
  };
}
