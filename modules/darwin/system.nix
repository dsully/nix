{lib, ...}: {
  power.sleep.computer = 15;

  # TCP performance tuning via LaunchDaemon (persists across reboots)
  # https://rolande.wordpress.com/2025/08/07/performance-tuning-the-network-stack-on-macos-sequoia-15-6/
  launchd.daemons.sysctl-tcp-tuning = {
    serviceConfig = {
      ProgramArguments = [
        "/usr/sbin/sysctl"
        "-w"
        "net.inet.tcp.delayed_ack=0"
        "net.inet.tcp.mssdflt=1360"
        "net.inet.tcp.blackhole=2"
        "net.inet.tcp.win_scale_factor=7"
        "net.inet.tcp.sendspace=861275"
        "net.inet.tcp.recvspace=861275"
        "net.inet.tcp.autorcvbufmax=8388608"
        "net.inet.tcp.autosndbufmax=8388608"
      ];
      RunAtLoad = true;
      LaunchOnlyOnce = true;
    };
  };

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
  '';
}
