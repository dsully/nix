{
  flake,
  pkgs,
  ...
}: let
  local = (flake.inputs.upstream or flake).packages.${pkgs.system} or {};

  # Address: https://discourse.nixos.org/t/mermaid-cli-on-macos/45096/3
  mermaid = pkgs.mermaid-cli.override {inherit (local) chromium;};
in {
  imports = [
    ./development.nix
    ./editor.nix
    ./nix.nix
    ./rust.nix
    ./system.nix
  ];

  home = {
    # Handle merging nixpkgs, the packages in this flake and allowing dependent to use the packages from this flake.
    packages = with (pkgs // local);
      [
        devmoji-log
        dirstat-rs
        feluda
        geil
        git-trim
        lolcate-rs
        magic-opener
      ]
      ++ (pkgs.lib.optionals pkgs.stdenv.isDarwin [
        mermaid
        safari-rs
      ]);
  };
}
