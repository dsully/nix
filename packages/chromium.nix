{pkgs, ...}: let
  version = "137.0.7151.55-1.1";
  hdiutil = "/usr/bin/hdiutil";

  inherit (pkgs) lib;
in
  if pkgs.stdenv.isDarwin
  then
    with pkgs;
      pkgs.stdenvNoCC.mkDerivation rec {
        inherit version;
        pname = "chromium";

        src = pkgs.fetchurl {
          url = "https://github.com/ungoogled-software/ungoogled-chromium-macos/releases/download/${version}/ungoogled-chromium_${version}_arm64-macos.dmg";
          hash = "sha256-F7kskoQ7ieGfEoXzWSpfaGjls/XxOAVXMKMl/ETxXNE=";
        };

        sourceRoot = "Chromium.app";

        nativeBuildInputs = [
          _7zz
          makeWrapper
        ];

        unpackPhase = ''
          #!/bin/bash
          mkdir -p ./Applications
          ${hdiutil} attach -readonly -mountpoint mnt $src
          cp -r "mnt/${sourceRoot}" .
          ${hdiutil} detach -force mnt
        '';

        installPhase = ''
          #!/bin/bash
          runHook preInstall
          mkdir -p "$out/Applications/${sourceRoot}"
          cp -R . "$out/Applications/${sourceRoot}"

          /usr/bin/xattr -r -d com.apple.quarantine "$out/Applications/${sourceRoot}"

          makeWrapper "$out/Applications/Chromium.app/Contents/MacOS/Chromium" "$out/bin/${pname}"

          runHook postInstall
        '';

        meta = {
          description = "Google Chromium, sans integration with Google";
          homepage = "https://github.com/ungoogled-software/ungoogled-chromium";
          license = lib.licenses.bsd3;
          maintainers = with lib.maintainers; [sudosubin];
          platforms = ["aarch64-darwin"];
          mainProgram = pname;
        };
      }
  else pkgs.chromium
