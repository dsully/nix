{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "infiniloom";
    version = "0.6.2";

    src = fetchCrate {
      inherit pname version;
      hash = "sha256-EP7cNH7I6mUgYayW22J7O/ppjrrG1lrIFw/hyDeNv/s=";
    };

    cargoHash = "sha256-FqE9s+e1PLRKLDeJqxTgvLDfEP/7oP64mBYsuxNWsJE=";
    doCheck = false;

    nativeBuildInputs = [
      installShellFiles
    ];

    postInstall = lib.optionalString (stdenv.hostPlatform.emulatorAvailable buildPackages) (
      let
        emulator = stdenv.hostPlatform.emulator buildPackages;
      in ''
        installShellCompletion --cmd ${pname} \
          --bash <(${emulator} $out/bin/${pname} completions bash) \
          --fish <(${emulator} $out/bin/${pname} completions fish) \
          --zsh <(${emulator} $out/bin/${pname} completions zsh)
      ''
    );

    meta = {
      description = "";
      homepage = "https://crates.io/crates/infiniloom";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
