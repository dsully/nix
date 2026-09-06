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
    rev = "d49f2365f1ca3dafdca978541f02abb523f2c417";
    version = "4.3.2-${rev}";

    src = fetchFromGitHub {
      owner = "nix-community";
      repo = "nh";
      inherit rev;
      hash = "sha256-EIAXZh7U5AOZEzFA9IjRgErwEIlNsnAs+3HNAJLjJJo=";
    };

    cargoHash = "sha256-wTwZhlPyYUBO07b2wTRZw9SAtjxMzy24bqIwx3YeXKo=";
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
