{
  lib,
  pkgs,
  ...
}: {
  # Fix mermaid: https://discourse.nixos.org/t/mermaid-cli-on-macos/45096/3
  environment = {
    # https://github.com/nix-darwin/nix-darwin/issues/943
    profiles = lib.mkOrder 700 [
      "\$HOME/.local/state/nix/profile"
      "/etc/profiles/per-user/$USER"
    ];

    shells = [pkgs.fish];

    systemPackages = with pkgs; [
      mas
      safari-rs
      sps
    ];
  };

  programs = {
    fish.enable = true;
  };
}
