{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "nurl";
    rev = "c6ddeaeacc53534db4d55cf3243ed451701f1a71";
    version = "0.3.13-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "nix-community";
      repo = "nurl";
      hash = "sha256-oIhvAukvli5G1ocfQ8QdyTSdoM/bwa8h0pjueOpo8To=";
    };

    cargoHash = "sha256-4ACuHFzfuF4JWU0cPAJO+RPiA1HZ6o3b8K0C4NWJHmM=";
    doCheck = false;

    meta = {
      description = "Generate Nix fetcher calls from repository URLs [maintainer=@figsoda";
      homepage = "https://github.com/nix-community/nurl";
      changelog = "https://github.com/nix-community/nurl/blob/${src.rev}/CHANGELOG.md";
      license = lib.licenses.mpl20;
      mainProgram = pname;
    };
  }
