{pkgs, ...}: {
  system.stateVersion = 6;

  environment = {
    pathsToLink = ["/share/fish"];
    shells = with pkgs; [bashInteractive zsh fish];
    systemPackages = with pkgs; [
      apple-photos-export
      autorebase
      bacon
      claude-code
      ghostscript_headless
      git-ai-commit
      morlana
      nh
      nix-output-monitor
      reading-list-to-pinboard-rs
      # systemd-language-server
      turbo-commit
      werk
    ];
  };
}
