{lib, ...}: {
  power.sleep.computer = 15;

  system.activationScripts.postActivation.text = lib.mkAfter ''
    launchctl load -w /System/Library/LaunchDaemons/com.apple.screensharing.plist 2>/dev/null || true
    launchctl load -w /System/Library/LaunchDaemons/com.apple.locate.plist 2>/dev/null || true
    launchctl unload -w /System/Library/LaunchAgents/com.apple.gamed.plist 2>/dev/null || true

    # Power management
    pmset -a hibernatemode 0 2>/dev/null || true
    pmset -a sms 0 2>/dev/null || true

    # System settings
    # systemsetup -setusingnetworktime on 2>/dev/null || true
    systemsetup -setrestartfreeze on 2>/dev/null || true

    # Disable Time Machine
    /usr/bin/tmutil disable 2>/dev/null || true

    # GateKeeper
    spctl --master-enable 2>/dev/null || true
    spctl --enable 2>/dev/null || true
  '';
}
