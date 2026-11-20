{
  lib,
  pkgs,
  stdenv,
}: let
  packages = {
    aarch64-darwin = {
      suffix = "aarch64-apple-darwin";
      hash = "sha256-IoCzhGoJ7urPfqi2oTFr+s/he14QeHBkzJkPf5nd0t4=";
    };
    x86_64-linux = {
      suffix = "x86_64-unknown-linux-gnu";
      hash = "sha256-N5ZPAWwv1y4z1l8RygrUPVMd4UdWfbl7DEUu0N290yw=";
    };
  };
  source =
    packages.${stdenv.hostPlatform.system}
      or (throw "Unsupported system: ${stdenv.hostPlatform.system}");
in
  pkgs.stdenv.mkDerivation rec {
    pname = "octet";
    version = "0.10.6";

    src = pkgs.fetchurl {
      url = "https://github.com/skaft-software/octet/releases/download/v${version}/octet-${version}-${source.suffix}.tar.gz";
      inherit (source) hash;
    };

    dontConfigure = true;
    dontBuild = true;
    dontStrip = true;

    installPhase = ''
      runHook preInstall

      install -m755 -Dt $out/bin octet octet-host

      runHook postInstall
    '';

    meta = {
      description = "Pi-compatible coding agent in Rust";
      homepage = "https://github.com/skaft-software/octet";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
