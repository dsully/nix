{
  system = {
    defaults = {
      CustomUserPreferences = {
        NSGlobalDomain = {
          # Adding a context menu item for showing the Web Inspector in web views
          WebKitDeveloperExtras = true;
        };

        "com.apple.Safari" = {
          AlwaysRestoreSessionAtLaunch = true;
          AutoFillCreditCardData = false;
          AutoFillFromAddressBook = false;
          AutoFillMiscellaneousForms = false;
          AutoFillPasswords = false;
          AutoOpenSafeDownloads = true;
          Command1Through9SwitchesTabs = false;
          CommandClickMakesTabs = true;

          # Remove downloads list items
          # 0 = manually
          # 1 = when safari quits
          # 2 = upon successful download
          # 3 = after on day
          DownloadsClearingPolicy = 0;

          EnableEnhancedPrivacyInRegularBrowsing = true;
          EnableNarrowTabs = true;
          ExcludePrivateWindowWhenRestoringSessionAtLaunch = false;
          ExtensionsEnabled = true;

          # Making Safari's search banners default to Contains instead of Starts With
          FindOnPageMatchesWordStartsOnly = false;

          HistoryAgeInDaysLimit = 365000;
          HomePage = "https://sully.org/dan/start/";
          IncludeDevelopMenu = true;
          LastMinimumFontSize = 12;
          LocalFileRestrictionsEnabled = false;
          NeverUseBackgroundColorInToolbar = true;
          NewTabBehavior = 0;
          NewTabPageSetByUserGesture = 1;
          NewWindowBehavior = 0;
          OpenNewTabsInFront = false;
          OpenPrivateWindowWhenNotRestoringSessionAtLaunch = false;
          PreloadTopHit = false;
          PrintHeadersAndFooters = false;
          PrivateBrowsingRequiresAuthentication = true;
          PrivateSearchEngineUsesNormalSearchEngineToggle = true;
          ReadingListSaveArticlesOfflineAutomatically = true;
          SafariProfilesLastActiveProfileUUIDString = "DefaultProfile";
          SendDoNotTrackHTTPHeader = true;
          ShowBackgroundImageInFavorites = false;
          ShowFavoritesBar = false;
          ShowFavoritesUnderSmartSearchField = false;
          ShowFullURLInSmartSearchField = true;
          ShowIconsInTabs = true;
          ShowOverlayStatusBar = true;
          ShowSidebarInNewWindows = false;
          ShowSidebarInTopSites = false;
          UseHTTPSOnly = false;

          # Disable the standard delay in rendering a Web page.
          WebKitInitialTimedLayoutDelay = 0.25;
          WebKitResourceTimedLayoutDelay = 0.0001;

          # Include Safari Suggestions
          UniversalSearchEnabled = false;
        };
      };
    };
  };
}
