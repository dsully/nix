{mkSystemModule, ...}:
mkSystemModule {
  name = "contacts";

  config = {
    system = {
      defaults = {
        CustomUserPreferences = {
          NSGlobalDomain = {
            # Show first name
            # 1 = before last name
            # 2 = after last name
            NSPersonNameDefaultDisplayNameOrder = 1;

            # Prefer nicknames
            NSPersonNameDefaultShouldPreferNicknamesPreference = 1;

            # Short name only
            NSPersonNameDefaultShortNameEnabled = 1;
            NSPersonNameDefaultShortNameFormat = 3;
          };
        };
      };
    };
  };
}
