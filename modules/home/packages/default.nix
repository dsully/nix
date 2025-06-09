{
  perSystem,
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
    packages = with perSystem.self;
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
