{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "nurl";
    rev = "fb76784e4c9656e41adb0982edbb5b7aa9ff4bf1";
    version = "0.3.13-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "nix-community";
      repo = "nurl";
      hash = "sha256-yNrlNurCc/h9E8MmNfj8y9ALbX3izDJboMDfGX1GftM=";
    };

    cargoHash = "sha256-CQp5J1CtUxe/riAOH9N93G0U028o2HJuxGKclDjtukc=";
    doCheck = false;

    meta = {
      description = "Generate Nix fetcher calls from repository URLs [maintainer=@figsoda";
      homepage = "https://github.com/nix-community/nurl";
      changelog = "https://github.com/nix-community/nurl/blob/${src.rev}/CHANGELOG.md";
      license = lib.licenses.mpl20;
      mainProgram = pname;
    };
  }
