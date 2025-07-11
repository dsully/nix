{pkgs, ...}: {
  home = {
    packages = with pkgs; [
      cargo-autoinherit
      cargo-binstall
      cargo-bloat
      cargo-cache
      cargo-clone
      cargo-dist
      cargo-duplicates
      cargo-edit
      cargo-features-manager
      cargo-insta
      cargo-llvm-lines
      cargo-msrv
      cargo-nextest
      cargo-run-bin
      cargo-shear
      cargo-sweep
      cargo-tarpaulin
      cargo-unused-features
      cargo-update
      cargo-wizard
      rustcat
      rustup
      sccache
    ];
  };
}
