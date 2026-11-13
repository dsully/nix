{
  lib,
  stdenvNoCC,
  fetchurl,
}:
# Output is a bundle archive for `octet extension install --path`, not a directory.
stdenvNoCC.mkDerivation rec {
  pname = "octet-pi-compat";
  version = "0.10.4";

  src = fetchurl {
    url = "https://github.com/skaft-software/octet/releases/download/v${version}/${pname}-${version}.tar.gz";
    hash = "sha256-ePvq4P64AhZ6QMYOUunojpF1miSHM0koHmQYP0r5TYE=";
  };

  patches = [
    ./follow-agent-dir-symlinks.patch
    ./raise-reviewed-source-limit.patch
    ./probe-background-refresh-as-absent.patch
    # DisturbedOcean/octet branch pi-provider-streams; needs a managed Pi release (packages/pi-release).
    ./run-extension-provider-streams.patch
    ./repaint-only-on-session-change.patch
    ./extension-provider-streams-outside-tool-calls.patch
  ];

  dontConfigure = true;
  dontBuild = true;
  dontFixup = true;

  installPhase = ''
    runHook preInstall

    cd ..
    tar --sort=name --mtime=@1 --owner=0 --group=0 --numeric-owner -cf - ${pname} | gzip -n > $out

    runHook postInstall
  '';

  meta = {
    description = "Octet's Pi adapter, patched for home-manager symlinks and Pi 1.5 extension-owned providers";
    homepage = "https://github.com/skaft-software/octet";
    license = lib.licenses.mit;
  };
}
