{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "infiniloom";
    version = "0.6.3";

    src = fetchCrate {
      inherit pname version;
      hash = "sha256-Nodg4euVW3NKjgh7EOmsdC0YyLR1+igULdtuMnjzmq8=";
    };

    cargoHash = "sha256-68WIDde9LA9rBfxeSLNKvTlpniBNjHGYYrmZVRIRzv4=";
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
