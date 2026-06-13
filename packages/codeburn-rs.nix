{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  pname = "cburn";
  version = "0.1.1";

  src = fetchFromGitHub {
    owner = "rossnoah";
    repo = "codeburn-rs";
    rev = "746c50bca9e031e578fd2a690d1c5da689ebb827";
    hash = "sha256-U5v+PSYDNba4VNMxMvavSsSD3lBuD0PJisl136wyNug=";
  };

  cargoHash = "sha256-ToimKWDMBr43ISOe6vRSkWDidpBIOc6hsd/MVNfofj4=";

  meta = {
    description = "See where your AI coding tokens go but 600x faster";
    homepage = "https://github.com/rossnoah/codeburn-rs";
    license = lib.licenses.gpl3Only;
    mainProgram = pname;
  };
}
