{
  lib,
  stdenvNoCC,
  fetchurl,
}:
# Output is a bundle archive for `octet extension install --path`, not a directory.
stdenvNoCC.mkDerivation rec {
  pname = "octet-pi-compat";
  version = "0.10.3";

  src = fetchurl {
    url = "https://github.com/skaft-software/octet/releases/download/v${version}/${pname}-${version}.tar.gz";
    hash = "sha256-GBSNDqrDX3vPi42E1RejACU2MJfGiEv6f9PL3Wl5LUc=";
  };

  patches = [
    ./follow-agent-dir-symlinks.patch
    ./raise-reviewed-source-limit.patch
    ./ignore-unknown-theme-colors.patch
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
    description = "Octet's Pi adapter, patched to follow home-manager symlinks in the Pi agent dir";
    homepage = "https://github.com/skaft-software/octet";
    license = lib.licenses.mit;
  };
}
