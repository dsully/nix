{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage (finalAttrs: rec {
  pname = "cburn";
  version = "0.1.1";

  src = fetchFromGitHub {
    owner = "rossnoah";
    repo = "codeburn-rs";
    tag = "v${finalAttrs.version}";
    hash = "sha256-h7T/qdUxEF5YBFpIOxttCR50fHUZ4p+qDm4zmReHDSM=";
  };

  cargoHash = "sha256-ToimKWDMBr43ISOe6vRSkWDidpBIOc6hsd/MVNfofj4=";

  meta = {
    description = "See where your AI coding tokens go but 600x faster";
    homepage = "https://github.com/rossnoah/codeburn-rs";
    license = lib.licenses.gpl3Only;
    mainProgram = pname;
  };
})
