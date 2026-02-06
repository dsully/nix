{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "nurl";
    rev = "892e602cfa77b075f64fbcbbe2a9250e1277ab4d";
    version = "0.3.13-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "nix-community";
      repo = "nurl";
      hash = "sha256-2i3Dpc7u9NgG6jlYD6+gZnjEtWRDKsI6pL0FOwPq5iA=";
    };

    cargoHash = "sha256-AlCWueIbkNSj85sL0nnW/O+pTuNqqHjHXF5lNOpvmzg=";
    doCheck = false;

    meta = {
      description = "Generate Nix fetcher calls from repository URLs [maintainer=@figsoda";
      homepage = "https://github.com/nix-community/nurl";
      changelog = "https://github.com/nix-community/nurl/blob/${src.rev}/CHANGELOG.md";
      license = lib.licenses.mpl20;
      mainProgram = pname;
    };
  }
