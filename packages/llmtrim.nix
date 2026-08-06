{
  lib,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  nix-update-script,
}:
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "llmtrim";
  version = "0.12.6-dev";
  __structuredAttrs = true;

  src = fetchFromGitHub {
    owner = "fkiene";
    repo = "llmtrim";
    rev = "d7fd2c4e3ec4a9e354f98227546e3f75b5c0f1c6";
    hash = "sha256-ilTVx+TNEDxEfGJVM4WH1EEoCQ0ALNR983tkxUyncZA=";
  };

  cargoHash = "sha256-NMp0QbzK22OS2mgB2sSEbvRTRjcJi+29yScJKgWquXE=";
  doCheck = false;

  nativeBuildInputs = [
    pkg-config
  ];

  passthru.updateScript = nix-update-script {};

  meta = {
    description = "Static, deterministic LLM prompt/payload compressor — cut input tokens 30-90% with zero extra model calls";
    homepage = "https://github.com/fkiene/llmtrim";
    license = lib.licenses.mpl20;
    mainProgram = finalAttrs.pname;
  };
})
