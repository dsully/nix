{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "nurl";
    rev = "e957b605eff68ef7e28194fbbe67190bf005a2d8";
    version = "0.3.13-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "nix-community";
      repo = "nurl";
      hash = "sha256-Ccbdtmam3YIeFvSKvG1izrv9uUrzEHK6391DXdUoyCc=";
    };

    cargoHash = "sha256-/loZ26pGVjDNYCpb78hCL1qOSYGDYOwrTU9IknhnFZQ=";
    doCheck = false;

    meta = {
      description = "Generate Nix fetcher calls from repository URLs [maintainer=@figsoda";
      homepage = "https://github.com/nix-community/nurl";
      changelog = "https://github.com/nix-community/nurl/blob/${src.rev}/CHANGELOG.md";
      license = lib.licenses.mpl20;
      mainProgram = pname;
    };
  }
