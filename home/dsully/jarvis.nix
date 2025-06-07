{pkgs, ...}: {
  home = {
    packages = with pkgs; [
      apple-photos-export
      autorebase
      bacon
      claude-code
      ghostscript_headless
      git-ai-commit
      nix-output-monitor
      pandoc
      reading-list-to-pinboard-rs
      # systemd-language-server
      turbo-commit
      werk
    ];
  };
}
