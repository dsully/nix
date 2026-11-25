{
  lib,
  pkgs,
  stdenv,
}: let
  packages = {
    aarch64-darwin = {
      suffix = "darwin-arm64";
      hash = "sha256-tK0yuAcVfM6DUYxMyT6b/b0+uk6qz2cLzfuBlZap2wI=";
    };
    x86_64-linux = {
      suffix = "linux-x64";
      hash = "sha256-qacWgzvmMJar8n50UVUZyeYNmdiX9gXLbpkpUv6BT28=";
    };
  };
  source =
    packages.${stdenv.hostPlatform.system}
      or (throw "Unsupported system: ${stdenv.hostPlatform.system}");
in
  # Keep version in step with pi-bolt.nix: `pi compile --kit` takes only the matching release's archive.
  pkgs.stdenv.mkDerivation rec {
    pname = "pi-bolt-kit";
    version = "1.3.1";

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
