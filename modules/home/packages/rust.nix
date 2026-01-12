{pkgs, ...}: {
  home = {
    packages = with pkgs; [
      cargo-autoinherit
      cargo-binstall
      cargo-bloat
      cargo-bump
      cargo-cache
      cargo-clone
      cargo-dist
      cargo-duplicates
      cargo-edit
      cargo-expand
      cargo-features-manager
      cargo-flamegraph
      cargo-hakari
      cargo-insta
      cargo-llvm-lines
      cargo-msrv
      cargo-nextest
      cargo-run-bin
      cargo-shear
      cargo-sort
      cargo-sweep
      cargo-tarpaulin
      cargo-udeps
      cargo-unused-features
      cargo-wizard
      rustcat
      rustup
      samply
      sccache
    ];
  };
}
