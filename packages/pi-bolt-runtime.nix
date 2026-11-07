{
  lib,
  pkgs,
  stdenv,
}: let
  packages = {
    aarch64-darwin = {
      suffix = "darwin-arm64";
      hash = "sha256-NuKHvFs9Vsj6wr6ieFJwWZb293awzuZ6arYT0tt9xcg=";
    };
    x86_64-linux = {
      suffix = "linux-x64";
      hash = "sha256-Z79HShxuIGWeAxLMiN0vW9qf1Ja6RLWHTinjRQZv+x0=";
    };
  };
  source =
    packages.${stdenv.hostPlatform.system}
      or (throw "Unsupported system: ${stdenv.hostPlatform.system}");
in
  # Keep version in step with pi-bolt.nix: `pi compile --runtime` takes only the matching release's archive.
  pkgs.stdenv.mkDerivation rec {
    pname = "pi-bolt-runtime";
    version = "1.1.4";

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
