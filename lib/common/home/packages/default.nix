{pkgs, ...}: {
  imports = [
    ./development.nix
    ./editor.nix
    ./nix.nix
    ./rust.nix
    ./system.nix
  ];

  home = {
    packages = with pkgs;
      [
        devmoji-log
        dirstat-rs
        feluda
        geil
        git-trim
        lolcate-rs
        magic-opener
      ]
      ++ (lib.optionals pkgs.stdenv.isDarwin [
        safari-rs
        sps
      ]);
  };
}
