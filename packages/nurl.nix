{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "nurl";
    rev = "78f82fe876e9bfb03055a8a142b45e21f2208473";
    version = "0.3.13-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "nix-community";
      repo = "nurl";
      hash = "sha256-3jYlIhArohDVb5gLEIBjNn34XeqEnagmhnFQJJmc160=";
    };

    cargoHash = "sha256-iMfCRLtmiUtLmINEU6kaD3hGlRcu8LdgcDM8U4RBrSM=";
    doCheck = false;

    meta = {
      description = "Generate Nix fetcher calls from repository URLs [maintainer=@figsoda";
      homepage = "https://github.com/nix-community/nurl";
      changelog = "https://github.com/nix-community/nurl/blob/${src.rev}/CHANGELOG.md";
      license = lib.licenses.mpl20;
      mainProgram = pname;
    };
  }
