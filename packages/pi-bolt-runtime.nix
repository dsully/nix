{
  lib,
  pkgs,
  stdenv,
}: let
  packages = {
    aarch64-darwin = {
      suffix = "darwin-arm64";
      hash = "sha256-iXjuugx3cAmfhLK66U97t6rc6EqjbmtbNVqnwycPrBs=";
    };
    x86_64-linux = {
      suffix = "linux-x64";
      hash = "sha256-iocH/hZxGpHTOTZFDNUKxuJm75nmnjwJ5SZlJUKi1J8=";
    };
  };
  source =
    packages.${stdenv.hostPlatform.system}
      or (throw "Unsupported system: ${stdenv.hostPlatform.system}");
in
  # Keep version in step with pi-bolt.nix: `pi compile --runtime` takes only the matching release's archive.
  pkgs.stdenv.mkDerivation rec {
    pname = "pi-bolt-runtime";
    version = "1.1.7";

    src = pkgs.fetchurl {
      url = "https://github.com/opensec-git/Pi-Bolt/releases/download/bolt-v${version}/${pname}-${source.suffix}.tar.gz";
      inherit (source) hash;
    };

    dontUnpack = true;

    installPhase = ''
      install -Dm644 $src $out/archive.tar.gz
    '';

    meta = {
      description = "Pi-Bolt runtime for `pi compile --runtime`";
      homepage = "https://github.com/opensec-git/Pi-Bolt";
      license = lib.licenses.mit;
      sourceProvenance = [lib.sourceTypes.binaryNativeCode];
      platforms = builtins.attrNames packages;
    };
  }
