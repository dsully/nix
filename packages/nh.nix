{
  lib,
  pkgs,
  rustPlatform,
  fetchFromGitHub,
  rom,
  wrapperLib,
}: let
  unwrapped = rustPlatform.buildRustPackage (finalAttrs: rec {
    pname = "nh";
    rev = "d2a7aa0c40cb0d2e1c433789e369c61fe63e1a76";
    version = "4.3.2-${rev}";

    src = fetchFromGitHub {
      owner = "nix-community";
      repo = "nh";
      inherit rev;
      hash = "sha256-ft0eSHTwEN/3Uf7GHt+uTsKKtweFpHDPtXqG5QNElf0=";
    };

    cargoHash = "sha256-WkTJ8pMNljzYBD1iPAgWqs3C9V+Ugvcjhpl4n7ULBCs=";
    doCheck = false;

    # Make the build output monitor configurable via NH_MONITOR. The wrapper
    # below then defaults it to rom, a drop-in for nix-output-monitor that reads
    # the same internal-json stream.
    patches = [./nh-rom.patch];

    env.NH_REV = rev;

    postInstall = ''
      rm $out/bin/xtask
    '';

    meta = {
      description = "Yet another Nix CLI helper. [Maintainers=@NotAShelf, @faukah";
      homepage = "https://github.com/nix-community/nh";
      changelog = "https://github.com/nix-community/nh/blob/${finalAttrs.src.rev}/CHANGELOG.md";
      license = lib.licenses.eupl12;
      mainProgram = pname;
    };
  });
in
  # pname, version, and meta (including mainProgram) carry over from `package`.
  wrapperLib.wrapPackage {
    inherit pkgs;

    package = unwrapped;

    # `--set-default`, so NH_MONITOR from the environment still wins.
    envDefault.NH_MONITOR = "rom";

    # Keep rom on PATH so the wrapped binary always finds it.
    runtimePkgs = [
      {
        data = rom;
        prefix = true;
      }
    ];
  }
