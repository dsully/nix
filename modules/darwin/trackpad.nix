{mkSystemModule, ...}: let
  trackpads = {
    TrackpadCornerSecondaryClick = 2;
    TrackpadFiveFingerPinchGesture = 0;
    TrackpadFourFingerHorizSwipeGesture = 0;
    TrackpadFourFingerPinchGesture = 0;
    TrackpadFourFingerVertSwipeGesture = 0;
    TrackpadHorizScroll = 1;
    TrackpadMomentumScroll = 1;
    TrackpadPinch = false;
    TrackpadRightClick = false;
    TrackpadRotate = false;
    TrackpadScroll = true;
    TrackpadThreeFingerHorizSwipeGesture = 0;
    TrackpadThreeFingerVertSwipeGesture = 0;
    TrackpadTwoFingerDoubleTapGesture = 0;
    TrackpadTwoFingerFromRightEdgeSwipeGesture = 0;
    USBMouseStopsTrackpad = false;
    UserPreferences = 1;
  };
in
  mkSystemModule {
    name = "trackpad";

    config = {
      system = {
        defaults = {
          trackpad = {
            Clicking = true;
            Dragging = false;
            TrackpadRightClick = true;
            TrackpadThreeFingerDrag = false;
            TrackpadThreeFingerTapGesture = 2;
          };

          CustomUserPreferences = {
            # Internal Trackpad
            "com.apple.AppleMultitouchTrackpad" = trackpads;

            # Magic Trackpad
            "com.apple.driver.AppleBluetoothMultitouch.trackpad" = trackpads;
          };
        };
      };
    };
  }
