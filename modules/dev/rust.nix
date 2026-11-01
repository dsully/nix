{
  lib,
  mkUserModule,
  my,
  pkgs,
  ...
}: let
  inherit (my.pkgs) mbx;
  cargoShimDir = "${mbx}/libexec/mbx";

  # rust-analyzer reads its user file from dirs::config_dir(), which ignores XDG on macOS.
  rustAnalyzerConfig = "${
    if pkgs.stdenv.hostPlatform.isDarwin
    then "Library/Application Support"
    else ".config"
  }/rust-analyzer/rust-analyzer.toml";
in
  mkUserModule {
    name = "rust";

    home = {
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
          cargo-machete
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
          mbx
          rustcat
          rustup
          samply
          sccache
        ];

        # mbx's cargo shim must precede rustup's ~/.cargo/bin/cargo; it drops itself from PATH to find the real one.
        sessionPath = lib.mkBefore [cargoShimDir];

        # Mirrors what `mbx setup` writes, so editor checks share mbx's cache without touching terminal builds' target dir.
        file.${rustAnalyzerConfig}.source = (pkgs.formats.toml {}).generate "rust-analyzer.toml" {
          check.overrideCommand = [
            "${cargoShimDir}/cargo"
            "check"
            "--workspace"
            "--all-targets"
            "--target-dir"
            "target/rust-analyzer"
            "--message-format=json"
          ];
        };
      };
    };
  }
