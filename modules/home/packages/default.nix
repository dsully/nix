{
  flake,
  pkgs,
  ...
}: {
  imports = [
    ./development.nix
    ./editor.nix
    ./nix.nix
    ./rust.nix
    ./system.nix
  ];

  home = {
    # Handle merging nixpkgs, the packages in this flake and allowing dependent to use the packages from this flake.
    packages = with (pkgs // ((flake.inputs.upstream or flake).packages.${pkgs.system} or {}));
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
        safari-rs
        sps
      ]);
  };
}
