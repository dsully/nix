{
  lib,
  buildPackages,
  rustPlatform,
  fetchCrate,
  installShellFiles,
  stdenv,
}:
rustPlatform.buildRustPackage rec {
  pname = "infiniloom";
  version = "0.7.0";

  src = fetchCrate {
    inherit pname version;
    hash = "sha256-jTZFbHUFKBzsAZNzdHZJHuIHfYoHip2m3G7GEJASr+I=";
  };

  cargoHash = "sha256-F8Zrunr4btjJOR086YzMMJvJ4PTZ2Ay3mQfESKs++qc=";
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
