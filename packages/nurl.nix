{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "nurl";
    rev = "82a43f261feaa80d59b33e862e3cc131cca62701";
    version = "0.3.13-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "nix-community";
      repo = "nurl";
      hash = "sha256-W63E6mIN8nvyGrsOBCcAzRAULpmo+Y8gkzJ6YgrjAA4=";
    };

    cargoHash = "sha256-wEt0LdZHBFKOoXTNtDYEHWtYamlTh1erZ/PbDATL7Hs=";
    doCheck = false;

    meta = {
      description = "Generate Nix fetcher calls from repository URLs [maintainer=@figsoda";
      homepage = "https://github.com/nix-community/nurl";
      changelog = "https://github.com/nix-community/nurl/blob/${src.rev}/CHANGELOG.md";
      license = lib.licenses.mpl20;
      mainProgram = pname;
    };
  }
