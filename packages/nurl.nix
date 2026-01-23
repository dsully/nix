{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "nurl";
    rev = "f27ed2760c5ff79ebc049807f3f2154db7fc9e02";
    version = "0.3.13-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "nix-community";
      repo = "nurl";
      hash = "sha256-4RVmxq/kL4BtcusmnLABwb9vl5nAUS5wfkbPno31WwM=";
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
