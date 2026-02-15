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

    # TCP performance tuning
    sysctl -w net.inet.tcp.delayed_ack=0 2>/dev/null || true
    sysctl -w net.inet.tcp.mssdflt=1448 2>/dev/null || true
    sysctl -w net.inet.tcp.blackhole=2 2>/dev/null || true
    sysctl -w net.inet.tcp.sendspace=3125000 2>/dev/null || true
    sysctl -w net.inet.tcp.recvspace=3125000 2>/dev/null || true
    sysctl -w net.inet.tcp.win_scale_factor=6 2>/dev/null || true
    sysctl -w net.inet.tcp.autorcvbufmax=3125000 2>/dev/null || true
    sysctl -w net.inet.tcp.autosndbufmax=3125000 2>/dev/null || true
  '';
}
