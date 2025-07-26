{pkgs, ...}:
with pkgs; let
  platformData = {
    "x86_64-linux" = {
      filename = "opencode-linux-x64.zip";
      hash = "sha256-/3galcoxognh8aR3WBGhU6gvtP0V5fmPVBq3vPYZ9ok=";
    };
    "aarch64-darwin" = {
      filename = "opencode-darwin-arm64.zip";
      hash = "sha256-nnNd6Sz6wpPjIp8yQoD9x6J1Txjs46DoiFCeKiCoygk=";
    };
  };

  currentPlatform = platformData.${stdenvNoCC.hostPlatform.system} or (throw "Unsupported platform: ${stdenvNoCC.hostPlatform.system}");
in
  stdenvNoCC.mkDerivation rec {
    pname = "opencode-updated";
    version = "0.3.77";

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
      mainProgram = pname;
    };
  }
