{
  lib,
  pkgs,
  stdenv,
}: let
  packages = {
    aarch64-darwin = {
      suffix = "darwin-arm64";
      hash = "sha256-RjvI2ndC2YlI4etohi+wx54di2SEMHR0c2NEg7Qq7G0=";
    };
    x86_64-linux = {
      suffix = "linux-x64";
      hash = "sha256-tfGjNJVfyerAB2xY7AVgWoH2dbX4IF/O6Va07QjPvmA=";
    };
  };
  source =
    packages.${stdenv.hostPlatform.system}
      or (throw "Unsupported system: ${stdenv.hostPlatform.system}");
in
  # Keep version in step with pi-bolt.nix: `pi compile --kit` takes only the matching release's archive.
  pkgs.stdenv.mkDerivation rec {
    pname = "pi-bolt-kit";
    version = "1.3.2";

    src = pkgs.fetchurl {
      url = "https://github.com/opensec-git/Pi-Bolt/releases/download/bolt-v${version}/${pname}-${source.suffix}.tar.gz";
      inherit (source) hash;
    };

    dontUnpack = true;

    installPhase = ''
      install -Dm644 $src $out/archive.tar.gz
    '';

    meta = {
      description = "Pi-Bolt compile kit for `pi compile --kit`";
      homepage = "https://github.com/opensec-git/Pi-Bolt";
      license = lib.licenses.mit;
      sourceProvenance = [lib.sourceTypes.binaryNativeCode];
      platforms = builtins.attrNames packages;
    };
  }
