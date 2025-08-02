{pkgs, ...}:
with pkgs; let
  platformData = {
    "x86_64-linux" = {
      filename = "opencode-linux-x64.zip";
      hash = "sha256-zgKSa76UypHFpG6XVl4/jSdfGmwv0zUvf5n1WPa2Dgk=";
    };
    "aarch64-darwin" = {
      filename = "opencode-darwin-arm64.zip";
      hash = "sha256-fdhvD/SQ/nCGl1ALaBm8ZyWCadasKTRqHwV8muEYt78=";
    };
  };

  currentPlatform = platformData.${stdenvNoCC.hostPlatform.system} or (throw "Unsupported platform: ${stdenvNoCC.hostPlatform.system}");
in
  stdenvNoCC.mkDerivation rec {
    pname = "opencode-updated";
    version = "0.3.112";

    src = fetchurl {
      url = "https://github.com/sst/opencode/releases/download/v${version}/${currentPlatform.filename}";
      inherit (currentPlatform) hash;
    };

    # Nix's built in zip has issues with the opencode archive.
    nativeBuildInputs = [unzip];
    dontUnpack = true;

    installPhase = ''
      runHook preInstall

      unzip "$src"

      mkdir -p $out/bin
      cp opencode $out/bin/opencode
      chmod +x $out/bin/opencode

      runHook postInstall
    '';

    meta = with lib; {
      description = "AI coding agent built for the terminal";
      homepage = "https://github.com/sst/opencode";
      license = licenses.mit;
      platforms = ["x86_64-linux" "aarch64-darwin"];
      mainProgram = "opencode";
    };
  }
