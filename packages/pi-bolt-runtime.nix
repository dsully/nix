{
  lib,
  pkgs,
  stdenv,
}: let
  packages = {
    aarch64-darwin = {
      suffix = "darwin-arm64";
      hash = "sha256-dwHyX/Nyr/IXt3F70d5ZCnxe+OEEyyIZAYQtLL0gcVE=";
    };
    x86_64-linux = {
      suffix = "linux-x64";
      hash = "sha256-iBab0pNzmQXFpQSORdpmvMaAi0fm2fgkgeKLiSlcgvQ=";
    };
  };
  source =
    packages.${stdenv.hostPlatform.system}
      or (throw "Unsupported system: ${stdenv.hostPlatform.system}");
in
  # Keep version in step with pi-bolt.nix: `pi compile --runtime` takes only the matching release's archive.
  pkgs.stdenv.mkDerivation rec {
    pname = "pi-bolt-runtime";
    version = "1.3.0";

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
