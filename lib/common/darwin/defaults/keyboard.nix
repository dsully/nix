{
  system = {
    defaults = {
      CustomUserPreferences = {
        # https://stackoverflow.com/questions/21878482/what-do-the-parameter-values-in-applesymbolichotkeys-plist-dict-represent
        # https://apple.stackexchange.com/questions/474904/what-does-each-part-in-com-apple-symbolichotkeys-plist-mean
        #
        # https://github.com/NUIKit/CGSInternal/blob/master/CGSHotKeys.h
        #
        "com.apple.SymbolicHotkeys" = {
          AppleSymbolicHotKeys = {
            # Move focus to the menu bar - Control, F2
            "7" = {enabled = false;};

            # Move focus to the Dock - Control, F3
            "8" = {enabled = false;};

            # Move focus to active or next window - Control, F4
            "9" = {enabled = false;};

            # Move focus to window toolbar - Control, F5
            "10" = {enabled = false;};

            # Move focus to floating window - Control, F6
            "11" = {enabled = false;};

            # ??? - Control, F1
            "12" = {enabled = false;};

            # Change the way Tab moves focus - Control, F7
            "13" = {enabled = false;};

            # # Turn zoom on or off - Command, Option, 8
            # 15 = { enabled = 1; value = { parameters = ( 56, 28, 1572864 ); type = standard; }; };
            #
            # # Zoom in - Command, Option, =
            # 17 = { enabled = 0; value = { parameters = ( 61, 24, 1572864 ); type = standard; }; };
            #
            # # Zoom out - Command, Option, -
            # 19 = { enabled = 0; value = { parameters = ( 45, 27, 1572864 ); type = standard; }; };

            # Reverse Black and White - Command, Control, Option, 8
            "21" = {enabled = false;};

            # # Turn image smoothing on or off - Command, Option, \
            # 23 = { enabled = 0; value = { parameters = ( 92, 42, 1572864 ); type = standard; }; };
            #
            # # Increase Contrast - Command, Control, Option, .
            "25" = {enabled = false;};

            # Decrease Contrast - Command, Control, Option, ','
            "26" = {enabled = false;};

            # Move focus to the next window in application - Command, backtic
            "27" = {enabled = true;};

            # Save picture of screen as file - Command, Shift, 3
            "28" = {enabled = false;};

            # Copy picture of screen to clipboard - Command, Control, Shift, 3
            "29" = {enabled = false;};

            # Save picture of selected area as file - Command, Shift, 4
            "30" = {enabled = false;};

            # Copy picture of selected area to clipboard - Command, Control, Shift, 4
            "31" = {enabled = false;};

            # All Windows - F9
            "32" = {enabled = false;};

            # Application Windows - F10
            "33" = {enabled = false;};

            # # All Windows (Slow) - F9
            # 34 = { enabled = 1; value = { parameters = ( 65535, 101, 131072 ); type = standard; }; };
            #
            # # Application Windows (Slow) - F10
            # 35 = { enabled = 1; value = { parameters = ( 65535, 109, 131072 ); type = standard; }; };
            #
            # Desktop - F11
            "36" = {enabled = false;};

            # # Desktop (Slow) - F11
            # 37 = { enabled = 1; value = { parameters = ( 65535, 103, 131072 ); type = standard; }; };
            #
            # # ??? - Command, Option, T
            # 50 = { enabled = 1; value = { parameters = ( 116, 17, 1572864 ); type = standard; }; };
            #
            # # Move focus to the window drawer - Command, Option, quote
            # 51 = { enabled = 1; value = { parameters = ( 39, 50, 1572864 ); type = standard; }; };
            #
            # # Turn Dock Hiding On/Off - Command, Option, D
            "52" = {enabled = false;};

            # # ??? - F14
            # 53 = { enabled = 1; value = { parameters = ( 65535, 107, 0 ); type = standard; }; };
            #
            # # ??? - F15
            # 54 = { enabled = 1; value = { parameters = ( 65535, 113, 0 ); type = standard; }; };
            #
            # # ??? - Option, F14
            # 55 = { enabled = 1; value = { parameters = ( 65535, 107, 524288 ); type = standard; }; };
            #
            # # ??? - Option, F15
            # 56 = { enabled = 1; value = { parameters = ( 65535, 113, 524288 ); type = standard; }; };
            #
            # Move focus to the status menus - Control, F8
            "57" = {enabled = false;};

            # Turn VoiceOver on / off - Command, F5
            "59" = {enabled = false;};

            # Select the previous input source - Command, Option, Space
            "60" = {enabled = false;};

            # Select the next source in the Input Menu - Command, Option, Shift, Space
            "61" = {enabled = false;};

            # Dashboard - F12
            "62" = {enabled = false;};

            # # Dashboard (Slow) - F12
            "63" = {enabled = false;};

            # Show Spotlight search field - Command, Shift, Space
            "64" = {enabled = false;};

            # Show Spotlight window - Control, Shift, Space
            "65" = {enabled = false;};

            # # Dictionary MouseOver - Command, Shift, E
            # 70 = { enabled = 1; value = { parameters = ( 101, 2, 1179648 ); type = standard; }; };
            #
            # # Hide and show Front Row - Command, Esc
            # 73 = { enabled = 1; value = { parameters = ( 65535, 53, 1048576 ); type = standard; }; };
            #
            # # Activate Spaces - F8
            # 75 = { enabled = 1; value = { parameters = ( 65535, 100, 0 ); type = standard; }; };
            #
            # # Activate Spaces (Slow) - Shift, F8
            # 76 = { enabled = 1; value = { parameters = ( 65535, 100, 131072 ); type = standard; }; };
            #
            # # Spaces Left - Control, Left
            # 79 = { enabled = 1; value = { parameters = ( 65535, 123, 262144 ); type = standard; }; };
            #
            # # Spaces Right - Control, Right
            # 81 = { enabled = 1; value = { parameters = ( 65535, 124, 262144 ); type = standard; }; };
            #
            # # Spaces Down - Control, Down
            # 83 = { enabled = 1; value = { parameters = ( 65535, 125, 262144 ); type = standard; }; };
            #
            # # Spaces Up - Control, Up
            # 85 = { enabled = 1; value = { parameters = ( 65535, 126, 262144 ); type = standard; }; };
            #
            # # Show Help Menu - Command, Shift, /
            # 91 = { enabled = 0; };
            # 92 = { enabled = 0; };
            # 98 = { enabled = 0; value = { parameters = ( 47, 44, 1179648 ); type = standard; }; };
            #
            # # Switch to Space 1 - Control, 1
            # 118 = { enabled = 1; value = { parameters = ( 65535, 18, 262144 ); type = standard; }; };
            #
            # # Switch to Space 2 - Control, 2
            # 119 = { enabled = 1; value = { parameters = ( 65535, 19, 262144 ); type = standard; }; };
            #
            # # Switch to Space 3 - Control, 3
            # 120 = { enabled = 1; value = { parameters = ( 65535, 20, 262144 ); type = standard; }; };
            #
            # # Switch to Space 4 - Control, 4
            # 121 = { enabled = 1; value = { parameters = ( 65535, 21, 262144 ); type = standard; }; };
            #
            "159" = {enabled = false;};
            "162" = {enabled = false;};

            # Show Notification Center
            "163" = {enabled = false;};

            # Toggle Do Not Disturb
            "175" = {enabled = false;};

            # Siri
            "176" = {enabled = false;};

            #
            "184" = {enabled = false;};

            "215" = {enabled = false;};
            "216" = {enabled = false;};
            "217" = {enabled = false;};
            "218" = {enabled = false;};
            "219" = {enabled = false;};
            "222" = {enabled = false;};

            # Disable Command-M to minimize
            "223" = {enabled = false;};

            # Disable Presenter mode
            "224" = {enabled = false;};

            "225" = {enabled = false;};
            "226" = {enabled = false;};
            "227" = {enabled = false;};
            "228" = {enabled = false;};
            "229" = {enabled = false;};
            "230" = {enabled = false;};
            "231" = {enabled = false;};
            "232" = {enabled = false;};
            "233" = {enabled = false;};
            "235" = {enabled = false;};
            "237" = {enabled = false;};
            "238" = {enabled = false;};
            "239" = {enabled = false;};
            "240" = {enabled = false;};
            "241" = {enabled = false;};
            "242" = {enabled = false;};
            "243" = {enabled = false;};
            "244" = {enabled = false;};
            "245" = {enabled = false;};
            "246" = {enabled = false;};
            "247" = {enabled = false;};
            "248" = {enabled = false;};
            "249" = {enabled = false;};
            "250" = {enabled = false;};
            "251" = {enabled = false;};
            "256" = {enabled = false;};
            "257" = {enabled = false;};
            "258" = {enabled = false;};
          };
        };
      };

      hitoolbox = {
        AppleFnUsageType = "Do Nothing";
      };
    };
  };
}
